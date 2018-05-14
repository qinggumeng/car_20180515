//
//  AppDelegate.m
//  iOS_3D_RecordPath
//
//  Created by PC on 15/8/31.
//  Copyright (c) 2015年 FENGSHENG. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "TestViewController.h"
#import "AgreementViewController.h"
#import "APIKey.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    
    [AMapServices sharedServices].apiKey = (NSString *)APIKey;
    
    MainViewController *main2ViewController = [[MainViewController alloc] init];
    TestViewController *testViewController = [[TestViewController alloc] init];
    
    AgreementViewController *agreeViewController = [[AgreementViewController alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token = [defaults objectForKey:@"token"];
    NSString *agree = [defaults objectForKey:@"agree"];
    
    if(token==nil){
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:testViewController];
    }else if(agree==nil){
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:agreeViewController];
    }else{
         self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:main2ViewController];
    }
    
   
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
