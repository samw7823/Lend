//
//  CLOSAppDelegate.h
//  myCloset
//
//  Created by Rachel Pinsker on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const CLOSUsernamePrefsKey;

@interface CLOSAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, assign) NSInteger previousIndex;
@property (nonatomic, strong) UITabBarController *tbc;

@end
