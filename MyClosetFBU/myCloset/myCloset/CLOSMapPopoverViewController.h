//
//  CLOSMapPopoverViewController.h
//  myCloset
//
//  Created by Samantha Wiener on 8/4/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CLOSMapPopoverViewController : UIViewController
@property (nonatomic, strong) NSMutableArray *stringAddressesToAdd;
@property (nonatomic) PFObject *item;
@property (nonatomic, copy) NSArray *following;
@property (nonatomic, copy) NSMutableArray *locationArray;
@end
