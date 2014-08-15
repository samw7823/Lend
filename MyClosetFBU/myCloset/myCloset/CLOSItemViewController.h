//
//  CLOSItemViewController.h
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface CLOSItemViewController : UIViewController

@property (nonatomic, strong) PFObject *item;
@end
