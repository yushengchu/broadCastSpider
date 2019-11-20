//
//  AppDelegate.m
//  BroadCastSpider
//
//  Created by sandsyu on 2019/11/18.
//  Copyright © 2019 sandsyu. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "BackgroundService.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    ViewController* vc = [[ViewController alloc] init];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[BackgroundService shared] keepAlive];
}

@end
