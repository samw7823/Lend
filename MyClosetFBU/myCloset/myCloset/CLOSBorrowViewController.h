//
//  CLOSBorrowViewController.h
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CLOSBorrowViewController : UIViewController

@property (nonatomic, strong) NSString *itemName;
@property (nonatomic, strong) PFUser *itemOwner;
@property (nonatomic, strong) PFObject *item;

@end
