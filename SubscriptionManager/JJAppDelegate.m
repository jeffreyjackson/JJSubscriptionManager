//
//  JJAppDelegate.m
//  SubscriptionManager
//
//  Created by Jeffrey Jackson 6/25/2015
//

#import "JJAppDelegate.h"
#import "JJSubscriptionViewController.h"
#import "JJSubscriptionManager.h"

@implementation JJAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [JJSubscriptionManager sharedManager];
    
    JJSubscriptionViewController *vc = [[JJSubscriptionViewController alloc] init];
    self.window.rootViewController = vc;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
