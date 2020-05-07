#import "ASFCameraController.h"
#import <AVFoundation/AVFoundation.h>

@interface ASFCameraController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    AVCaptureSession    *captureSession;
    AVCaptureConnection *videoConnection;
}
@end

@implementation ASFCameraController

#pragma mark capture
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection == videoConnection) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureOutput:didOutputSampleBuffer:fromConnection:)]) {
            [self.delegate captureOutput:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
        }
    }
}

#pragma mark - Setup Video Session
- (AVCaptureDevice *)videoDeviceWithPosition:(AVCaptureDevicePosition)position{
    NSArray *devices;
    if (@available(iOS 10.0, *)) {
        devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                                                         mediaType:AVMediaTypeVideo position:position].devices;
    }else{
        devices = [AVCaptureDevice devices];
    }
    for (AVCaptureDevice *device in devices){
        if ([device position] == position){
            return device;
        }
    }
    return nil;
}

- (BOOL) setupCaptureSession:(AVCaptureVideoOrientation)videoOrientation useBackCamera:(BOOL)useBackCamera{
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession beginConfiguration];
    NSLog(@"是否使用后置摄像头：%d", useBackCamera);
    AVCaptureDevice *videoDevice = [self videoDeviceWithPosition:useBackCamera?AVCaptureDevicePositionBack:AVCaptureDevicePositionFront];
    AVCaptureDeviceInput *videoIn = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:nil];
    if ([captureSession canAddInput:videoIn])
        [captureSession addInput:videoIn];
    AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
    [videoOut setAlwaysDiscardsLateVideoFrames:YES];
    #ifdef __OUTPUT_BGRA__
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    #else
    NSDictionary *dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    #endif
    [videoOut setVideoSettings:dic];
    dispatch_queue_t videoCaptureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
    [videoOut setSampleBufferDelegate:self queue:videoCaptureQueue];
    if ([captureSession canAddOutput:videoOut]){
        [captureSession addOutput:videoOut];
    }
    videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
    if (videoConnection.supportsVideoMirroring) {
        [videoConnection setVideoMirrored:TRUE];
    }
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:videoOrientation];
    }
    if ([captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        [captureSession setSessionPreset:AVCaptureSessionPreset640x480];
    }
    [captureSession commitConfiguration];
    return YES;
}

- (void) startCaptureSession{
    if ( !captureSession ){
        return;
    }
    if (!captureSession.isRunning ){
        [captureSession startRunning];
    }
}

- (void) stopCaptureSession{
    [captureSession stopRunning];
}
@end
