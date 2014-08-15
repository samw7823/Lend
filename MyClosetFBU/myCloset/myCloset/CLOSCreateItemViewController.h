//
//  CLOSCreateItemViewController.h
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface CLOSCreateItemViewController : UIViewController
//@property (strong, nonatomic) NSString *closetId;
//@property (strong, nonatomic) NSString *closetName;
@property (strong, nonatomic) PFObject *closet;
@property (nonatomic) UIImage *image;
@property (nonatomic) BOOL isGroupItem;
@property (nonatomic) PFObject *group;
@end
