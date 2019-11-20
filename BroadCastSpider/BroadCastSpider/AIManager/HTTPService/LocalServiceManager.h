//
//  LocalServiceManager.h
//
//
//  Created by sandsyu on 2019/8/27.
//  Copyright © 2019 Scorpion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  出错原因
 */
typedef NS_OPTIONS(NSInteger, MXAIBroadCastStatus) {
    // 网络异常
    STRAT = 1,
    END
};
typedef void(^imageCallBack) (NSInteger status,id image);
typedef void(^broadStatusBlock) (MXAIBroadCastStatus status);

@interface LocalServiceManager : NSObject

+ (LocalServiceManager*)shared;

- (void)httpPostImageMonitor:(imageCallBack)imageCallBack;

- (void)broadCastStatusMonitor:(broadStatusBlock)broadStatusBlock;

- (void)postImage:(UIImage*)image;

- (void)postSatus:(MXAIBroadCastStatus)status;

@end


