//
//  CLOSInventoryTableViewCell.m
//  myCloset
//
//  Created by Samantha Wiener on 7/16/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSInventoryTableViewCell.h"


@implementation CLOSInventoryTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    self.acceptButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:15.0];
    self.rejectButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:15.0];
    
    
    self.acceptButton.backgroundColor = [UIColor colorWithRed:14.0f/255.0f green:114.0f/255.0f blue:0.0 alpha:.6];
    self.rejectButton.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:48.0f/255.0f blue:0.0 alpha:.6];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
