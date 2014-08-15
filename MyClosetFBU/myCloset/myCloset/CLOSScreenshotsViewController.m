//
//  CLOSScreenshotsViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/11/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSScreenshotsViewController.h"

@interface CLOSScreenshotsViewController () <UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UILabel *tutorialHeaderLabel;


#define NUM_PAGES 8

@end

@implementation CLOSScreenshotsViewController

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
    
    self.pageControl.numberOfPages = NUM_PAGES;
    
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:self.view.frame];
    sv.contentSize = CGSizeMake(sv.frame.size.width * self.pageControl.numberOfPages, sv.frame.size.width);
    sv.pagingEnabled = YES;
    sv.delegate = self;
    
    for (int i = 0; i < (NUM_PAGES - 1); i++) { // make the views to display
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(i * [UIScreen mainScreen].bounds.size.width + 20, 70, [UIScreen mainScreen].bounds.size.width - 40, [UIScreen mainScreen].bounds.size.height - 110)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"image[%d]",i]];
        [sv addSubview:imageView];
    }
    
    // make a button that allows user to begin using the app
    UIButton *readyButton = [[UIButton alloc] initWithFrame:CGRectMake((NUM_PAGES - 1) * [UIScreen mainScreen].bounds.size.width, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    readyButton.titleLabel.numberOfLines = 5;
    readyButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, 8);
    [readyButton setTitle:@"Now you're ready\nto begin\nusing Lend!\nClick anywhere to get started" forState:UIControlStateNormal];
    readyButton.titleLabel.font = [UIFont fontWithName:@"MarkerFelt-Thin" size:35.0];
    readyButton.tintColor = [UIColor whiteColor];
    readyButton.titleLabel.hidden = NO;
    readyButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    readyButton.backgroundColor = [UIColor colorWithRed:0.0 green:.2 blue:1.0 alpha:.4];
    [readyButton addTarget:self
                    action:@selector(dismiss:)
          forControlEvents:UIControlEventTouchUpInside];
    [sv addSubview:readyButton];
    
    
    [self.view insertSubview:sv atIndex:0];

    
    
    // Do any additional setup after loading the view from its nib.
}



- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    self.pageControl.currentPage = (NSInteger)(targetContentOffset->x / [UIScreen mainScreen].bounds.size.width);
    if (self.pageControl.currentPage == (NUM_PAGES - 1)) {
        self.view.backgroundColor = [UIColor lightGrayColor];
        self.tutorialHeaderLabel.hidden = YES;
    }
    else {
        self.view.backgroundColor = [UIColor blackColor];
        self.tutorialHeaderLabel.hidden = NO;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)pageControlChanged:(id)sender
{
    
}

- (IBAction)dismiss:(id)sender
{
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [self.presentingViewController.presentingViewController dismissViewControllerAnimated:NO completion:NULL];
}

@end
