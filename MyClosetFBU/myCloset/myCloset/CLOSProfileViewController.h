//
//  CLOSProfileViewController.h
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CLOSProfileViewController : UIViewController

@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) NSMutableArray *myClosets;
@property (strong, nonatomic) UIImage *profileImage;

- (IBAction)seeMap:(id)sender;
- (void) checkReachability;

@end
