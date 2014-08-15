//
//  CLOSNewsFeedHeaderView.m
//  myCloset
//
//  Created by Ruoxi Tan on 8/12/14.
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import "CLOSNewsFeedHeaderView.h"

@implementation CLOSNewsFeedHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.9];
        //add location button
        _locationButton = [[UIButton alloc] initWithFrame:CGRectMake(53, 35, [UIScreen mainScreen].bounds.size.width - 53 - 20, 15)];
        _locationButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_locationButton setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_locationButton];
        //add username button
        _usernameButton = [[UIButton alloc] initWithFrame:CGRectMake(53, 10, 166, 15)];
        _usernameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_usernameButton setBackgroundColor:[UIColor clearColor]];
        [self addSubview:_usernameButton];
        //add time label
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(245, 4, 100, 29)];
        //add time image
        UIImage *timeImage = [UIImage imageNamed:@"timeIcon.png"];
        //add UIImageView as a subview for the label
        UIImageView *timeView = [[UIImageView alloc] initWithImage:timeImage];
        timeView.frame = CGRectMake(0, 6, 15.0, 15.0);
        [_timeLabel addSubview:timeView];
        [self addSubview:_timeLabel];
        //add profile view
        _profileView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 10, 40, 40)];
        [self addSubview:_profileView];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
