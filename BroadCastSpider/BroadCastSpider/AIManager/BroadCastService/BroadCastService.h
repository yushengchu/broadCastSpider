//
//  BroadCastService.h
//  broadCast
//
//  Created by sandsyu on 2019/11/18.
//  Copyright © 2019 sandsyu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BroadCastService : NSObject

+ (BroadCastService*)shared;

- (void)start;//开始录屏
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
