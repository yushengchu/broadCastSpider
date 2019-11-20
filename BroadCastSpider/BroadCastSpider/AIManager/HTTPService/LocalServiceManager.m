//
//  LocalServiceManager.m
//  
//
//  Created by sandsyu on 2019/8/27.
//  Copyright © 2019 Scorpion. All rights reserved.
//

#import "LocalServiceManager.h"

@interface LocalServiceManager()
@property (nonatomic, strong) imageCallBack callBack;
@property (nonatomic, strong) broadStatusBlock statusBlock;
@end

@implementation LocalServiceManager

+ (LocalServiceManager*)shared {
    static LocalServiceManager* share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[LocalServiceManager alloc]init];
    });
    return share;
}


- (void)httpPostImageMonitor:(imageCallBack)imageCallBack {
    self.callBack = imageCallBack;
}

- (void)postImage:(UIImage*)image {
    if (self.callBack) {
        self.callBack(1, [image copy]);
    }
}

- (void)broadCastStatusMonitor:(broadStatusBlock)broadStatusBlock {
    self.statusBlock = broadStatusBlock;
}

- (void)postSatus:(MXAIBroadCastStatus)status {
    if (self.statusBlock) {
        self.statusBlock(status);
    }
}
@end
