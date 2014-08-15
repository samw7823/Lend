//
//  CLOSSearchTableViewCell.h
//  myCloset
//
//  Created by Ruoxi Tan on 7/15/14.
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import <UIKit/UIKit.h>

@interface CLOSSearchTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *itemName;
@property (weak, nonatomic) IBOutlet UILabel *itemDescription;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;

@end
