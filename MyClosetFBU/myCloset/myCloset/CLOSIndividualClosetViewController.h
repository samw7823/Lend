//
//  CLOSIndividualClosetViewController.h
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CLOSIndividualClosetViewController : UIViewController

@property (nonatomic, strong) PFObject *closet;
@property (nonatomic, strong) PFUser *user;

@end
