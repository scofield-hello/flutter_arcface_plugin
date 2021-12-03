//
//  ArcSoftActiveInfo.h
//  ArcSoftFaceEngine
//
//  Created by tao guo on 2020/1/10.
//  Copyright © 2020 noit. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArcSoftActiveInfo : NSObject

@property(nonatomic, strong, readonly) NSString* appId;
@property(nonatomic, strong, readonly) NSString* sdkKey;
@property(nonatomic, strong, readonly) NSString* platform;
@property(nonatomic, strong, readonly) NSString* sdkType;
@property(nonatomic, strong, readonly) NSString* sdkVersion;
@property(nonatomic, strong, readonly) NSString* fileVersion;
@property(nonatomic, strong, readonly) NSString* startTime;
@property(nonatomic, strong, readonly) NSString* endTime;

@end

NS_ASSUME_NONNULL_END
