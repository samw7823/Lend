//
//  CLOSSignUpDetailViewController.h
//  myCloset
//
//  Created by Samantha Wiener on 7/24/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CLOSSignUpDetailViewController : UIViewController <NSURLConnectionDelegate>

@property (nonatomic, assign) PFUser *user;

@end
