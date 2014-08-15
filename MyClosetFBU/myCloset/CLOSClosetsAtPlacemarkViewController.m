//
//  CLOSClosetsAtPlacemarkViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/25/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSClosetsAtPlacemarkViewController.h"
#import "CLOSIndividualClosetViewController.h"
#import <Parse/Parse.h>

@interface CLOSClosetsAtPlacemarkViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *owners;
@property (strong, nonatomic) NSMutableArray  *closetsToShowPrivacyChecked;
@property (nonatomic, strong) UILabel *sliderLabel;
@property (nonatomic, strong) UISlider *rangeSlider;
@property (nonatomic, strong) UIView *headerView;
@property (atomic) int counter;


typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@end

@implementation CLOSClosetsAtPlacemarkViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSIndividualClosetViewController *individualvc = [[CLOSIndividualClosetViewController alloc] init];
    individualvc.closet = self.closetsToShow[indexPath.row];
    PFObject *closet = self.closetsToShow[indexPath.row];
    PFRelation *ownerRelation = [closet relationForKey:@"owner"];
    PFQuery *query = [ownerRelation query];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *owner, NSError *error) {
        individualvc.user = (PFUser *)owner;
        [self.navigationController pushViewController:individualvc animated:YES];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue a cell and set its text as the name of a closet
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCellWithStyle"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"UITableViewCellWithStyle"];
    }
    
    PFObject *closet = self.closetsToShow[indexPath.row];
    cell.textLabel.text = closet[@"name"];
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    
    if ([self.navigationItem.title isEqualToString:@"Closets Nearby"]) { // in closets nearby, so display location of closet
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        NSArray *locationStrings = closet[@"FormattedAddressLines"];
        if (locationStrings)
            cell.detailTextLabel.text = locationStrings[0];
    }
    
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // number of closets at that placemark
    return [self.closetsToShow count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.navigationItem.title isEqualToString:@"Closets Nearby"]) {
        return 80;
    }
    else {
        return 60;
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.navigationItem.title isEqualToString:@"Closets Nearby"]) {
        self.headerView.backgroundColor = [UIColor colorWithWhite:.33 alpha:.5];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, self.headerView.frame.size.width, self.headerView.frame.size.height / 2.0)];
        label.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0];
        label.textColor = [UIColor whiteColor];
        label.text = @"closets within...";
        
        self.sliderLabel.text = [NSString stringWithFormat:@"%d miles", (int)self.rangeSlider.value];
        self.sliderLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0];
        self.sliderLabel.textColor = [UIColor whiteColor];
        
        // add button as subview
        [self.headerView addSubview:label];
    }
    
    return self.headerView;
}

- (void) changeRadius: (id) sender
{
    self.rangeSlider.enabled = NO;
    UISlider *slider = (UISlider *)sender;
    int progressAsInt = (int)roundf(slider.value);
    self.sliderLabel.text = [NSString stringWithFormat:@"%d miles", progressAsInt];
    [self didChangeRadius:slider];
}

- (void) didChangeRadius: (id) sender
{
    
    [self.closetsToShow removeAllObjects];
    [self.tableView reloadData];
    UISlider *slider = (UISlider *)sender;
    PFQuery *closetsNearbyQuery = [PFQuery queryWithClassName:@"Closet"];
    NSNumber *closetsNearbyRange = [NSNumber numberWithFloat:slider.value];
    [closetsNearbyQuery whereKey:@"geopoint" nearGeoPoint:[PFGeoPoint geoPointWithLocation:self.placemark.location] withinMiles:[closetsNearbyRange intValue]];
    [closetsNearbyQuery whereKey:@"owner" notEqualTo:[PFUser currentUser]];
    [closetsNearbyQuery whereKey:@"isPrivate" equalTo:@NO];
    [closetsNearbyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.closetsToShow = objects.mutableCopy;
        [self checkPrivacyAndReload];
    }];
}

- (void) checkPrivacyAndReload
{
    // deal with privacy
    
    // set the counter
    self.counter =  (int)[self.closetsToShow count];
    
    self.closetsToShowPrivacyChecked = [self.closetsToShow mutableCopy];
    [self.closetsToShow removeAllObjects];
    
    for (PFObject *closet in self.closetsToShowPrivacyChecked) {// for each closet, check if the owner has a private account. if not, show the closet. if yes, check if current user is following the owner
        PFRelation *ownerRelation = [closet relationForKey:@"owner"];
        PFQuery *ownerQuery = [ownerRelation query];
        [ownerQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            PFUser *owner = [objects firstObject];
            if ([owner[@"isPrivate"] isEqual:@YES]) { // account is private, so query for a follow object between the two users
                PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
                [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
                [followQuery whereKey:@"to" equalTo:owner];
                [followQuery whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:approved]];
                [followQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if ([objects count] != 0) { // user is following the owner -- show the closet
                        [self.closetsToShow addObject:closet];
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:([self.closetsToShow count] - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                    }
                    self.counter--; // finished checking another closet
                    if (self.counter == 0) // all done, all closets inserted, re-enabled the slider
                        self.rangeSlider.enabled = YES;
                }];
            }
            else { // account isn't private, so show the closet
                [self.closetsToShow addObject:closet];
                [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:([self.closetsToShow count] - 1) inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                self.counter--; // finished checking another closet
                if (self.counter == 0) // all done, all closets inserted, re-enabled the slider
                    self.rangeSlider.enabled = YES;
            }
        }];
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set up table view
    self.automaticallyAdjustsScrollViewInsets = NO;
    //[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    if ([self.navigationItem.title isEqualToString:@"Closets Nearby"]) {
        // deal with privacy
        [self checkPrivacyAndReload];
        
        // initialize view for header
        self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, [UIScreen mainScreen].bounds.size.width, 80)];
        
        // initialize range slider and label
        
        // initialize range slider
        self.rangeSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, self.headerView.frame.size.height / 2.0 - 8, self.headerView.frame.size.width / 2.0 + 65, self.headerView.frame.size.height / 2.0)];
        
        // set min and max value + current value
        self.rangeSlider.minimumValue = 0.0;
        self.rangeSlider.maximumValue = 30.0;
        if (!self.rangeSlider.value)
            self.rangeSlider.value = [[PFUser currentUser][@"closetsNearbyRange"] intValue];
        
        // set action to change the label and reload page when slider is moved
        [self.rangeSlider addTarget:self
                             action:@selector(changeRadius:)
                   forControlEvents:UIControlEventTouchUpInside];
        self.sliderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.headerView.frame.size.width / 2.0 + 85, self.headerView.frame.size.height / 2.0 - 8, self.headerView.frame.size.width / 2.0, self.headerView.frame.size.height / 2.0)];
        
        // add slider and it's label to the header view
        [self.headerView addSubview:self.rangeSlider];
        [self.headerView addSubview:self.sliderLabel];
    }
    else { // from map view
        // set up label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, [UIScreen mainScreen].bounds.size.width - 8, 60)];
        label.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0];
        label.textColor = [UIColor whiteColor];
        label.text = [NSString stringWithFormat:@"    %@",self.placemarkTitle];
        label.adjustsFontSizeToFitWidth = YES;
        // set the label as the header view
        self.headerView = (UIView *) label;
        self.headerView.backgroundColor = [UIColor colorWithWhite:.33 alpha:.5];
    }
    

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // disable the slider until first table view loads
    self.rangeSlider.enabled = NO;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
