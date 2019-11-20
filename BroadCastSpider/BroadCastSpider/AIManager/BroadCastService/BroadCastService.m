//
//  BroadCastService.m
//  broadCast
//
//  Created by sandsyu on 2019/11/18.
//  Copyright © 2019 sandsyu. All rights reserved.
//

#import "BroadCastService.h"
#import "SampleBufferManager.h"

@interface BroadCastService()
@property (nonatomic, strong) __attribute__((NSObject)) CMSampleBufferRef sampleBuffer;
@property (nonatomic, assign) BOOL uploadStatus;//是否正在请求中
@property (nonatomic, strong) NSMutableURLRequest *request;
@end

#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;

@implementation BroadCastService

+ (BroadCastService*)shared {
    static BroadCastService* share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[BroadCastService alloc]init];
    });
    return share;
}

//不直接转换为image对象 刷新挂载的lastFrame
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    self.sampleBuffer = sampleBuffer;
}

- (void)start {
    [self postStart];//通知主APP 录屏开启
}

- (void)postStart {
    __weak BroadCastService* weakSelf = self;
    NSString* url = [NSString stringWithFormat:@"http://127.0.0.1:27370/statusStart"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 2.0f;
    NSURLSessionDataTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error){
            NSLog(@"请求失败 请检查HTTP Server是否未开启");
        }
        NSError *theError;
        id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&theError];
        if (jsonData && jsonData[@"code"] && [jsonData[@"code"] isEqualToString:@"1"]) {
            //通知成功
            NSLog(@"请求成功 主APP获得录屏开启状态");
            //开始发送图片
            [weakSelf lowerPutFrame];
        }else {
            NSLog(@"请求失败 请检查HTTP Server是否未开启");
        }
    }];
    [task resume];
}


- (void)lowerPutFrame {
    //不存在最后一帧 睡一下等一等
    if (!self.sampleBuffer) {
        [self sleepWithPostImage];
        return;
    }
    if (!self.uploadStatus) {//存在最后一帧 且当前不处于请求中的状态
        @autoreleasepool {
            CMSampleBufferRef m_sampleBuffer = nil;
            CMSampleBufferCreateCopy(kCFAllocatorDefault, self.sampleBuffer, &m_sampleBuffer);
            UIImage *newImage = [SampleBufferManager getImageWithSampleBuffer:m_sampleBuffer];
            NSData* newData = UIImageJPEGRepresentation(newImage, 1.0f);
            CFRelease(m_sampleBuffer);
            [self postImageToLocalService:newData];
        }
    }

}

//每次请求完成后休息0.2s再发下一次请求
- (void)sleepWithPostImage {
    NSLog(@"休息一下 延迟调用 ---------- ");
    @WeakObj(self)
    double delayInSeconds = 0.5f;
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW,delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, queue, ^{
        [selfWeak lowerPutFrame];
    });
}

//给主APP post图片
- (void)postImageToLocalService:(NSData*)data {
    NSLog(@"发送图片给APP ---------------");
    @WeakObj(self);
    self.uploadStatus = YES;
    NSString* url = [NSString stringWithFormat:@"http://127.0.0.1:27370/postAIData"];
    self.request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    self.request.HTTPMethod = @"POST";
    self.request.HTTPBody = data;
    [NSURLConnection sendAsynchronousRequest:self.request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {  // 当请求结束的时候调用
        NSLog(@"图片发送完毕 ---------------");
        selfWeak.request = nil;
        selfWeak.uploadStatus = NO;
        [selfWeak sleepWithPostImage];
    }];
}
@end
