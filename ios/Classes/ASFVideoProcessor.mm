//
//  AFVideoProcessor.mm
//

#import "ASFVideoProcessor.h"
#import "Utility.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import <ArcSoftFaceEngine/merror.h>

#define DETECT_MODE          ASF_DETECT_MODE_VIDEO
#define ASF_FACE_NUM         50
#define ASF_FACE_SCALE       16
#define ASF_FACE_COMBINEDMASK ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_FACE3DANGLE | ASF_LIVENESS
#define kSandboxPathStr [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]

@implementation ASFFace3DAngle
@end

@implementation ASFVideoFaceInfo
@end

@interface ASFVideoProcessor()
{
    ASF_CAMERA_DATA*   _cameraDataForProcessFR;
    dispatch_semaphore_t _processSemaphore;
    dispatch_semaphore_t _processFRSemaphore;
}
@property (nonatomic, assign) BOOL frModelVersionChecked;
@property (nonatomic, strong) ArcSoftFaceEngine* arcsoftFace;
@end

@implementation ASFVideoProcessor

- (instancetype)init {
    self = [super init];
    if(self) {
        _processSemaphore = NULL;
        _processFRSemaphore = NULL;
    }
    return self;
}

- (void)initProcessor{
    
    self.arcsoftFace = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [self.arcsoftFace initFaceEngineWithDetectMode:DETECT_MODE
                                                 orientPriority:ASF_OP_0_ONLY
                                                          scale:ASF_FACE_SCALE
                                                     maxFaceNum:ASF_FACE_NUM
                                                   combinedMask:ASF_FACE_COMBINEDMASK];
    if (mr == ASF_MOK) {
        NSLog(@"初始化成功");
    } else {
        NSLog(@"初始化失败：%ld", mr);
    }
     [self.arcsoftFace setLivenessThreshold:0.5f];
    _processSemaphore = dispatch_semaphore_create(1);
    _processFRSemaphore = dispatch_semaphore_create(1);
}

- (void)uninitProcessor{
    if(_processSemaphore && 0 == dispatch_semaphore_wait(_processSemaphore, DISPATCH_TIME_FOREVER)){
        dispatch_semaphore_signal(_processSemaphore);
        _processSemaphore = NULL;
    }
    if(_processFRSemaphore && 0 == dispatch_semaphore_wait(_processFRSemaphore, DISPATCH_TIME_FOREVER)){
        [Utility freeCameraData:_cameraDataForProcessFR];
        _cameraDataForProcessFR = MNull;
        dispatch_semaphore_signal(_processFRSemaphore);
        _processFRSemaphore = NULL;
    }
    [self.arcsoftFace unInitFaceEngine];
    self.arcsoftFace = nil;
}

- (void)setDetectFaceUseFD:(BOOL)detectFaceUseFD
{
    if(_detectFaceUseFD == detectFaceUseFD)
        return;
    _detectFaceUseFD = detectFaceUseFD;
    
    [self uninitProcessor];
    [self initProcessor];
}

- (BOOL)isDetectFaceUseFD
{
    return _detectFaceUseFD;
}

- (NSArray*)process:(ASF_CAMERA_DATA*)cameraData
         srcFeature:(NSData *)srcFeature
       genImageFile:(BOOL)genImageFile
      useBackCamera:(BOOL)useBackCamera
   similarThreshold:(float)similarThreshold
             action:(NSInteger)action
          imageInfo:(UIImage *)imageInfo{
    NSMutableArray *arrayFaceInfo = nil;
    if(0 == dispatch_semaphore_wait(_processSemaphore, 3)){
        __block BOOL detectFace = NO;
        __block ASF_SingleFaceInfo singleFaceInfo = {0};
        __weak __typeof(self) weakSelf = self;
        do {
            ASF_MultiFaceInfo asfMultiFaceInfo = {0};
            MRESULT mr = [self.arcsoftFace detectFacesWithWidth:cameraData->i32Width
                                                         height:cameraData->i32Height
                                                           data:cameraData->ppu8Plane[0]
                                                         format:cameraData->u32PixelArrayFormat
                                                        faceRes:&asfMultiFaceInfo];
            if (ASF_MOK != mr) {
                break;
            }
            if (asfMultiFaceInfo.faceNum == 0) {
                //未检测到人脸
                dispatch_sync(dispatch_get_main_queue(), ^{
                    __strong __typeof(weakSelf) strongRef = weakSelf;
                    if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                        [strongRef.delegate processRecognized:@"请将摄像头正对您的脸部" action:0];
                });
                break;
            }
            arrayFaceInfo = [NSMutableArray arrayWithCapacity:asfMultiFaceInfo.faceNum];
            for (int i = 0; i < asfMultiFaceInfo.faceNum; i++) {
                ASFVideoFaceInfo *faceInfo = [[ASFVideoFaceInfo alloc] init];
                faceInfo.faceRect = asfMultiFaceInfo.faceRect[i];
                [arrayFaceInfo addObject:faceInfo];
            }
            if (asfMultiFaceInfo.faceNum > 1) {
                //检测人脸数量大于1个
                dispatch_sync(dispatch_get_main_queue(), ^{
                    __strong __typeof(weakSelf) strongRef = weakSelf;
                    if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                        [strongRef.delegate processRecognized:@"不允许出现多张人脸" action:0];
                });
                break;
            }
            if (![self isFaceInCenter:asfMultiFaceInfo.faceRect[0]]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    __strong __typeof(weakSelf) strongRef = weakSelf;
                    if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                        [strongRef.delegate processRecognized:@"请将脸部置于中间位置，不要偏移" action:0];
                });
                break;
            }
            mr = [self.arcsoftFace processWithWidth:cameraData->i32Width
                                             height:cameraData->i32Height
                                               data:cameraData->ppu8Plane[0]
                                             format:cameraData->u32PixelArrayFormat
                                            faceRes:&asfMultiFaceInfo
                                               mask:ASF_FACE3DANGLE | ASF_LIVENESS];
            if(ASF_MOK != mr) {
                NSLog(@"人脸特征检测失败：%ld", mr);
                break;
            }
            if (!useBackCamera) {
                ASF_Face3DAngle face3DAngle = {0};
                if(ASF_MOK != [self.arcsoftFace getFace3DAngle:&face3DAngle]){
                    break;
                }
                ASFFace3DAngle *face3DAngleInfo = [[ASFFace3DAngle alloc] init];
                face3DAngleInfo.yawAngle = face3DAngle.yaw[0];
                face3DAngleInfo.pitchAngle = face3DAngle.pitch[0];
                face3DAngleInfo.rollAngle = face3DAngle.roll[0];
                BOOL isYaw = (face3DAngleInfo.yawAngle >= -20.00f && face3DAngleInfo.yawAngle <= 20.00f);
                BOOL isPitch = (face3DAngleInfo.pitchAngle >= -10.00f && face3DAngleInfo.pitchAngle <= 10.00f);
                BOOL isRoll = (face3DAngleInfo.rollAngle >= -10.00f && face3DAngleInfo.rollAngle <= 10.00f);
                if (!(isYaw && isPitch && isRoll)) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        __strong __typeof(weakSelf) strongRef = weakSelf;
                        if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                            [strongRef.delegate processRecognized:@"请调整人脸角度,不要偏斜" action:0];
                    });
                    break;
                }
            }
            ASF_FaceLivenessScore faceLiveness = {0};
            if (ASF_MOK != [self.arcsoftFace getLiveness:&faceLiveness]) {
                break;
            }
            if(faceLiveness.scoreArray[0] != 1){
                dispatch_sync(dispatch_get_main_queue(), ^{
                    __strong __typeof(weakSelf) strongRef = weakSelf;
                    if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                        [strongRef.delegate processRecognized:@"请眨一眨您的眼睛" action:0];
                });
                break;
            }
            dispatch_sync(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongRef = weakSelf;
                if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                    [strongRef.delegate processRecognized:@"保持人脸在取景框中等待识别完成" action:0];
            });
            detectFace = YES;
            singleFaceInfo.rcFace = asfMultiFaceInfo.faceRect[0];
            singleFaceInfo.orient = asfMultiFaceInfo.faceOrient[0];
        } while (NO);
        dispatch_semaphore_signal(_processSemaphore);
        if(0 == dispatch_semaphore_wait(_processFRSemaphore, 3)){
            __block ASF_CAMERA_INPUT_DATA offscreenProcess = [self copyCameraDataForProcessFR:cameraData];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                __strong __typeof(weakSelf) strongRef = weakSelf;
                if(!strongRef.frModelVersionChecked){
                    strongRef.frModelVersionChecked = YES;
                }
                if(detectFace){
                    ASF_FaceFeature faceFeature = {0};
                    MRESULT mr = [self.arcsoftFace extractFaceFeatureWithWidth:offscreenProcess->i32Width
                                                                        height:offscreenProcess->i32Height
                                                                          data:offscreenProcess->ppu8Plane[0]
                                                                        format:offscreenProcess->u32PixelArrayFormat
                                                                      faceInfo:&singleFaceInfo
                                                                       feature:&faceFeature];
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                            [strongRef.delegate processRecognized:@"检测成功" action:0];
                    });
                    if(mr == ASF_MOK){
                        if(action == 0){
                            NSData *imageData = [NSData dataWithBytes:faceFeature.feature length:faceFeature.featureSize];
                            NSString *base64Str = [imageData base64EncodedStringWithOptions:NSDataBase64DecodingIgnoreUnknownCharacters];
                            NSString *imagePath = nil;
                            if (genImageFile) {
                                imagePath = [NSString stringWithFormat:@"file://%@", [Utility getImagePath:imageInfo]];
                            }
                            //添加 字典，将label的值通过key值设置传递
                            NSDictionary *dict =[[NSDictionary alloc]initWithObjectsAndKeys:base64Str,@"feature",imagePath,@"image",nil];
                            //创建通知
                            NSNotification *notification =[NSNotification notificationWithName:@"onFaceExtracted" object:nil userInfo:dict];
                            //通过通知中心发送通知
                            [[NSNotificationCenter defaultCenter] postNotification:notification];
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                                    [strongRef.delegate processRecognized:@"人脸特征提取成功" action:1];
                            });
                        }else if (action == 1){
                            ASF_FaceFeature refFaceFeature = {0};
                            MFloat similar = 0.0f;
                            refFaceFeature.feature = (MByte*)[srcFeature bytes];
                            refFaceFeature.featureSize = (MInt32)[srcFeature length];
                            MRESULT mr = [strongRef.arcsoftFace compareFaceWithFeature:&faceFeature
                                                                         feature2:&refFaceFeature
                                                                  confidenceLevel:&similar];
                            if (mr == ASF_MOK && similar >= similarThreshold) {
                                NSData *imageData = [NSData dataWithBytes:faceFeature.feature length:faceFeature.featureSize];
                                NSString *base64Str = [imageData base64EncodedStringWithOptions:NSDataBase64DecodingIgnoreUnknownCharacters];
                                NSDictionary *dict =[[NSDictionary alloc]initWithObjectsAndKeys:[NSNumber numberWithFloat:similar], @"similar",base64Str, @"feature", nil];
                                //创建通知
                                NSNotification *notification =[NSNotification notificationWithName:@"onFaceRecognized" object:nil userInfo:dict];
                                //通过通知中心发送通知
                                [[NSNotificationCenter defaultCenter] postNotification:notification];
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                                        [strongRef.delegate processRecognized:@"人脸对比成功" action:1];
                                });
                            }else{
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                                        [strongRef.delegate processRecognized:@"人脸对比失败" action:0];
                                });
                            }
                        }else{
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                if(strongRef.delegate && [strongRef.delegate respondsToSelector:@selector(processRecognized:action:)])
                                    [strongRef.delegate processRecognized:@"人脸特征提取失败" action:0];
                            });
                        }
                  }
                }
                dispatch_semaphore_signal(self->_processFRSemaphore);
            });
        }
    }
    return arrayFaceInfo;
}

- (ASF_CAMERA_INPUT_DATA)copyCameraDataForProcessFR:(ASF_CAMERA_INPUT_DATA)pOffscreenIn
{
    if (pOffscreenIn == MNull) {
        return  MNull;
    }
    if (_cameraDataForProcessFR != NULL)
    {
        if (_cameraDataForProcessFR->i32Width != pOffscreenIn->i32Width ||
            _cameraDataForProcessFR->i32Height != pOffscreenIn->i32Height ||
            _cameraDataForProcessFR->u32PixelArrayFormat != pOffscreenIn->u32PixelArrayFormat) {
            [Utility freeCameraData:_cameraDataForProcessFR];
            _cameraDataForProcessFR = NULL;
        }
    }
    if (_cameraDataForProcessFR == NULL) {
        _cameraDataForProcessFR = [Utility createOffscreen:pOffscreenIn->i32Width
                                                    height:pOffscreenIn->i32Height
                                                    format:pOffscreenIn->u32PixelArrayFormat];
    }
    if (ASVL_PAF_NV12 == pOffscreenIn->u32PixelArrayFormat)
    {
        memcpy(_cameraDataForProcessFR->ppu8Plane[0],
               pOffscreenIn->ppu8Plane[0],
               pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[0]) ;
        
        memcpy(_cameraDataForProcessFR->ppu8Plane[1],
               pOffscreenIn->ppu8Plane[1],
               pOffscreenIn->i32Height * pOffscreenIn->pi32Pitch[1] / 2);
    }
    return _cameraDataForProcessFR;
}

- (BOOL) isFaceInCenter:(MRECT)faceRect{
    CGRect frameFaceRect = {0};
    CGRect frameGLView = self.glViewFrame;
    frameFaceRect.size.width = CGRectGetWidth(frameGLView)*(faceRect.right-faceRect.left)/480;
    frameFaceRect.size.height = CGRectGetHeight(frameGLView)*(faceRect.bottom-faceRect.top)/640;
    frameFaceRect.origin.x = CGRectGetWidth(frameGLView)*faceRect.left / 480;
    frameFaceRect.origin.y = CGRectGetHeight(frameGLView)*faceRect.top / 640;
    int adjustedRectCenterX = frameFaceRect.origin.x + (frameFaceRect.size.width / 2);
    int adjustedRectCenterY = frameFaceRect.origin.y + (frameFaceRect.size.height / 2);
    int viewCenterX = frameGLView.size.width / 2;
    int viewCenterY = frameGLView.size.height / 2;
    NSLog(@"parent center = (%d, %d)", viewCenterX, viewCenterY);
    NSLog(@"rect center = (%d, %d)", adjustedRectCenterX, adjustedRectCenterY);
    int absXGap = abs(viewCenterX - adjustedRectCenterX);
    int absYGap = abs(viewCenterY - adjustedRectCenterY);
    NSLog(@"abs (%d, %d)", absXGap, absYGap);
    return absXGap <= 20 && absYGap <= 20;
}

@end
