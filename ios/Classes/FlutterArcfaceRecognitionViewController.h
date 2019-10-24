//
//  FlutterArcfaceRecognitionViewController.h
//  flutter_arcface_plugin
//
//  Created by iMac on 2019/10/16.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterArcfaceRecognitionViewController : UIViewController
@property (nonatomic, assign)NSInteger type;
@property (nonatomic, strong)NSData *videoData;
@property (nonatomic, copy)NSString *maxScore;
@property (nonatomic, assign)BOOL isPositionBack;
@end

NS_ASSUME_NONNULL_END
