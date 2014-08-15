//
//  CLOSPrivacySettingsViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/22/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSPrivacySettingsViewController.h"
#import <Parse/Parse.h>
#import "CLOSEditClosetLocationViewController.h"

@interface CLOSPrivacySettingsViewController ()
@property (weak, nonatomic) IBOutlet UISwitch *isPrivateSwitch;
@property (strong, nonatomic) PFUser *currentUser;
@property (nonatomic) BOOL oldPrivacy;
@property (weak, nonatomic) IBOutlet UISlider *closetsNearbySlider;
@property (strong, nonatomic) NSNumber *oldClosetsNearbyRange;
@property (weak, nonatomic) IBOutlet UILabel *sliderLabel;
@property (weak, nonatomic) IBOutlet UIButton *editLocationsButton;

typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@end

@implementation CLOSPrivacySettingsViewController

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
    // set up buttons
    self.editLocationsButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.editLocationsButton.layer.cornerRadius = 8.0f;
    
    // set up slider
    self.closetsNearbySlider.minimumValue = 0.0;
    self.closetsNearbySlider.maximumValue = 30.0;
    
    // get the current user and current privacy setting, current closetsNearbyRange
    self.currentUser = [PFUser currentUser];
    if ([self.currentUser[@"isPrivate"] isEqual:@YES])
        self.oldPrivacy = TRUE;
    else
        self.oldPrivacy = FALSE;
    self.isPrivateSwitch.on = self.oldPrivacy;
    
    self.oldClosetsNearbyRange = self.currentUser[@"closetsNearbyRange"];
    if (self.oldClosetsNearbyRange)
        self.closetsNearbySlider.value = [self.oldClosetsNearbyRange intValue];
    else
        self.closetsNearbySlider.value = 0.0;
    self.sliderLabel.text = [NSString stringWithFormat:@"%d miles", (int)self.closetsNearbySlider.value];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"save settings" style:UIBarButtonItemStylePlain target:self action:@selector(save:)];

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // make sure interaction enabled
    self.view.userInteractionEnabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)slider:(id)sender{
    UISlider *slider = (UISlider *)sender;
    int progressAsInt = (int)roundf(slider.value);
    self.sliderLabel.text = [NSString stringWithFormat:@"%d miles", progressAsInt];
}
- (IBAction)editLocation:(id)sender
{
    self.view.userInteractionEnabled = NO;
    CLOSEditClosetLocationViewController *editvc = [[CLOSEditClosetLocationViewController alloc] init];
    [self.navigationController pushViewController:editvc animated:YES];
}

- (IBAction)save:(id)sender
{
    // don't allow double clicking
    self.view.userInteractionEnabled = NO;
    
    BOOL needsUpdate = NO;
    
    BOOL isPrivate = self.isPrivateSwitch.on;

    // if the user here has changed their privacy preference, update the user's account
    if (isPrivate != self.oldPrivacy) {
        self.currentUser[@"isPrivate"] = isPrivate ? @YES : @NO;
        if (!isPrivate) { // going from private to public, so update all follow requests to be accepted
            PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
            [followQuery whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:requested]];
            [followQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                for (PFObject *object in objects) {
                    object[@"verificationState"] = [NSNumber numberWithInteger:approved];
                    [object saveInBackground];
                }
            }];
        }
        if (isPrivate == true)
            [self.currentUser incrementKey:@"weightedActivity" byAmount:@-1000];
        else
            [self.currentUser incrementKey:@"weightedActivity" byAmount:@1000];
        needsUpdate = YES;

    }
    if (self.closetsNearbySlider.value != [self.oldClosetsNearbyRange floatValue]) {
        self.currentUser[@"closetsNearbyRange"] = [NSNumber numberWithInt:(int)self.closetsNearbySlider.value];
        needsUpdate = YES;
    }
    
    if (needsUpdate)
        [self.currentUser saveInBackground];
    
    // go back to settings
    [self.navigationController popViewControllerAnimated:YES];
}

@end
