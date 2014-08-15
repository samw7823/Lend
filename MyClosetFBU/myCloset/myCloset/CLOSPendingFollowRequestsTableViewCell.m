//
//  CLOSPendingFollowRequestsTableViewCell.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/4/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSPendingFollowRequestsTableViewCell.h"

@implementation CLOSPendingFollowRequestsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
