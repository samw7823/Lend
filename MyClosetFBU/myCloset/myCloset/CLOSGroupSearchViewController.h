//
//  CLOSGroupSearchViewController.h
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface CLOSGroupSearchViewController : UIViewController
@property (nonatomic, copy) NSArray *groupItems;
@property (nonatomic, assign) PFObject *group; //used if groupItems isnt passed
@end
