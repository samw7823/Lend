//
//  CLOSPendingFollowRequestsTableViewCell.h
//  myCloset
//
//  Created by Rachel Pinsker on 8/4/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLOSPendingFollowRequestsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *rejectButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;

@end
