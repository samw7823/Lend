//
//  CLOSFriendListViewController.h
//  myCloset
//
//  Created by Rachel Pinsker on 7/14/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CLOSFriendListViewController : UIViewController

@property (strong, nonatomic) PFUser *user;
@property (nonatomic) BOOL isFollowers; //YES if clicked followers, NO if clicked following

@end
