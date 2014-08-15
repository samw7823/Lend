//
//  CLOSReportAUserView.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSReportAUserView.h"

@interface CLOSReportAUserView ()

@end

@implementation CLOSReportAUserView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        /* table view */
        CGFloat halfHeight = [[UIScreen mainScreen] bounds].size.height / 2.0;
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        
        self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, width, halfHeight) style:UITableViewStylePlain];
        // set display options
        self.tableView.backgroundColor = [UIColor clearColor];
        self.tableView.tintColor = [UIColor whiteColor];
        
        // make sure user can't scroll and can only select one option
        self.tableView.scrollEnabled = NO;
        self.tableView.multipleTouchEnabled = NO;
        
        // register a class for cells
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        
        // add it as a subview to the view
        [self addSubview:self.tableView];
        /* end table view */
        
        
        /* cancel button */
        self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.cancelButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"X"
                                                                            attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0],
                                                                                         NSForegroundColorAttributeName : [UIColor whiteColor]}]
                                   forState: UIControlStateNormal];
        
        // add it as a subview to the view
        [self addSubview:self.cancelButton];
        /*end cancel button */
        
        
        /* send button */
        self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.sendButton.layer.cornerRadius = 8.0f;
        self.sendButton.backgroundColor = [UIColor colorWithWhite:.33 alpha:.5];
        [self.sendButton setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Send"
                                                                           attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0],
                                                                                        NSForegroundColorAttributeName : [UIColor whiteColor]}]
                                   forState: UIControlStateNormal];
        

        // add it as a subview to the view
        [self addSubview:self.sendButton];
        /* end send button */
        
        
        
        
        
        // set background image for the view
        self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
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
