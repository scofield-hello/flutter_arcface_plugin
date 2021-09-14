//
//  FlutterArcfaceRecognitionViewController.m
//  flutter_arcface_plugin
//
//  Created by iMac on 2019/10/16.
//

#import "FlutterArcfaceRecognitionViewController.h"
#import "ASFCameraController.h"
#import "GLKitView.h"
#import "Utility.h"
#import "ASFVideoProcessor.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
#import "UIColor+Ex.h"

#define IMAGE_WIDTH     480
#define IMAGE_HEIGHT    640
@interface FlutterArcfaceRecognitionViewController ()<ASFCameraControllerDelegate, ASFVideoProcessorDelegate>

@property (nonatomic, assign)NSInteger action;
@property (nonatomic, assign)BOOL useBackCamera;
@property (nonatomic, assign)BOOL genImageFile;
@property (nonatomic, strong)NSData* srcFeature;
@property (nonatomic, assign)float similarThreshold;


@property (nonatomic, strong) ASFCameraController* cameraController;
@property (nonatomic, strong) ASFVideoProcessor* videoProcessor;
@property (nonatomic, strong) NSMutableArray* arrayAllFaceRectView;
@property (nonatomic, strong) GLKitView *glView;
@property (nonatomic, strong) UILabel *labelTips;
@property (nonatomic, strong) UIButton *buttonNavBack;
@property (nonatomic, strong)UIView *faceRectView;
@end

@implementation FlutterArcfaceRecognitionViewController

- (instancetype)initWithAction:(NSInteger)action
                 useBackCamera:(BOOL)useBackCamera
                  genImageFile:(BOOL)genImageFile
                    srcFeature:(NSData *)srcFeature
              similarThreshold:(float)similarThreshold{
    self = [super init];
    if (self) {
        self.action = action;
        self.useBackCamera = useBackCamera;
        self.genImageFile = genImageFile;
        self.srcFeature = srcFeature;
        self.similarThreshold = similarThreshold;
    }
    return self;
}

- (void)viewDidLoad {
    
    self.view.backgroundColor = [UIColor whiteColor];
    UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)uiOrientation;
    UILabel *labelTitle = [[UILabel alloc]initWithFrame:CGRectMake(0, 24, self.view.frame.size.width, 44)];
    [labelTitle setText:@"人脸识别"];
    [labelTitle setTextColor:[UIColor blackColor]];
    [labelTitle setFont:[UIFont boldSystemFontOfSize:18.0]];
    [labelTitle setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:labelTitle];
    _buttonNavBack = [UIButton buttonWithType:UIButtonTypeCustom];
    _buttonNavBack.frame = CGRectMake(8, 24, 44, 44);
    [_buttonNavBack setImage:[UIImage imageNamed:@"ic_action_back_light"] forState:UIControlStateNormal];
    [_buttonNavBack addTarget:self action:@selector(onNavBack:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_buttonNavBack];
    UILabel *confirmLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 98, self.view.frame.size.width, 22.0)];
    [confirmLabel setText:@"请确认是您本人操作"];
    [confirmLabel setTextColor:[UIColor blackColor]];
    [confirmLabel setFont:[UIFont systemFontOfSize:16.0f]];
    [confirmLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:confirmLabel];
    
    _labelTips = [[UILabel alloc] initWithFrame:CGRectMake(0, 120, self.view.frame.size.width, 22.0)];
    [_labelTips setText:@"保持人脸在取景框中等待完成识别"];
    [_labelTips setFont:[UIFont systemFontOfSize:14.0f]];
    [_labelTips setTextColor:[UIColor grayColor]];
    [_labelTips setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:_labelTips];
    
    self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
    self.glView = [[GLKitView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 240)/2, 168.0, 240, 240)];
    self.glView.layer.borderWidth = 1.0f;
    self.glView.layer.borderColor =  [UIColor colorWithHexString:@"#0091FF" alpha:0.2].CGColor;
    self.glView.layer.cornerRadius = 120.0f;
    self.glView.layer.masksToBounds = YES;
    [self.view addSubview:self.glView];

    float rectWidth = self.glView.bounds.size.width;
    float rectHeight = self.glView.bounds.size.height;
    _faceRectView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, rectWidth, rectHeight)];
    _faceRectView.layer.borderWidth = 1.0f;
    _faceRectView.layer.borderColor = [[UIColor yellowColor] CGColor];
    [self.glView addSubview:_faceRectView];
    float lineMargin = (self.view.frame.size.width - 285.0) / 2;
    UIView *sepLine = [[UIView alloc]initWithFrame:CGRectMake(lineMargin, 418.0, 285.0, 1.0)];
    sepLine.backgroundColor = [UIColor colorWithHexString:@"#DEDEDE" alpha:1.0];
    [self.view addSubview:sepLine];
    //三个单元格
    float gridWidth = 285 / 3;
    UIView *gridPhone = [[UIView alloc]initWithFrame:CGRectMake(lineMargin, 429.0, gridWidth, 64.0)];
    UIView *gridLight = [[UIView alloc]initWithFrame:CGRectMake(lineMargin + gridWidth, 429.0, gridWidth, 64.0)];
    UIView *gridCover = [[UIView alloc]initWithFrame:CGRectMake(lineMargin + gridWidth*2, 429.0, gridWidth, 64.0)];
    float iconWidth = 16;
    float iconMarginLeft = (gridWidth - iconWidth) / 2;
    UIImageView *leftImageView = [[UIImageView alloc]initWithFrame:CGRectMake(iconMarginLeft, 0, iconWidth, iconWidth)];
    leftImageView.image = [UIImage imageNamed:@"ic_phone"];
    [gridPhone addSubview:leftImageView];
    UILabel *leftLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, iconWidth, gridWidth, 64.0 - iconWidth)];
    leftLabel.textAlignment = NSTextAlignmentCenter;
    leftLabel.textColor = [UIColor colorWithHexString:@"#333333" alpha:1.0];
    leftLabel.font = [UIFont systemFontOfSize:12.0];
    leftLabel.text = @"正对手机";
    [gridPhone addSubview:leftLabel];
    
    UIImageView *middleImageView = [[UIImageView alloc]initWithFrame:CGRectMake(iconMarginLeft, 0, iconWidth, iconWidth)];
    middleImageView.image = [UIImage imageNamed:@"ic_light"];
    [gridLight addSubview:middleImageView];
    UILabel *middleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, iconWidth, gridWidth, 64.0 - iconWidth)];
    middleLabel.textAlignment = NSTextAlignmentCenter;
    middleLabel.textColor = [UIColor colorWithHexString:@"#333333" alpha:1.0];
    middleLabel.font = [UIFont systemFontOfSize:12.0];
    middleLabel.text = @"光线充足";
    [gridLight addSubview:middleLabel];
    
    UIImageView *rightImageView = [[UIImageView alloc]initWithFrame:CGRectMake(iconMarginLeft, 0, iconWidth, iconWidth)];
    rightImageView.image = [UIImage imageNamed:@"ic_face"];
    [gridCover addSubview:rightImageView];
    UILabel *rightLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, iconWidth, gridWidth, 64.0 - iconWidth)];
    rightLabel.textAlignment = NSTextAlignmentCenter;
    rightLabel.textColor = [UIColor colorWithHexString:@"#333333" alpha:1.0];
    rightLabel.font = [UIFont systemFontOfSize:12.0];
    rightLabel.text = @"脸无遮挡";
    [gridCover addSubview:rightLabel];
    
    [self.view addSubview:gridPhone];
    [self.view addSubview:gridLight];
    [self.view addSubview:gridCover];

    self.videoProcessor = [[ASFVideoProcessor alloc] init];
    self.videoProcessor.delegate = self;
    [self.videoProcessor initProcessor];
    self.videoProcessor.glViewFrame = self.glView.frame;
    self.cameraController = [[ASFCameraController alloc]init];
    self.cameraController.delegate = self;
    [self.cameraController setupCaptureSession:videoOrientation useBackCamera:_useBackCamera];
}

-(void)onNavBack:(id)sender
{
    UIViewController *rootVC = self.presentingViewController;
    while (rootVC.presentingViewController) {
        rootVC = rootVC.presentingViewController;
    }
    [rootVC dismissViewControllerAnimated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.cameraController startCaptureSession];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.cameraController stopCaptureSession];
}

- (void)timerHideAlertViewController:(id)sender {
    NSTimer *timer = (NSTimer*)sender;
    UIAlertController *alertViewController = (UIAlertController*)timer.userInfo;
    [alertViewController dismissViewControllerAnimated:YES completion:nil];
    alertViewController = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    ASF_CAMERA_DATA* cameraData = [Utility getCameraDataFromSampleBuffer:sampleBuffer];
    UIImage *imageInfo = [Utility imageFromSampleBuffer:sampleBuffer];
    UIImage *sizeImage = [Utility clipWithImageToSize:CGSizeMake(240, 320) clipImage:imageInfo];
    NSArray *arrayFaceInfo = [self.videoProcessor process:cameraData
                                                srcFeature:_srcFeature
                                                genImageFile:_genImageFile
                                                useBackCamera:_useBackCamera
                                         similarThreshold:_similarThreshold
                                                   action:_action
                                                imageInfo:sizeImage];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.glView renderWithCVPixelBuffer:cameraFrame orientation:0 mirror:NO];
        ASFVideoFaceInfo *faceInfo = arrayFaceInfo[0];
        _faceRectView.frame = [self adjustFaceRect:faceInfo.faceRect];
        _faceRectView.hidden = NO;
    });
    [Utility freeCameraData:cameraData];
}

-(void)processRecognized:(NSString *)tip action:(NSInteger)action
{
    self.labelTips.text = [NSString stringWithFormat:@"%@", tip];
    if (action == 1) {
        UIViewController *rootVC = self.presentingViewController;
        while (rootVC.presentingViewController) {
            rootVC = rootVC.presentingViewController;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                 });
    }
}

- (CGRect)adjustFaceRect:(MRECT)faceRect
{
    CGRect frameFaceRect = {0};
    CGRect frameGLView = self.glView.frame;
    frameFaceRect.size.width = CGRectGetWidth(frameGLView)*(faceRect.right-faceRect.left)/IMAGE_WIDTH;
    frameFaceRect.size.height = CGRectGetHeight(frameGLView)*(faceRect.bottom-faceRect.top)/IMAGE_HEIGHT;
    frameFaceRect.origin.x = CGRectGetWidth(frameGLView)*faceRect.left/IMAGE_WIDTH;
    frameFaceRect.origin.y = CGRectGetHeight(frameGLView)*faceRect.top/IMAGE_HEIGHT;
    
    return frameFaceRect;
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
