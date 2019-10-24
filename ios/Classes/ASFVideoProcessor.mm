//
//  AFVideoProcessor.mm
//

#import "ASFVideoProcessor.h"
#import "Utility.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import <ArcSoftFaceEngine/merror.h>

//#define ASF_APPID            @"GKgxanYQak7mHzUZcMxdPKnx1z3fhAkyTemnGu569dHL"
//#define ASF_SDKKEY           @"Hzmu3U6H5NyDRDNEUxD8W4ty2xzKXdV55suALPo99Lks"
#define DETECT_MODE          ASF_DETECT_MODE_VIDEO
#define ASF_FACE_NUM         6
#define ASF_FACE_SCALE       16
#define ASF_FACE_COMBINEDMASK ASF_FACE_DETECT | ASF_FACERECOGNITION | ASF_FACE3DANGLE
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
@property (nonatomic, assign) BOOL              frModelVersionChecked;
@property (atomic, strong) ASFRPerson*           frPerson;

@property (nonatomic, strong) ArcSoftFaceEngine*      arcsoftFace;
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

- (void)initProcessor
{
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
    
    _processSemaphore = dispatch_semaphore_create(1);
    _processFRSemaphore = dispatch_semaphore_create(1);
}

- (void)uninitProcessor
{
    if(_processSemaphore && 0 == dispatch_semaphore_wait(_processSemaphore, DISPATCH_TIME_FOREVER))
    {
        dispatch_semaphore_signal(_processSemaphore);
        _processSemaphore = NULL;
    }
    
    if(_processFRSemaphore && 0 == dispatch_semaphore_wait(_processFRSemaphore, DISPATCH_TIME_FOREVER))
    {
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

- (NSArray*)process:(ASF_CAMERA_DATA*)cameraData WithDataInfo:(NSData *)imageData WithMaxScore:(NSString *)maxScore WithType:(NSInteger)type WithImageInfo:(UIImage *)imageInfo
{
    NSMutableArray *arrayFaceInfo = nil;
    if(0 == dispatch_semaphore_wait(_processSemaphore, 3))
    {
        __block BOOL detectFace = NO;
        __block ASF_SingleFaceInfo singleFaceInfo = {0};
        __weak ASFVideoProcessor* weakSelf = self;
        do {
            ASF_MultiFaceInfo multiFaceInfo = {0};
            MRESULT mr = [self.arcsoftFace detectFacesWithWidth:cameraData->i32Width
                                                         height:cameraData->i32Height
                                                           data:cameraData->ppu8Plane[0]
                                                         format:cameraData->u32PixelArrayFormat
                                                        faceRes:&multiFaceInfo];
            if(ASF_MOK != mr || multiFaceInfo.faceNum != 1) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                        [self.delegate processRecognized:@"没有检测到人脸" WithType:0];
                });
                if (multiFaceInfo.faceNum>1) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                            [self.delegate processRecognized:@"不允许出现多张人脸" WithType:0];
                    });
                }
                break;
            }
            arrayFaceInfo = [NSMutableArray arrayWithCapacity:0];
            for (int face=0; face<multiFaceInfo.faceNum; face++) {
                ASFVideoFaceInfo *faceInfo = [[ASFVideoFaceInfo alloc] init];
                faceInfo.faceRect = multiFaceInfo.faceRect[face];
                [arrayFaceInfo addObject:faceInfo];
            }
            
            NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
            mr = [self.arcsoftFace processWithWidth:cameraData->i32Width
                                             height:cameraData->i32Height
                                               data:cameraData->ppu8Plane[0]
                                             format:cameraData->u32PixelArrayFormat
                                            faceRes:&multiFaceInfo
                                               mask:ASF_FACE3DANGLE];
            NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
            NSLog(@"processTime=%dms", (int)(cost * 1000));
            if(ASF_MOK != mr) {
                NSLog(@"process失败：%ld", mr);
                break;
            }
            ASF_Face3DAngle face3DAngle = {0};
            if(ASF_MOK != [self.arcsoftFace getFace3DAngle:&face3DAngle] || face3DAngle.num != multiFaceInfo.faceNum)
                break;
            ASFFace3DAngle *face3DAngleInfo = [[ASFFace3DAngle alloc] init];
            face3DAngleInfo.yawAngle = face3DAngle.yaw[0];
            face3DAngleInfo.pitchAngle = face3DAngle.pitch[0];
            face3DAngleInfo.rollAngle = face3DAngle.roll[0];
            BOOL isYaw = (face3DAngleInfo.yawAngle >= -10.00f && face3DAngleInfo.yawAngle <= 10.00f);
            BOOL isPit = (face3DAngleInfo.pitchAngle >= -10.00f && face3DAngleInfo.pitchAngle <= 10.00f);
            BOOL isRoll = (face3DAngleInfo.rollAngle >= -10.00f && face3DAngleInfo.rollAngle <= 10.00f);
            if (!(isYaw && isPit && isRoll)) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                        [self.delegate processRecognized:@"请将脸部正对摄像头,不要偏斜" WithType:0];
                });
           
                break;
            }
            detectFace = YES;
            singleFaceInfo.rcFace = multiFaceInfo.faceRect[0];
            singleFaceInfo.orient = multiFaceInfo.faceOrient[0];
        } while (NO);
        dispatch_semaphore_signal(_processSemaphore);
        if(0 == dispatch_semaphore_wait(_processFRSemaphore, 3))
        {
            __block ASF_CAMERA_INPUT_DATA offscreenProcess = [self copyCameraDataForProcessFR:cameraData];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                if(!weakSelf.frModelVersionChecked)
                {
                    weakSelf.frModelVersionChecked = YES;
                }
                if(detectFace)
                {
                    ASF_FaceFeature faceFeature = {0};
                    NSTimeInterval begin = [[NSDate date] timeIntervalSince1970];
                    MRESULT mr = [self.arcsoftFace extractFaceFeatureWithWidth:offscreenProcess->i32Width
                                                                        height:offscreenProcess->i32Height
                                                                          data:offscreenProcess->ppu8Plane[0]
                                                                        format:offscreenProcess->u32PixelArrayFormat
                                                                      faceInfo:&singleFaceInfo
                                                                       feature:&faceFeature];
                    NSTimeInterval cost = [[NSDate date] timeIntervalSince1970] - begin;
                    NSLog(@"FRTime=%dms", (int)(cost * 1000));
                    NSLog(@"-----------featureSize---------------%d", faceFeature.featureSize);
                    float leftInfo = singleFaceInfo.rcFace.left;
                    float topInfo = singleFaceInfo.rcFace.top;
                    float rightInfo = singleFaceInfo.rcFace.right;
                    float bottomInfo = singleFaceInfo.rcFace.bottom;
                    NSLog(@"----------leftInfo------------- %f", leftInfo);
                    NSLog(@"----------topInfo----------- %f", topInfo);
                    NSLog(@"----------rightInfo------------- %f", rightInfo);
                    NSLog(@"----------bottomInfo----------- %f", bottomInfo);
                    BOOL isLeft = (leftInfo >= 60&&leftInfo <= 140);
                    BOOL isTop = (topInfo >= 150&&topInfo <= 230);
                    if (!(isTop&&isLeft)) {
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                                [self.delegate processRecognized:@"请将脸部置于中间位置，不要偏移" WithType:0];
                        });
                    }else{
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                                [self.delegate processRecognized:@"检测成功" WithType:0];
                        });
                      
                        if(mr == ASF_MOK)
                    {
                        if(type==0){
                            NSData *imageData = [NSData dataWithBytes:faceFeature.feature length:faceFeature.featureSize];
                            NSString *base64Str = [imageData base64EncodedStringWithOptions:NSDataBase64DecodingIgnoreUnknownCharacters];
                            NSString *imagePath = [NSString stringWithFormat:@"file://%@", [Utility getImagePath:imageInfo]];
                            //添加 字典，将label的值通过key值设置传递
                            NSDictionary *dict =[[NSDictionary alloc]initWithObjectsAndKeys:base64Str,@"feature",imagePath,@"image",nil];
                            //创建通知
                            NSNotification *notification =[NSNotification notificationWithName:@"backFaceInfo" object:nil userInfo:dict];
                            //通过通知中心发送通知
                            [[NSNotificationCenter defaultCenter] postNotification:notification];
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                                    [self.delegate processRecognized:@"人脸特征提取成功" WithType:1];
                            });
                        }else if (type==1){
                            ASF_FaceFeature refFaceFeature = {0};
                            MFloat fConfidenceLevel =  0.0;
                            refFaceFeature.feature = (MByte*)[imageData bytes];
                            refFaceFeature.featureSize = (MInt32)[imageData length];
                            MRESULT mr = [self.arcsoftFace compareFaceWithFeature:&faceFeature
                                                                         feature2:&refFaceFeature
                                                                  confidenceLevel:&fConfidenceLevel];
                            if (mr == ASF_MOK && fConfidenceLevel >= [maxScore floatValue]) {
                                NSString *similar = [NSString stringWithFormat:@"%.lf", (fConfidenceLevel*100)];
                                NSDictionary *dict =[[NSDictionary alloc]initWithObjectsAndKeys:similar,@"similar",nil];
                                //创建通知
                                NSNotification *notification =[NSNotification notificationWithName:@"backFaceSuccess" object:nil userInfo:dict];
                                //通过通知中心发送通知
                                [[NSNotificationCenter defaultCenter] postNotification:notification];
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                                        [self.delegate processRecognized:@"人脸对比成功" WithType:1];
                                });
                            }else{
                                dispatch_sync(dispatch_get_main_queue(), ^{
                                    if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                                        [self.delegate processRecognized:@"人脸对比失败" WithType:0];
                                });
                            }
                        }
                    }else{
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            if(self.delegate && [self.delegate respondsToSelector:@selector(processRecognized:WithType:)])
                                [self.delegate processRecognized:@"人脸特征提取失败" WithType:0];
                        });
                    }
                  }
                }
                dispatch_semaphore_signal(_processFRSemaphore);
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

@end
