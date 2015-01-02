//
//  CLOSAppDelegate.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSAppDelegate.h"

#import <Parse/Parse.h>

#import "CLOSPendingFollowRequestsTableViewController.h"
#import "CLOSloginViewController.h"

NSString * const CLOSUsernamePrefsKey = @"Username";
@interface CLOSAppDelegate () <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, UIAlertViewDelegate>

@end
typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@implementation CLOSAppDelegate
+(void)initialize
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *factorySettings = @{CLOSUsernamePrefsKey : @""};
    [defaults registerDefaults:factorySettings];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    [Parse setApplicationId:@"r0QEPBDtR7d2FdgkCclWCmrBE0Ae48GlPB8tdz96"
                  clientKey:@"XtEqInDDzls72AVG6yUI5ugT9xPHak1ekIuDBJwS"];
    
//    //Register for push notifications
//    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|
//                                                    UIRemoteNotificationTypeAlert|
//                                                    UIRemoteNotificationTypeSound];
    
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
    
    
    
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    CLOSloginViewController *loginvc = [[CLOSloginViewController alloc] init];

    self.window.rootViewController = loginvc;
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    /* if application launched from a push notification */
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if ([[notificationPayload objectForKey:@"isTransactionRequest"] isEqualToString:@"YES"]) {
        loginvc.isFromTransactionNotification = YES;
        loginvc.isFromFollowNotification = NO;
    }
    else if ([[notificationPayload objectForKey:@"isFollowRequest"] isEqualToString:@"YES"]){
        loginvc.isFromFollowNotification = YES;
        loginvc.isFromTransactionNotification = NO;
    }
    
    NSDictionary *localNotification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        loginvc.isFromTransactionNotification = YES;
    }

    //Launch facebook
    [PFFacebookUtils initializeFacebook];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    if (self.tbc) { // logged in
        UINavigationController *nav = self.tbc.viewControllers[self.tbc.selectedIndex];
        UIViewController *vc = [nav.viewControllers lastObject];
        if (vc.presentedViewController) { // end editing in the presented view
            [vc.presentedViewController.view endEditing:YES];
        }
        else { // otherwise end editing in current view
            [vc.view endEditing:YES];
        }
    }
    else { // at login or sign up
        if (self.window.rootViewController.presentedViewController) { // in sign up
            [self.window.rootViewController.presentedViewController.view endEditing:YES];
        }
        else { // in login
            [self.window.rootViewController.view endEditing:YES];
        }
    }
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBAppCall handleDidBecomeActiveWithSession:[PFFacebookUtils session]];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


-(BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    self.previousIndex = tabBarController.selectedIndex;
    return YES;
}

//Method called if push notification registration is successful
- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

//Display push notification when app is being used
- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSString *isTransactionRequest = [userInfo objectForKey:@"isTransactionRequest"];
    NSString *isAcceptTransactionRequest = [userInfo objectForKey:@"isAcceptTransactionRequest"];
    NSString *isRejectTransactionRequest = [userInfo objectForKey:@"isRejectTransactionRequest"];
    NSString *isFollowRequest = [userInfo objectForKey:@"isFollowRequest"];
    if ([isTransactionRequest isEqualToString:@"YES"] ||
        [isAcceptTransactionRequest isEqualToString:@"YES"] ||
        [isRejectTransactionRequest isEqualToString:@"YES"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lend"
                                                        message:userInfo[@"aps"][@"alert"]
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:@"View", nil];
        [alert show];

    }
    //check if follow request
    else if ([isFollowRequest isEqualToString:@"YES"]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lend" message:userInfo[@"aps"][@"alert"] delegate:self cancelButtonTitle:@"Ignore" otherButtonTitles:@"View", nil];
        alert.tag = 17;
        [alert show];
    }
    else{
        [PFPush handlePush:userInfo];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 17) {
        if (buttonIndex == 1) {
            //if you clicked on view, dismiss current view
            UINavigationController *oldNav = (UINavigationController *)self.tbc.selectedViewController;

            if (oldNav.presentedViewController) {
                [oldNav dismissViewControllerAnimated:YES completion:NULL];
            }

            [oldNav popToRootViewControllerAnimated:NO];
            self.tbc.selectedIndex = 4;
            UINavigationController *nav = (UINavigationController *)self.tbc.selectedViewController;
            [nav popToRootViewControllerAnimated:NO];

            //query for pending requests
            PFUser *user = [PFUser currentUser];
            PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
            [query orderByDescending:@"createdAt"];
            [query whereKey:@"to" equalTo:user];
            [query includeKey:@"from"];
            [query whereKey:@"verificationState" equalTo:@(requested)];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                CLOSPendingFollowRequestsTableViewController *pendingvc = [[CLOSPendingFollowRequestsTableViewController alloc] init];
                pendingvc.pendingRequests = objects;
                //go to the pending request
                [nav pushViewController:pendingvc animated:YES];
            }];


        }
    }else{
        if (buttonIndex == 1) {
            //Pop and dismiss everthing on the current tab
            UINavigationController *oldNav = (UINavigationController *)self.tbc.selectedViewController;

            if (oldNav.presentedViewController) {
                [oldNav dismissViewControllerAnimated:YES completion:NULL];
            }

            [oldNav popToRootViewControllerAnimated:NO];
            self.tbc.selectedIndex = 3;
            UINavigationController *nav = (UINavigationController *)self.tbc.selectedViewController;
            [nav popToRootViewControllerAnimated:NO];

            //Set the badge value of the inventory tab
            PFQuery *lendTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
            [lendTransactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
            [lendTransactionQuery whereKey:@"hasUpdatedForOwner" equalTo:@YES];

            PFQuery *borrowTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
            [borrowTransactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
            [borrowTransactionQuery whereKey:@"hasUpdatedForBorrower" equalTo:@YES];

            PFQuery *countTransactionQuery = [PFQuery orQueryWithSubqueries:@[lendTransactionQuery, borrowTransactionQuery]];
            [countTransactionQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                if (number > 0)
                    nav.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", number];
                else
                    nav.tabBarItem.badgeValue = nil;
            }];
        }

    }
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    //local notification for borrowing / lending
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lend" message:notification.alertBody delegate:self cancelButtonTitle:@"OK" otherButtonTitles:@"View",nil];
    [alert show];
}
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [FBAppCall handleOpenURL:url
                  sourceApplication:sourceApplication
                        withSession:[PFFacebookUtils session]];
}

@end
