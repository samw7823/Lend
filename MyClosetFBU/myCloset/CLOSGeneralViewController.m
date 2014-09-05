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
    
    // set height/width info
    float height = 140.0;
    float imageWidth = 75.0;
    float screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    // make scroll view
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    sv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
    sv.scrollEnabled = YES;
    sv.contentSize = CGSizeMake(screenWidth, 7 * height);
    [sv addSubview:self.view];
    self.view = sv;
    
    for (int i = 0; i < 7; i++) {
        // make the text views
        UITextView *textview = [[UITextView alloc] initWithFrame:CGRectMake(0, i * height, screenWidth, height)];
        textview.backgroundColor = [UIColor colorWithWhite:.33 alpha:.5];
        textview.textColor = [UIColor whiteColor];
        textview.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0];
        textview.layer.borderColor = [[UIColor blackColor] CGColor];
        textview.layer.borderWidth = 1.0;
        
        
        // disable interaction
        textview.editable = NO;
        textview.userInteractionEnabled = NO;

        if (i != 6) { // not for background image
            textview.textContainerInset = UIEdgeInsetsMake(0, imageWidth, 0, 0);
            // make image view
            UIImageView *imageview = [[UIImageView alloc] initWithFrame:CGRectMake(0, (height - imageWidth) / 2.0, imageWidth, imageWidth)];
            
            // add image as a subview and set the text
            switch (i) {
                case 0:
                    textview.text = @"Bedroom closet doors, by Alex Ford, available at https://www.flickr.com/photos/alex_ford/8465476077 under the license: https://creativecommons.org/licenses/by-nc-nd/2.0/legalcode";
                    imageview.image = [UIImage imageNamed:@"closetDoor[0].jpg"];
                    break;
                case 1:
                    textview.text = @"Garage, by Catherine, available at  https://www.flickr.com/photos/katphotos/2512122314 under the license: https://creativecommons.org/licenses/by-nc-nd/2.0/";
                    imageview.image = [UIImage imageNamed:@"closetDoor[1].jpg"];
                    break;
                case 2:
                    textview.text = @"A new foray for us, by French Finds, available at https://www.flickr.com/photos/frenchfinds/8119279649 under the license: https://creativecommons.org/licenses/by/2.0/legalcode";
                    imageview.image = [UIImage imageNamed:@"closetDoor[2].jpg"];
                    break;
                case 3:
                    textview.text = @"Garage deuren, by Roel Wijnants, available at https://www.flickr.com/photos/roel1943/8706141674 under the license: https://creativecommons.org/licenses/by-nc/2.0/";
                    imageview.image = [UIImage imageNamed:@"closetDoor[3].jpg"];
                    break;
                case 4:
                    textview.text = @"Tall Dovetail Dresser, by Didriks, available at https://www.flickr.com/photos/dinnerseries/12840581763 under the license: https://creativecommons.org/licenses/by/2.0/legalcode";
                    imageview.image = [UIImage imageNamed:@"closetDoor[4].jpg"];
                    break;
                case 5:
                    textview.text = @"untitled, by benben, available at https://www.flickr.com/photos/nebneb/137242126 under the license: https://creativecommons.org/licenses/by-nc-sa/2.0/legalcode";
                    imageview.image = [UIImage imageNamed:@"closetDoor[5].jpg"];
                    break;
                default: // shouldn't go in here ever
                    break;
            }
            [textview addSubview:imageview];
        }
        else { // background image
            textview.text = @"Wood Background image:\nGOVGRID WOOD BROWN 3, by Gallery Administrator, available at http://govgrid.org/gallery3/index.php/Wood/GOVGRID-WOOD-BROWN-3 under the license: http://creativecommons.org/licenses/by-sa/3.0/legalcode";
        }
        
        [self.view addSubview:textview];
    }
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
