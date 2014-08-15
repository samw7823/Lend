//
//  CLOSNewsFeedTableViewCell.h
//  myCloset
//
//  Created by Samantha Wiener on 7/29/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLOSNewsFeedTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *viewLikeButton;
@property (weak, nonatomic) IBOutlet UILabel *itemName;
@property (weak, nonatomic) IBOutlet UIButton *borrowButton;
@property (weak, nonatomic) IBOutlet UIImageView *itemImage;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *unLikeButton;

@end
