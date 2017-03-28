//
//  AppDelegate.m
//  LLYRtmpDemo
//
//  Created by lly on 2017/3/1.
//  Copyright © 2017年 lly. All rights reserved.
//

#import "AppDelegate.h"
#import "LLYAudienceVC.h"
#import "LLYDirectorVC.h"

@interface AppDelegate ()<UIAlertViewDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"提示" message:@"请表明身份" delegate:self cancelButtonTitle:@"我要当主播" otherButtonTitles:@"我要当观众", nil];
    [alertView show];

    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    if (buttonIndex == 0) {
        
        LLYDirectorVC *directorVC = [[LLYDirectorVC alloc]init];
        self.window.rootViewController = directorVC;
        [self.window makeKeyAndVisible];
        
    }
    else if (buttonIndex == 1) {
        LLYAudienceVC *audienceVC = [[LLYAudienceVC alloc]init];
        self.window.rootViewController = audienceVC;
        [self.window makeKeyAndVisible];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
