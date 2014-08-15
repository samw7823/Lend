//
//  CLOSSearchTableViewCell.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/15/14.
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import "CLOSSearchTableViewCell.h"

@implementation CLOSSearchTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    self.image.layer.cornerRadius = 8.0f;
    self.image.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
