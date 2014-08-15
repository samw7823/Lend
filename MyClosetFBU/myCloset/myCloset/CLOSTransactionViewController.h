//
//  CLOSTransactionViewController.h
//  myCloset
//
//  Created by Samantha Wiener on 7/17/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>


@interface CLOSTransactionViewController : UIViewController

//@property (nonatomic, strong) NSString *transactionId;
@property (nonatomic, strong) PFObject *transaction;
@property (nonatomic, strong) PFObject *requestedOfUser;
@property (nonatomic, strong) PFObject *requestToBorrow;
@property (nonatomic) BOOL isMyRequests;

@end
