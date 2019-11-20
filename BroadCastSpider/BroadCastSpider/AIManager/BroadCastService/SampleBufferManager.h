//
//  MXSampleBufferManager.h
//  MoxieAISDK
//
//  Created by joker on 2018/9/18.
//  Copyright © 2018 Scorpion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SampleBufferManager : NSObject

+ (UIImage*)getImageWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
