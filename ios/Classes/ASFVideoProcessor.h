//
//  ASFVideoProcessor.h
//

#import <Foundation/Foundation.h>
#import <ArcSoftFaceEngine/ArcSoftFaceEngineDefine.h>
#import "Utility.h"
@class ASFRPerson;
@protocol ASFVideoProcessorDelegate <NSObject>

- (void)processRecognized:(NSString*)errorStr WithType:(NSInteger)type ;

@end

@interface ASFFace3DAngle : NSObject
@property(nonatomic,assign) MFloat rollAngle;
@property(nonatomic,assign) MFloat yawAngle;
@property(nonatomic,assign) MFloat pitchAngle;
@property(nonatomic,assign) MInt32 status;
@end

@interface ASFVideoFaceInfo : NSObject
@property(nonatomic,assign) MRECT faceRect;
@property(nonatomic,assign) MInt32 age;
@property(nonatomic,assign) MInt32 gender;
@property(nonatomic,strong) ASFFace3DAngle *face3DAngle;
@property(nonatomic,assign) MByte byte;
@end

@interface ASFVideoProcessor : NSObject

@property(nonatomic, assign) BOOL detectFaceUseFD;
@property(nonatomic, weak) id<ASFVideoProcessorDelegate> delegate;

- (void)initProcessor;
- (void)uninitProcessor;
- (NSArray*)process:(ASF_CAMERA_DATA*)cameraData WithDataInfo:(NSData *)imageData WithMaxScore:(NSString *)maxScore WithType:(NSInteger)type WithImageInfo:(UIImage *)imageInfo;
@end
