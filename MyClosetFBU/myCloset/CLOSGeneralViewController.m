//
//  CLOSGeneralViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/13/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSGeneralViewController.h"

@interface CLOSGeneralViewController () <UIScrollViewDelegate>

@end

@implementation CLOSGeneralViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    // make compatible for 3.5 inch
    if ([UIScreen mainScreen].bounds.size.height != 568) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        sv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
        sv.scrollEnabled = YES;
        sv.contentSize = CGSizeMake(320, 568);
        [sv addSubview:self.view];
        self.view = sv;
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
