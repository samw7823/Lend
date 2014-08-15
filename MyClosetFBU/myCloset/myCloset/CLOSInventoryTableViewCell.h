//
//  CLOSInventoryTableViewCell.h
//  myCloset
//
//  Created by Samantha Wiener on 7/16/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CLOSInventoryTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *userName;
@property (weak, nonatomic) IBOutlet UILabel *itemName;
@property (weak, nonatomic) IBOutlet UILabel *itemDate; //lend date
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;
@property (strong, nonatomic) PFUser *user;
@property (weak, nonatomic) IBOutlet UILabel *requestStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *returnDate;

@end
