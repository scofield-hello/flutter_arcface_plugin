#import "FlutterArcfacePlugin.h"
#import "FlutterArcfaceRecognitionViewController.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
@implementation FlutterArcfacePlugin{
    FlutterResult _result;
    FlutterArcfaceRecognitionViewController *_arcfacePickerController;
    UIViewController *_viewController;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_arcface_plugin"
            binaryMessenger:[registrar messenger]];
  UIViewController *viewController = [UIApplication sharedApplication]
        .delegate.window.rootViewController;
  FlutterArcfacePlugin *instance = [[FlutterArcfacePlugin alloc] initWithRoot:viewController];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    _result = result;
  if ([@"active" isEqualToString:call.method]) {
      NSString *ak = [call.arguments objectForKey:@"ak"];
      NSString *sk = [call.arguments objectForKey:@"sk"];
      [self activeEngineWithAK:ak sk:sk];
  } else if ([@"recognize" isEqualToString:call.method]) {
      
      //_arcfacePickerController.maxScore = [NSString stringWithFormat:@"%@", [call.arguments objectForKey:@"similar_threshold"]];
      float similarThreshold = ((NSNumber*)[call.arguments objectForKey:@"similarThreshold"]).floatValue;
      NSData *srcFeature = [self dencode:[call.arguments objectForKey:@"srcFeature"]];
      _arcfacePickerController = [[FlutterArcfaceRecognitionViewController alloc] initWithAction:1
                                                                                   useBackCamera:NO
                                                                                    genImageFile:NO
                                                                                      srcFeature:srcFeature
                                                                                similarThreshold:similarThreshold];
      _arcfacePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
      [_viewController presentViewController:_arcfacePickerController animated:YES completion:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFaceRecognized:)name:@"onFaceRecognized" object:nil];
  } else if ([@"extract" isEqualToString:call.method]) {
      BOOL useBackCamera = ((NSNumber*)[call.arguments objectForKey:@"useBackCamera"]).boolValue;
      BOOL genImageFile = ((NSNumber*)[call.arguments objectForKey:@"genImageFile"]).boolValue;
      _arcfacePickerController = [[FlutterArcfaceRecognitionViewController alloc] initWithAction:0
                                                                                   useBackCamera:useBackCamera
                                                                                    genImageFile:genImageFile
                                                                                      srcFeature:nil
                                                                                similarThreshold:0.0f];
      _arcfacePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
      [_viewController presentViewController:_arcfacePickerController animated:YES completion:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFaceExtracted:)name:@"onFaceExtracted" object:nil];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark -激活虹软人脸识别引擎.
-(void)activeEngineWithAK:(NSString *)ak sk:(NSString *)sk{
    __weak __typeof(self) weakRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong __typeof(weakRef) strongRef = weakRef;
        ArcSoftFaceEngine *engine = [[ArcSoftFaceEngine alloc] init];
        MRESULT mr = [engine activeWithAppId:ak SDKKey:sk];
        NSLog(@"虹软人脸识别引擎激活: %ld", mr);
        NSLog(@"虹软人脸识别引擎版本: %@", [engine getVersion]);
        strongRef->_result([NSNumber numberWithLong:mr]);
       
    });
//    ArcSoftFaceEngine *engine = [[ArcSoftFaceEngine alloc] init];
//    MRESULT mr = [engine activeWithAppId:ak SDKKey:sk];
//    NSLog(@"虹软人脸识别引擎激活: %ld", mr);
//    NSLog(@"虹软人脸识别引擎版本: %@", [engine getVersion]);
//    return (int)mr;
}

#pragma mark -初始化
- (instancetype)initWithRoot:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
    _viewController = viewController;
    _arcfacePickerController = [[FlutterArcfaceRecognitionViewController alloc] init];
    }
  return self;
}
#pragma mark - 图片转NSData类型
- (NSData *)dencode:(NSString *)base64String
{
    return [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
}
#pragma mark - 人员注册返回数据
- (void)onFaceExtracted:(NSNotification *)notification{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    [dictionary setValue:notification.userInfo[@"feature"] forKeyPath:@"feature"];
    [dictionary setValue:notification.userInfo[@"image"] forKeyPath:@"image"];
    _result(dictionary);
}

//#pragma mark - 字典类型转JSON
//-(NSString *)convertJSONWithDic:(NSMutableDictionary *)dic {
//    NSError *err;
//    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&err];
//    if (err) {
//        return @"字典转JSON出错";
//    }
//    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//}

#pragma mark - 人员登录返回
-(void)onFaceRecognized:(NSNotification *)notification{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:2];
    [dictionary setValue:notification.userInfo[@"feature"] forKeyPath:@"feature"];
    [dictionary setValue:notification.userInfo[@"similar"] forKeyPath:@"similar"];
    _result(dictionary);
}

#pragma mark - 删除通知
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"onFaceExtracted" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"onFaceRecognized" object:nil];
}

@end
