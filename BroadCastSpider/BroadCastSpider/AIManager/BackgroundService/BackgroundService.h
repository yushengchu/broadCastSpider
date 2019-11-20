//
//  BackgroundService.h
//  
//
//  Created by joker on 2018/9/17.
//  Copyright © 2018 Scorpion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BackgroundService : NSObject

+ (BackgroundService*)shared;
- (void)keepAlive;
- (void)endKeepAlive;

@end

NS_ASSUME_NONNULL_END
