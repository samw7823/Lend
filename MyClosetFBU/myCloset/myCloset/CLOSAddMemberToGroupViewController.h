//
//  CLOSAddMemberToGroupViewController.h
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Parse/Parse.h>

@interface CLOSAddMemberToGroupViewController : UIViewController

@property (strong, nonatomic) PFObject *group;
@property (copy, nonatomic) NSArray *alreadyMembers;

@end
