//
//  ViewController.m
//  BroadCastSpider
//
//  Created by sandsyu on 2019/11/18.
//  Copyright © 2019 sandsyu. All rights reserved.
//

#import "ViewController.h"
#import "HTTPServer.h"
#import "SCHTTPConnection.h"
#import "LocalServiceManager.h"
#import "TensorFlowService.h"
#import <ReplayKit/ReplayKit.h>
#import "BackgroundService.h"

@interface ViewController ()
@property (nonatomic, strong) HTTPServer *httpServer;//HTTP服务端
@property (nonatomic, strong) TensorFlowService *tfls;
@property (nonatomic, strong) UIImage *lastFrame;

@property (nonatomic, copy) NSDictionary* pageInfo;
@end

#define WeakObj(o) autoreleasepool{} __weak typeof(o) o##Weak = o;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configUI];
    self.tfls = [[TensorFlowService alloc] init];
    //开启HTTP Service
    [self startHttpService];
}


- (void)configUI {
    RPSystemBroadcastPickerView* pick = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    pick.showsMicrophoneButton = NO;
    pick.backgroundColor = [UIColor redColor];
    pick.center = self.view.center;
    [self.view addSubview:pick];
}

#pragma mark 开启http服务
- (void)startHttpService {
    self.httpServer = [[HTTPServer alloc] init];
    [self.httpServer setType:@"_http._tcp."];
    [self.httpServer setConnectionClass:[SCHTTPConnection class]];
    NSError *error = nil;
    [self.httpServer setPort:27370];
    if([self.httpServer start:&error]){
        NSLog(@"startHttpService Success port:27370");
        [self addHttpServerObservice];
    }else {
        NSLog(@"Error starting HTTP Server: %@", error);
    }
}

//监听录屏返回的数据
- (void)addHttpServerObservice {
    @WeakObj(self);
    //监听获取到的图片
    [[LocalServiceManager shared] httpPostImageMonitor:^(NSInteger status, UIImage *image) {
        if(status && image) {
            if (image) {
                [selfWeak tensorFlowMatch:image];
            }
        }
    }];
    
    [[LocalServiceManager shared] broadCastStatusMonitor:^(MXAIBroadCastStatus status) {
        NSLog(@"收到录屏启动的消息");
    }];
}

- (void)tensorFlowMatch:(UIImage*)image {
    @WeakObj(self);
    [self.tfls identifyImage:image result:^(NSArray * _Nonnull result) {
        [selfWeak matchImageResult:result image:image];
    }];
}

- (void)matchImageResult:(NSArray*)result image:(UIImage*)image{
    for (NSDictionary* pageInfo in result) {
        NSInteger per = pageInfo[@"per"] ? [pageInfo[@"per"] integerValue] : 0;//置信度
        NSString* pageStr = pageInfo[@"page"];
        NSLog(@"当前页面为:%@ 置信度:%ld%%",pageStr,(long)per);

        /**
         在这里判断是否是关键帧
         关键帧上传服务器进行OCR爬取数据
         */
    }
}

//@"apple_control_center_ios11": @"iOS11控制中心页面",
//@"apple_control_center_ios12": @"iOS12控制中心页面",
//@"multi_task": @"iOS多任务页面",
//@"mobile_desktop": @"iOS桌面",
//@"wechat_account_security": @"微信账号安全页面",
//@"wechat_account_security_7": @"微信账号安全页面(7.0)",
//@"wechat_change_account": @"切换账号页面",
//@"wechat_contacts": @"微信通讯录页面",
//@"wechat_contacts_7": @"微信通讯录页面(7.0)",
//@"discover": @"微信发现页面",
//@"wechat_discover_7": @"微信发现页面(7.0)",
//@"wechat_me": @"微信我的页面",
//@"wechat_me_7": @"微信我的页面(7.0)",
//@"wechat_settings": @"微信设置页面",
//@"wechat_settings_7": @"微信设置页面(7.0)",
//@"wechat_wallet": @"微信钱包页面",
//@"wechat_wallet_7": @"微信钱包页面(7.0)",
//@"wechat_weilidai": @"微信微粒贷页面"

@end
