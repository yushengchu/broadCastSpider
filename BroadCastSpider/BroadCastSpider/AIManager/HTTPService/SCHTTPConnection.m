//
//  SCHTTPConnection.m
//
//
//  Created by sandsyu on 2019/8/27.
//  Copyright © 2019 Scorpion. All rights reserved.
//

#import "SCHTTPConnection.h"
#import "HTTPMessage.h"
#import "HTTPDataResponse.h"
#import "DDNumber.h"
#import "HTTPLogging.h"
#import <AdSupport/ASIdentifierManager.h>

#import <UIKit/UIKit.h>
#import "LocalServiceManager.h"

static const int httpLogLevel = LOG_LEVEL_WARN;


@implementation SCHTTPConnection

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path{
    return YES;
}


#pragma mark - get & post

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path{
    //获取任务
    NSData *responseData = [NSJSONSerialization dataWithJSONObject:@{@"code":@"1"} options:0 error:nil];
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/postAIData"]){
        NSData *requestData = [request body];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            UIImage* image = [[UIImage alloc] initWithData:requestData];
            [[LocalServiceManager shared] postImage:image];
        });
        return [[HTTPDataResponse alloc] initWithData:responseData];
        
    }else if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/statusStart"]){//收到开始录屏的请求
        [[LocalServiceManager shared] postSatus:STRAT];
        return [[HTTPDataResponse alloc] initWithData:responseData];
        
    }
    return [[HTTPDataResponse alloc] initWithData:responseData];
}


- (void)processBodyData:(NSData *)postDataChunk
{
	HTTPLogTrace();
	BOOL result = [request appendData:postDataChunk];
	if (!result)
	{
		HTTPLogError(@"%@[%p]: %@ - Couldn't append bytes!", THIS_FILE, self, THIS_METHOD);
	}
}

#pragma mark - 私有方法

//获取上行参数
- (NSDictionary *)getRequestParam:(NSData *)rawData
{
    if (!rawData) return nil;
    
    NSString *raw = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
    NSMutableDictionary *paramDic = [NSMutableDictionary dictionary];
    NSArray *array = [raw componentsSeparatedByString:@"&"];
    for (NSString *string in array) {
        NSArray *arr = [string componentsSeparatedByString:@"="];
        NSString *value = [arr.lastObject stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [paramDic setValue:value forKey:arr.firstObject];
    }
    return [paramDic copy];
}

@end
