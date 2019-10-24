#import "FlutterArcfacePlugin.h"
#import "FlutterArcfaceRecognitionViewController.h"
#import <ArcSoftFaceEngine/ArcSoftFaceEngine.h>
@implementation FlutterArcfacePlugin{
    FlutterResult _result;
    FlutterMethodCall *_call;
    NSDictionary *_arguments;
    FlutterArcfaceRecognitionViewController *_arcfacePickerController;
    UIViewController *_viewController;
    double similar;
    FlutterMethodChannel* methodChannel;
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_arcface_plugin"
            binaryMessenger:[registrar messenger]];
  FlutterArcfacePlugin* instance = [[FlutterArcfacePlugin alloc] init];
    if (@available(iOS 5.0, *)) {
        UIViewController *viewController =
        [UIApplication sharedApplication].delegate.window.rootViewController;
        instance =
        [[FlutterArcfacePlugin alloc] initWithViewController:viewController];
    } else {
        // Fallback on earlier versions
    }
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"active" isEqualToString:call.method]) {
      result(@([self engineWithAK:[call.arguments objectForKey:@"ak"] sk:[call.arguments objectForKey:@"sk"]]));
  } else if ([@"recognize" isEqualToString:call.method]) {
      _result = nil;
      _result = result;
      _arcfacePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
      _arcfacePickerController.type = 1;
      _arcfacePickerController.isPositionBack = NO;
      _arcfacePickerController.maxScore = [NSString stringWithFormat:@"%@", [call.arguments objectForKey:@"similar_threshold"]];
      _arcfacePickerController.videoData = [self dencode:[call.arguments objectForKey:@"src_feature"]];
      [_viewController presentViewController:_arcfacePickerController animated:YES completion:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backFaceSuccess:)name:@"backFaceSuccess" object:nil];
  } else if ([@"extract" isEqualToString:call.method]) {
      _result = result;
      _arcfacePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
      _arcfacePickerController.type = 0;
      _arcfacePickerController.isPositionBack = YES;
      [_viewController presentViewController:_arcfacePickerController animated:YES completion:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backFaceInfo:)name:@"backFaceInfo" object:nil];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark -激活引擎错误代码返回
-(int)engineWithAK:(NSString *)ak sk:(NSString *)sk
{
    ArcSoftFaceEngine *engine = [[ArcSoftFaceEngine alloc] init];
    MRESULT mr = [engine activeWithAppId:ak SDKKey:sk];
    return [[NSString stringWithFormat:@"%ld", mr] intValue];
}

#pragma mark -初始化
- (instancetype)initWithViewController:(UIViewController *)viewController {
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
- (void)backFaceInfo:(NSNotification *)text{
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:0];
    [dic setValue:text.userInfo[@"feature"] forKeyPath:@"feature"];
    [dic setValue:text.userInfo[@"image"] forKeyPath:@"image"];
    _result([self convertJSONWithDic:dic]);
}

#pragma mark - 字典类型转JSON
-(NSString *)convertJSONWithDic:(NSMutableDictionary *)dic {
    NSError *err;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&err];
    if (err) {
        return @"字典转JSON出错";
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - 人员登录返回
-(void)backFaceSuccess:(NSNotification *)text{
    if (text.userInfo[@"similar"] != nil) {
        double similar = [text.userInfo[@"similar"] doubleValue]/100;
        _result(@(similar));
    }
}

#pragma mark - 删除通知
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"backFaceInfo" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"backFaceSuccess" object:nil];
}

@end
