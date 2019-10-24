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
#define IMAGE_WIDTH     480
#define IMAGE_HEIGHT    640
@interface FlutterArcfaceRecognitionViewController ()<ASFCameraControllerDelegate, ASFVideoProcessorDelegate>
{
    ASF_CAMERA_DATA*   _offscreenIn;
}
@property (nonatomic, strong) ASFCameraController* cameraController;
@property (nonatomic, strong) ASFVideoProcessor* videoProcessor;
@property (nonatomic, strong) NSMutableArray* arrayAllFaceRectView;
@property (strong, nonatomic) GLKitView *glView;
@property (strong, nonatomic) UILabel *labelName;
@property (strong, nonatomic) UIButton *buttonRegister;

@property (strong, nonatomic)UIView *faceRectView;
@end

@implementation FlutterArcfaceRecognitionViewController

- (void)viewDidLoad {
    // Do any additional setup after loading the view.
     self.view.backgroundColor = [UIColor whiteColor];
     
     UIInterfaceOrientation uiOrientation = [[UIApplication sharedApplication] statusBarOrientation];
     AVCaptureVideoOrientation videoOrientation = (AVCaptureVideoOrientation)uiOrientation;

     _buttonRegister = [UIButton buttonWithType:UIButtonTypeCustom];
     _buttonRegister.frame = CGRectMake(10, 30, 40, 40);
     [_buttonRegister setImage:[UIImage imageNamed:@"ic_action_back_light"] forState:UIControlStateNormal];
     [_buttonRegister addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
     [self.view addSubview:_buttonRegister];
     
     
     self.arrayAllFaceRectView = [NSMutableArray arrayWithCapacity:0];
     self.glView = [[GLKitView alloc] initWithFrame:CGRectMake((self.view.frame.size.width-240)/2, (self.view.frame.size.height-240)/2, 240, 240)];
     self.glView.layer.borderWidth = 4.0f;
     self.glView.layer.borderColor = [UIColor greenColor].CGColor;
     self.glView.layer.cornerRadius = 120.0f;
     self.glView.layer.masksToBounds = YES;
     [self.view addSubview:self.glView];
     
     _faceRectView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
     _faceRectView.layer.borderWidth = 1;
     _faceRectView.layer.borderColor = [[UIColor greenColor] CGColor];
     [self.glView addSubview:_faceRectView];
     
     self.videoProcessor = [[ASFVideoProcessor alloc] init];
     self.videoProcessor.delegate = self;
     [self.videoProcessor initProcessor];
     
     self.cameraController = [[ASFCameraController alloc]init];
     self.cameraController.delegate = self;
     [self.cameraController setupCaptureSession:videoOrientation isPositionBack:_isPositionBack];
     
     _labelName = [[UILabel alloc] initWithFrame:CGRectMake(20, (self.view.frame.size.height-240)/2-80, self.view.frame.size.width-40, 40)];
     _labelName.textAlignment = NSTextAlignmentCenter;
     _labelName.text = @"拿起手机，请将面部放置中间位置";
     _labelName.font = [UIFont boldSystemFontOfSize:18];
     [self.view addSubview:_labelName];
}

-(void)back:(id)sender
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
    NSArray *arrayFaceInfo = [self.videoProcessor process:cameraData WithDataInfo:_videoData WithMaxScore:_maxScore WithType:_type WithImageInfo:sizeImage];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.glView renderWithCVPixelBuffer:cameraFrame orientation:0 mirror:NO];
        ASFVideoFaceInfo *faceInfo = arrayFaceInfo[0];
        _faceRectView.frame = [self dataFaceRect2ViewFaceRect:faceInfo.faceRect];
        _faceRectView.hidden = NO;
    });
    [Utility freeCameraData:cameraData];
}

-(void)processRecognized:(NSString *)errorStr WithType:(NSInteger)type
{
    self.labelName.text = [NSString stringWithFormat:@"%@", errorStr];
    if (type==1) {
        UIViewController *rootVC = self.presentingViewController;
        while (rootVC.presentingViewController) {
            rootVC = rootVC.presentingViewController;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:nil];
                 });
        
    }
}
- (CGRect)dataFaceRect2ViewFaceRect:(MRECT)faceRect
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
