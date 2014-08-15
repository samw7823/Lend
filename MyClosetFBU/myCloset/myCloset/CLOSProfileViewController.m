//
//  CLOSProfileViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSProfileViewController.h"

#import <MapKit/MapKit.h>

#import <FacebookSDK/FacebookSDK.h>

#import <Parse/Parse.h>

#import "CLOSClosetCell.h"
#import "CLOSClosetsAtPlacemarkViewController.h"
#import "CLOSCreateClosetViewController.h"
#import "CLOSCreateGroupViewController.h"
#import "CLOSFriendListViewController.h"
#import "CLOSGroupProfileViewController.h"
#import "CLOSIndividualClosetViewController.h"
#import "CLOSMapViewController.h"
#import "CLOSReportAUserViewController.h"
#import "CLOSSettingsViewController.h"
#import "CLOSSignUpDetailViewController.h"
#import "Reachability.h"
#import "CLOSScreenshotsViewController.h"

@interface CLOSProfileViewController () <UICollectionViewDelegate, UICollectionViewDataSource, CLLocationManagerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSURLConnectionDataDelegate, UIScrollViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *isFollowingButton;
@property (weak, nonatomic) IBOutlet UIButton *unfollowButton;
@property (weak, nonatomic) IBOutlet UIButton *pendingButton;
@property (weak, nonatomic) IBOutlet UILabel *hasNoPublicClosetsLabel;
@property (weak, nonatomic) IBOutlet UIButton *seeFollowingButton;
@property (weak, nonatomic) IBOutlet UIButton *seeFollowersButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIButton *addClosetTutorialButton;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UIImageView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (strong, nonatomic) NSTimer *flashTimer;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableData *imageData;
@property (strong, nonatomic) UIActivityIndicatorView *loadingIndicator;
@property (strong, nonatomic) UITableView *groupListTableView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, copy) NSArray *myGroups;

@property (nonatomic, assign) NSInteger numberOfClosets;
@property (nonatomic, strong) UIBezierPath *arrow;

@property (nonatomic) BOOL isFollowing;
@property (nonatomic, assign) BOOL shouldBePrivateToCurrentUser;
@property (nonatomic, assign) BOOL endOfQuerying;

@property (nonatomic) Reachability *hostReachability;
@property (nonatomic) Reachability *internetReachability;
@property (nonatomic) Reachability *wifiReachability;
@property (nonatomic) UILabel *noInternetLabel;

typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

typedef NS_ENUM(NSInteger, tutorialStates) {
    noClosets = 0,
    madeCloset = 1,
    viewedCloset = 2,
    madeItem = 3,
    sawMap = 4,
    sawClosetsNearby = 5,
    sawGroups = 6,
    done = 7
};
@end

@implementation CLOSProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _numberOfClosets = -1;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self checkReachability];
    if ([UIScreen mainScreen].bounds.size.height != 568) { // not 4 inch
        float screenSizeDifference = 568 - [UIScreen mainScreen].bounds.size.height;
        self.scrollView.frame = CGRectMake(self.scrollView.frame.origin.x, self.scrollView.frame.origin.y + screenSizeDifference, self.scrollView.frame.size.width, self.scrollView.frame.size.height - screenSizeDifference);
        self.toolbar.frame = CGRectMake(self.toolbar.frame.origin.x, self.toolbar.frame.origin.y + screenSizeDifference, self.toolbar.frame.size.width, self.toolbar.frame.size.height);
        
    }
    
    // loading indicator initialization
    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    CGRect frame = [self.collectionView frame];
    self.loadingIndicator.center = CGPointMake(frame.size.width / 2.0, self.toolbar.frame.origin.y + (self.toolbar.frame.size.height / 2.0) +(frame.size.height / 2.0));
    self.loadingIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.loadingIndicator];
    
    /* NEW USER TUTORIAL */
    //set up tutorial
    self.addClosetTutorialButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.addClosetTutorialButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    //   self.arrowImageView.image = [UIImage imageNamed:@"arrowCircle.png"];
    //   self.arrowImageView.tintColor = [UIColor whiteColor];
    
    // hide tutorial
    self.addClosetTutorialButton.hidden = YES;
   // self.addClosetTutorialButton.layer.borderColor = [[UIColor colorWithRed:26.0f/255.0f green:0.0f/255.0f blue:59.0f/255.0f alpha:.7] CGColor];
    //self.addClosetTutorialButton.layer.borderWidth = 3.0;
    //self.addClosetTutorialButton.layer.shado
    self.arrowImageView.hidden = YES;
    
    /* END NEW USER TUTORIAL */
    
    // make buttons rounded
    self.isFollowingButton.layer.cornerRadius = 8.0f;
    self.seeFollowersButton.layer.cornerRadius = 8.0f;
    self.seeFollowingButton.layer.cornerRadius = 8.0f;
    self.unfollowButton.layer.cornerRadius = 8.0f;
    self.pendingButton.layer.cornerRadius = 8.0f;
    
    // set font
    self.isFollowingButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0];
    self.unfollowButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0];
    self.seeFollowersButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.seeFollowingButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    
    // set font and color and size for navigation bar
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0]}];
    for (UIBarButtonItem *b in self.toolbar.items) {
        [b setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0]} forState:UIControlStateNormal];
        if ([b.title isEqualToString:@"|"])
            b.enabled = NO;
        else if ([b.title isEqualToString:@"Closets Nearby"])
            b.enabled = YES;
    }
    //set all bar button items to have same font and size
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0]} forState:UIControlStateNormal];
    
    // self.collectionView.backgroundColor = [UIColor colorWithWhite:.2 alpha:.5];
    
    // self.view.backgroundColor = [UIColor colorWithWhite:.2 alpha:.5];
    
    self.automaticallyAdjustsScrollViewInsets = NO; // delete header space in collection view
    
    // set up collection view cells and collection view
    UINib *cellNib = [UINib nibWithNibName:@"CLOSClosetCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ClosetCell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(150, 150)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    // if this page has been launched by a class that didn't provide a user, the current user's items should be displayed
    if (!self.user) { // set up page to show current user's profile
        self.user = [PFUser currentUser];

        // set up scroll view and table view to see groups
        self.groupListTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.collectionView.frame.origin.x + self.collectionView.frame.size.width, self.collectionView.frame.origin.y, self.collectionView.frame.size.width, self.collectionView.frame.size.height)];
        self.groupListTableView.dataSource = self;
        self.groupListTableView.delegate = self;

        [self.groupListTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
        self.groupListTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        self.groupListTableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];

        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * 2, self.scrollView.frame.size.height);
        self.scrollView.delegate = self;
        [self.scrollView addSubview:self.groupListTableView];

        // set up page to show current user's profile
        UIBarButtonItem *moreButton = [[UIBarButtonItem alloc] initWithTitle:@"More" style:UIBarButtonItemStyleBordered target:self action:@selector(settings:)];
        self.navigationItem.rightBarButtonItem = moreButton;

    }
    
    if ([self.internetReachability currentReachabilityStatus] != NotReachable) {

        //Set profile picture
        PFFile *profilePicture = self.user[@"profilePicture"];
        [profilePicture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            UIImage *image = [UIImage imageWithData:data];
            self.profileView.image = image;
        }];
    }
    self.usernameLabel.text = self.user.username;
    self.usernameLabel.adjustsFontSizeToFitWidth = YES;
    
    
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager startUpdatingLocation];
        [self.locationManager stopUpdatingLocation];
    }

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.userInteractionEnabled = YES;
    
    // make sure nothing is flashing
    if (self.flashTimer) {
        [self.flashTimer invalidate];
        self.flashTimer = nil;
    }
    self.endOfQuerying = NO;
    NetworkStatus netStatus = [self.internetReachability currentReachabilityStatus];
    if (netStatus != NotReachable) {
        [self loadPage];
        if ([[PFUser currentUser].username isEqualToString:self.user.username])
            [self loadGroups];
    }

}

- (void) scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if ([self.scrollView isEqual:scrollView]) { // only if scrolling horizontally from scroll view. not scrolling through collection view or table view
        // check if needs to see groups
        if ([self.user[@"tutorialStage"] isEqual:@(sawClosetsNearby)]) {
            self.user[@"tutorialStage"] = @(sawGroups);
            [self.user saveInBackground];
            [self enterTutorial];
        }
        else if ([self.user[@"tutorialStage"] isEqual:@(noClosets)]) { // if needs to add a closet, reverse whether the tutorial is hidden. (when going to groups, hide it. when going to closets, show it)
            self.addClosetTutorialButton.hidden = !self.addClosetTutorialButton.hidden;
        }
        
        UIBarButtonItem *addButton = [self.toolbar.items lastObject];
        addButton.tintColor = [UIColor whiteColor];
        
        if (targetContentOffset->x == 0.0) {// prepare to show closets
            self.navigationItem.title = @"my closets";
            [addButton setTitle:@"Add Closet"];
        }
        else {
            self.navigationItem.title = @"my groups";
            [addButton setTitle:@"Add Group"];
        }
    }
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return number of groups user is in
    return [self.myGroups count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue a cell and make background clear
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];

    // set the cell to show the group name
    cell.textLabel.text = self.myGroups[indexPath.row][@"name"];
    cell.textLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    cell.textLabel.textColor = [UIColor whiteColor];

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // launch the group profile view controller after setting its group property to be the group selected
        PFObject *group = self.myGroups[indexPath.row];
        CLOSGroupProfileViewController *groupProfvc = [[CLOSGroupProfileViewController alloc] init];
        groupProfvc.group = group;
        [self.navigationController pushViewController:groupProfvc animated:YES];

}

- (void) loadGroups
{
    // query to get user's groups
    PFQuery *groupQuery = [PFQuery queryWithClassName:@"Group"];
    [groupQuery whereKey:@"members" equalTo:[PFUser currentUser]];
    [groupQuery orderByDescending:@"createdAt"];//show most recent first
    [groupQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.myGroups = objects;
            [self.groupListTableView reloadData];
        }
    }];
}
    
- (void) loadPage
{

    // start activity indicator
    [self.loadingIndicator startAnimating];
    
    // moving this to viewWillAppear because of threading problem where the follow relation between current user and private profile was found after self.myClosets was being loaded and set to nil for there being no follow object even when there was one
    NSString *username;
    if ([self.user.username isEqualToString:[PFUser currentUser].username]) { // set up page to show current user's profile
        if (self.user[@"tutorialStage"] == nil) {
            self.user[@"tutorialStage"] = [NSNumber numberWithInteger:noClosets];
            [self.user saveInBackground];
        }

        // show either add group or add closet and either my closets or my groups
        UIBarButtonItem *addButton = [self.toolbar.items lastObject];
        if (self.scrollView.contentOffset.x == 0.0) {
            username = @"my closets";
            addButton.title = @"Add Closet";
        }
        else {
            username = @"my groups";
            addButton.title = @"Add Group";
        }
        self.isFollowingButton.hidden = YES;
        self.unfollowButton.hidden = YES;
        self.pendingButton.hidden = YES;
        self.isFollowing = YES; // make sure user can see all of his or her closets
        self.shouldBePrivateToCurrentUser = NO; // make sure user can see all of his or her closets
        self.endOfQuerying = NO;
        // self.settings.hidden = NO;
        [self.hasNoPublicClosetsLabel setText:@"you have no closets"];
        
//        //have an add closet button only for current user
//        UIImage *gearImage = [UIImage imageNamed:@"gear.png"];
//        UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:gearImage style:UIBarButtonItemStyleBordered target:self action:@selector(settings:)];
//
//        self.navigationItem.rightBarButtonItem = settingsButton;
//
        //Add tap gesture to profile view to show action sheet to change it
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileViewTapped)];
        [self.profileView addGestureRecognizer:tapGestureRecognizer];
        
        // get the current user's closets
        PFRelation *relation = [self.user relationForKey:@"ownedClosets"];
        PFQuery *query = [relation query];
        if (self.numberOfClosets < 20) {
            query.limit = 20;
        } else {
            query.limit = self.numberOfClosets + 1;
        }
        [query orderByDescending:@"createdAt"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [self.loadingIndicator stopAnimating];
            if (error) {
                // clear out closets shown before if can't reach parse
                self.myClosets = nil;
                self.numberOfClosets = -1;
                [self.collectionView reloadData];
                UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                    message:@"Cannot reach the internet. Please check your internet connection before loading the app again."
                                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [failAlert show];
                [self.hasNoPublicClosetsLabel setText:@"no internet"];
                self.hasNoPublicClosetsLabel.hidden = NO;
            }
            else {
                self.myClosets = objects.mutableCopy;
                if ([self.myClosets count] == 0) {// if current user has no closets show the label
                    self.hasNoPublicClosetsLabel.hidden = NO;
                }
                self.numberOfClosets = self.myClosets.count;
                [self.collectionView reloadData];

                // do tutorial stuff
                if ([self.myClosets count] != 0 && [self.user[@"tutorialStage"] isEqual:@(noClosets)]) { // need to increase tutorial stage
                    self.user[@"tutorialStage"] = @(madeCloset);
                    [self.user saveInBackground];
                }
                NSInteger pastDone = done + 1;
                if ([self.user[@"tutorialStage"] compare:@(pastDone)] == NSOrderedAscending)
                    [self enterTutorial];
            }
        }];
        

    }
    else { // current user viewing another user's page
        // set up toolbar accordingly
        NSUInteger length = [self.toolbar.items count];
        for (int i = 1; i < length; i++) {
            UIBarButtonItem *button = self.toolbar.items[i];
            button.title = @"";
            button.enabled = NO;
        }
        
        UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleBordered target:self action:@selector(options:)];
        [optionsButton setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
                                                NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:21.0]}
                                     forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem = optionsButton;
        
        username = [NSString stringWithFormat:@"%@'s closets",self.user.username];
        [self.hasNoPublicClosetsLabel setText:@"this user has no public closets"];
        //Check if already following this user
        PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
        [query whereKey:@"from" equalTo:[PFUser currentUser]];
        [query whereKey:@"to" equalTo:self.user];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            [self.loadingIndicator stopAnimating];
            if (error) {
                // clear out closets shown before if can't reach parse
                self.myClosets = nil;
                self.numberOfClosets = -1;
                [self.collectionView reloadData];
                UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                    message:@"Cannot reach the internet. Please check your internet connection before loading the app again."
                                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [failAlert show];
                [self.hasNoPublicClosetsLabel setText:@"no internet"];
                self.hasNoPublicClosetsLabel.hidden = NO;
            }
            else if ([objects count] != 0) { // follow object found
                self.isFollowingButton.hidden = YES;
                PFObject *follow = [objects lastObject];
                if ([follow[@"verificationState"] isEqual:[NSNumber numberWithInteger:approved]]) { // following
                    self.isFollowing = YES;
                    self.shouldBePrivateToCurrentUser = NO;
                    self.pendingButton.hidden = YES;
                    self.unfollowButton.hidden = NO;
                    
                    // get all closets to display and put them into self.myClosets
                    PFRelation *relation = [self.user relationForKey:@"ownedClosets"];
                    PFQuery *query = [relation query];
                    if (self.numberOfClosets < 20) {
                        query.limit = 20;
                    } else {
                        query.limit = self.numberOfClosets;
                    }
                    [query whereKey:@"isPrivate" notEqualTo:@YES]; // don't get any private closets
                    [query orderByDescending:@"createdAt"];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        self.myClosets = objects.mutableCopy;
                        if ([self.myClosets count] == 0) {// if a user has no public closets or current user has no closets show the label
                            self.hasNoPublicClosetsLabel.hidden = NO;
                        }
                        self.numberOfClosets = self.myClosets.count;
                        [self.collectionView reloadData];
                    }];
                }
                else if ([follow[@"verificationState"] isEqual:[NSNumber numberWithInteger:requested]]) { // pending request
                    self.isFollowing = NO;
                    self.shouldBePrivateToCurrentUser = YES;
                    self.pendingButton.hidden = NO;
                    self.unfollowButton.hidden = YES;

                    // deal with privacy
                    if ([self.user[@"isPrivate"] isEqual:@YES]) { // this should always be true if it is a pending request. no closets should be shown
                        self.myClosets = nil;
                        self.numberOfClosets = -1;
                        self.hasNoPublicClosetsLabel.hidden = NO;
                        [self.collectionView reloadData];
                    }
                }
            }
            else { // no follow object found
                self.isFollowingButton.hidden = NO;
                self.unfollowButton.hidden = YES;
                self.pendingButton.hidden = YES;
                self.isFollowing = NO;
                
                // check if private account
                if ([self.user[@"isPrivate"] isEqual:@YES]) { // not following so show nothing
                    self.myClosets = nil;
                    self.numberOfClosets = -1;
                    self.hasNoPublicClosetsLabel.hidden = NO;
                    [self.collectionView reloadData];
                }
                else { // user not private, so show public closets
                    PFRelation *relation = [self.user relationForKey:@"ownedClosets"];
                    PFQuery *query = [relation query];
                    if (self.numberOfClosets < 20) {
                        query.limit = 20;
                    } else {
                        query.limit = self.numberOfClosets;
                    }
                    [query whereKey:@"isPrivate" notEqualTo:@YES]; // don't get any private closets
                    [query orderByDescending:@"createdAt"];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        self.myClosets = objects.mutableCopy;
                        if ([self.myClosets count] == 0) {// if a user has no public closets
                            self.hasNoPublicClosetsLabel.hidden = NO;
                        }
                        self.numberOfClosets = self.myClosets.count;
                        [self.collectionView reloadData];
                    }];
                }
                
            }
        }];
        
    }
    self.navigationItem.title = username;
    
    self.hasNoPublicClosetsLabel.hidden = YES;
    
    PFFile *profilePicture = self.user[@"profilePicture"];
    [profilePicture getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        self.profileView.image = image;
    }];
    
    // make sure interaction is enabled every time view is going to appear
    self.view.userInteractionEnabled = YES;
    
}

- (void) enterTutorial
{
    // make sure nothing is flashing -- fixing problem when user clicks closets nearby and location services are off and closets nearby continues to flash
    if (self.flashTimer) {
        [self.flashTimer invalidate];
        self.flashTimer = nil;
    }
    if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:noClosets]]) { // need to make a closet
        [self.addClosetTutorialButton setTitle:@"Welcome!\nTo get started,\nlet's add a closet" forState:UIControlStateNormal];
        // show the label and arrow
        self.addClosetTutorialButton.hidden = NO;


        //self.arrowImageView.hidden = NO;
        // highlight the add closet button
        if (!self.flashTimer) {
            self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:.8
                                                               target:self
                                                             selector:@selector(flashAddButton)
                                                             userInfo:nil
                                                              repeats:YES];
        }
    }
    else if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:madeCloset]]) { // need to view the closet and make an item
        // make sure add closet is white
        UIBarButtonItem *addCloset = [self.toolbar.items lastObject];
        addCloset.tintColor = [UIColor whiteColor];
        
        
        [self.addClosetTutorialButton setTitle:@"Now let's look at the closet!" forState:UIControlStateNormal];
        self.addClosetTutorialButton.hidden = NO;
        
        
        // highlight the first closet in the collection view
        if (!self.flashTimer) {
            self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:.8
                                                               target:self
                                                             selector:@selector(flashCell)
                                                             userInfo:nil
                                                              repeats:YES];
        }
    }
    // madeCloset stage is dealt with in individual closet view controller. can't progress until item is made
    else if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:madeItem]]) { // need to see the map
        // make sure cell's alpha is reset
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        cell.alpha = 1.0;
        
        // move the tutorial text and highlight see map
        [self.addClosetTutorialButton setTitle:@"See where your closets are located!" forState:UIControlStateNormal];
        self.addClosetTutorialButton.hidden = NO;
        [self.addClosetTutorialButton setFrame:CGRectMake(self.toolbar.frame.origin.x, self.toolbar.frame.origin.y + 30,self.addClosetTutorialButton.frame.size.width, self.addClosetTutorialButton.frame.size.height)];
        if (!self.flashTimer) {
            self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:.8
                                                               target:self
                                                             selector:@selector(flashMapButton)
                                                             userInfo:nil
                                                              repeats:YES];
        }
        
    }
    else if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:sawMap]]) { // need to see nearby closets
        // make sure see map is white
        UIBarButtonItem *seeMap = [self.toolbar.items firstObject];
        seeMap.tintColor = [UIColor whiteColor];
        
        // move the tutorial text and highlight nearby closets
        [self.addClosetTutorialButton setTitle:@"See nearby closets! (you can change the range in your settings)" forState:UIControlStateNormal];
        self.addClosetTutorialButton.hidden = NO;
        [self.addClosetTutorialButton setFrame:CGRectMake(self.toolbar.frame.origin.x + (self.toolbar.frame.size.width/2.0) - (self.addClosetTutorialButton.frame.size.width / 2.0), self.toolbar.frame.origin.y + 30,self.addClosetTutorialButton.frame.size.width, self.addClosetTutorialButton.frame.size.height)];
        if (!self.flashTimer) {
            self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:.8
                                                               target:self
                                                             selector:@selector(flashClosetsNearbyButton)
                                                             userInfo:nil
                                                              repeats:YES];
        }
        
    }
    else if ([self.user[@"tutorialStage"] isEqual:@(sawClosetsNearby)]) { // need to see groups
        // make sure closets nearby is white
        UIBarButtonItem *closetsNearby = self.toolbar.items[2];
        closetsNearby.tintColor = [UIColor whiteColor];
        
        // move the tutorial text and highlight settings
        [self.addClosetTutorialButton setTitle:@"<----- Swipe left to see your groups ------" forState:UIControlStateNormal];
        [self.addClosetTutorialButton setFrame:self.scrollView.frame];
        self.addClosetTutorialButton.userInteractionEnabled = NO;
        self.addClosetTutorialButton.hidden = NO;


    }
    else if ([self.user[@"tutorialStage"] isEqual:@(sawGroups)]) { // need to go to settings
        // move the tutorial text and highlight settings
        [self.addClosetTutorialButton setTitle:@"Now explore your settings! Find friends, see items you've borrowed, choose your preferences" forState:UIControlStateNormal];
        [self.addClosetTutorialButton setBounds:CGRectMake(0, 0, 209, 135)];
        self.addClosetTutorialButton.frame = CGRectMake(self.navigationController.navigationBar.frame.size.width - self.addClosetTutorialButton.frame.size.width, self.navigationController.navigationBar.frame.size.height + 15, self.addClosetTutorialButton.bounds.size.width, self.addClosetTutorialButton.bounds.size.height);
        self.addClosetTutorialButton.hidden = NO;
        if (!self.flashTimer) {
            self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:.8
                                                               target:self
                                                             selector:@selector(flashSettingsButton)
                                                             userInfo:nil
                                                              repeats:YES];
        }

    }
    else { // all done
        // make sure settings is white
        UIBarButtonItem *settings = self.navigationItem.rightBarButtonItem;
        settings.tintColor = [UIColor whiteColor];
        
        self.addClosetTutorialButton.hidden = YES;
    }
}

- (void) flashSettingsButton
{
    // flash the settings button
    UIBarButtonItem *settings = self.navigationItem.rightBarButtonItem;
    if ([settings.tintColor isEqual:[UIColor whiteColor]])
        settings.tintColor = [UIColor lightGrayColor];
    else
        settings.tintColor = [UIColor whiteColor];
}

- (void) flashClosetsNearbyButton
{
    // flash the closets nearby button
    UIBarButtonItem *closetsNearby = self.toolbar.items[2];
    if ([closetsNearby.tintColor isEqual:[UIColor whiteColor]])
        closetsNearby.tintColor = [UIColor lightGrayColor];
    else
        closetsNearby.tintColor = [UIColor whiteColor];
}

- (void) flashMapButton
{
    // flash the see map button
    UIBarButtonItem *seeMap = [self.toolbar.items firstObject];
    if ([seeMap.tintColor isEqual:[UIColor whiteColor]])
        seeMap.tintColor = [UIColor lightGrayColor];
    else
        seeMap.tintColor = [UIColor whiteColor];
    
}

- (void) flashCell
{
    // flash the first cell in the collection view
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell.alpha == 1.0)
        cell.alpha = .5;
    else
        cell.alpha = 1.0;
}

- (void) flashAddButton
{
    // flash the add closets button
    UIBarButtonItem *addCloset = [self.toolbar.items lastObject];
    if ([addCloset.title isEqualToString:@"Add Closet"]) {
        if ([addCloset.tintColor isEqual:[UIColor whiteColor]])
            addCloset.tintColor = [UIColor lightGrayColor];
        else
            addCloset.tintColor = [UIColor whiteColor];
    }
}

- (IBAction)seeFollowing:(id)sender
{
    // don't allow user to click twice
    self.view.userInteractionEnabled = NO;
    // push friendsListViewController with boolean set such that it will display who the owner of the current profile page is following
    CLOSFriendListViewController *friendsvc = [[CLOSFriendListViewController alloc] init];
    friendsvc.user = self.user; // display this user's following list
    friendsvc.isFollowers = NO;
    [self.navigationController pushViewController:friendsvc animated:YES];
}

- (IBAction)seeFollowers:(id)sender
{
    // don't allow user to click twice
    self.view.userInteractionEnabled = NO;
    // push friendsListViewController with boolean set such that it will display the followers of the owner of the current profile page
    CLOSFriendListViewController *friendsvc = [[CLOSFriendListViewController alloc] init];
    friendsvc.user = self.user; // display this user's followers list
    friendsvc.isFollowers = YES;
    [self.navigationController pushViewController:friendsvc animated:YES];
}

- (IBAction)follow:(id)sender
{
    // create a new follow object in parse from the current user to the user whose profile is being shown
    PFUser *currentUser = [PFUser currentUser];
    PFObject *follow = [PFObject objectWithClassName:@"Follow"];
    [follow setObject:self.user forKey:@"to"];
    [follow setObject:currentUser forKey:@"from"];
    if ([self.user[@"isPrivate"]  isEqual: @YES]) {
        follow[@"verificationState"] = [NSNumber numberWithInteger:requested];
        self.isFollowingButton.hidden = YES;
        self.unfollowButton.hidden = YES;
        self.pendingButton.hidden = NO;
    }
    else {
        follow[@"verificationState"] = [NSNumber numberWithInteger:approved];
        self.isFollowingButton.hidden = YES;
        self.unfollowButton.hidden = NO;
        self.pendingButton.hidden = YES;
    }
    [follow saveInBackground];
    
    //Add push notification
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"username" equalTo:self.user.username];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    NSString *message;
    NSDictionary *data;
    if ([self.user[@"isPrivate"] isEqual:@YES]){
        message = [NSString stringWithFormat:@"%@ requested to follow you", currentUser.username];
        data = @{@"alert":message,@"isFollowRequest" : @"YES"};
    }
    else{
        message = [NSString stringWithFormat:@"%@ started following you", currentUser.username];
        data = @{@"alert":message, @"isFollowRequest" : @"NO"};
    }
    [push setData:data];
    [push sendPushInBackground];
    
}

- (IBAction)unfollow:(id)sender
{
    
    // delete the follow object from the current user to the user whose profile is being shown
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    
    [query whereKey:@"from" equalTo:[PFUser currentUser]];
    [query whereKey:@"to" equalTo:self.user];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if ([objects count] != 0) {
            PFObject *follow = objects[0];
            [follow deleteInBackground];
            self.unfollowButton.hidden = YES;
            self.isFollowingButton.hidden = NO;
            self.pendingButton.hidden = YES;
        }
        
    }];
}

- (IBAction)pending:(id)sender
{
    UIActionSheet *cancelRequestActionSheet = [[UIActionSheet alloc] initWithTitle:@"Cancel Friend Request?"
                                                                          delegate:self
                                                                 cancelButtonTitle:@"No"
                                                            destructiveButtonTitle:@"Yes, Cancel Request"
                                                                 otherButtonTitles:nil];
    cancelRequestActionSheet.tag = 123;
    cancelRequestActionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [cancelRequestActionSheet showFromTabBar:self.tabBarController.tabBar];
    
}

- (IBAction)addCloset:(id)sender
{
    // don't allow user to click twice
    self.view.userInteractionEnabled = NO;
    if ([((UIBarButtonItem *)sender).title isEqualToString:@"Add Closet"]) { // go to add closet
        // the current user can create a closet. this modally presents the create closet view controller
        CLOSCreateClosetViewController *createClosetvc = [[CLOSCreateClosetViewController alloc] init];
        [self presentViewController:createClosetvc animated:YES completion:NULL];
    }
    else { // otherwise add a new group
        CLOSCreateGroupViewController *createGroupvc = [[CLOSCreateGroupViewController alloc] init];
        [self presentViewController:createGroupvc animated:YES completion:NULL];
    }
}

- (IBAction)seeMap:(id)sender
{
    // don't allow user to click twice
    self.view.userInteractionEnabled = NO;
    //check tutorial stage if current user
    if ([self.user.username isEqualToString:[PFUser currentUser].username]) {
        if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:madeItem]]) { // stage needs to be updated
            self.user[@"tutorialStage"] = [NSNumber numberWithInteger:sawMap];
            [self.user saveInBackground];
        }
    }
    CLOSMapViewController *mapvc = [[CLOSMapViewController alloc] init];
    mapvc.usersClosets = self.myClosets;
    for (PFObject *closet in self.myClosets) {
        NSArray *locationStrings = closet[@"FormattedAddressLines"];
        NSMutableString *locationString = [NSMutableString string];
        for (NSString *string in locationStrings) {
            [locationString appendString:string];
            [locationString appendString:@" "];
        }
        [mapvc.stringAddressesToAdd addObject:locationString];
    }
    [self.navigationController pushViewController:mapvc animated:YES];
}

- (IBAction)closetsNearby:(id)sender
{
    // don't allow user to click on anything else right now
    self.view.userInteractionEnabled = NO;
    //check tutorial stage if current user
    if ([self.user.username isEqualToString:[PFUser currentUser].username]) {
        if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:sawMap]]) { // stage needs to be updated
            self.user[@"tutorialStage"] = [NSNumber numberWithInteger:sawClosetsNearby];
            [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [self enterTutorial];
            }];
        }
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        CLLocation *location = locationManager.location;
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            // location services turned off for this app
            if (error) {
                [self closetsNearbyLocOff];
            } else { // location services on for this app. get the current city geopoint
                CLPlacemark *placemark = [placemarks lastObject];
                NSMutableString *cityString = [[NSMutableString alloc] init];
                if (placemark.addressDictionary[@"SubLocality"]) {
                    [cityString appendString:placemark.addressDictionary[@"SubLocality"]];
                    [cityString appendString:@" "];
                }
                [cityString appendString:placemark.addressDictionary[@"City"]];
                [cityString appendString:@" "];
                [cityString appendString:placemark.addressDictionary[@"State"]];
                [cityString appendString:@" "];
                [cityString appendString:placemark.addressDictionary[@"Country"]];
                [geocoder geocodeAddressString:cityString completionHandler:^(NSArray *placemarks, NSError *error) {
                    if (error) {
                        NSLog(@"can't find current city");
                    }
                    else {
                        CLPlacemark *placemarkGeneral = [placemarks lastObject];
                        PFQuery *closetsNearbyQuery = [PFQuery queryWithClassName:@"Closet"];
                        NSNumber *closetsNearbyRange = self.user[@"closetsNearbyRange"];
                        if (!closetsNearbyRange)
                            closetsNearbyRange = [NSNumber numberWithInt:5];
                        [closetsNearbyQuery whereKey:@"geopoint" nearGeoPoint:[PFGeoPoint geoPointWithLocation:placemarkGeneral.location] withinMiles:[closetsNearbyRange intValue]];
                        [closetsNearbyQuery whereKey:@"owner" notEqualTo:[PFUser currentUser]];
                        [closetsNearbyQuery whereKey:@"isPrivate" equalTo:@NO];
                        [closetsNearbyQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            CLOSClosetsAtPlacemarkViewController *closetsAtPlacemarkvc = [[CLOSClosetsAtPlacemarkViewController alloc] init];
                            closetsAtPlacemarkvc.placemark = placemarkGeneral;
                            closetsAtPlacemarkvc.closetsToShow = objects.mutableCopy;
                            closetsAtPlacemarkvc.placemarkTitle = [NSString stringWithFormat:@"closets within %@ miles", closetsNearbyRange];
                            closetsAtPlacemarkvc.navigationItem.title = @"Closets Nearby";
                            [self.navigationController pushViewController:closetsAtPlacemarkvc animated:YES];
                        }];
                    }
                }];
            }
        }];
    }
    else { // location services turned off
        [self closetsNearbyLocOff];
    }
}

- (void) closetsNearbyLocOff
{
    // re-enable interaction because never left the view
    self.view.userInteractionEnabled = YES;
    UIAlertView *locationOff = [[UIAlertView alloc] initWithTitle:@"Location Services Off" message:@"To see closets nearby, you must turn on location services." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    locationOff.alertViewStyle = UIAlertViewStyleDefault;
    [locationOff show];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue cell and get pointers to its label and imageview
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ClosetCell" forIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:50];
    
    // get the closet for the specific cell
    PFObject *closet = self.myClosets[indexPath.row];
    
    // set the name label and image view according to the closet's properties
    NSString *closetName = closet[@"name"];
    [titleLabel setText:closetName];
    
    NSNumber *closetDoorPhotoNumber = closet[@"photoNumber"];
    int number = [closetDoorPhotoNumber intValue];
    switch (number) {
        case 1:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[1].jpg"]];
            break;
        case 2:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[2].jpg"]];
            break;
        case 3:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[3].jpg"]];
            break;
        case 4:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[4].jpg"]];
            break;
        case 5:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[5].jpg"]];
            break;
        default:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[0].jpg"]];
            break;
    }
    
    cell.alpha = 1.0;
    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //check tutorial stage if current user
    if ([self.user.username isEqualToString:[PFUser currentUser].username]) {
        if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:madeCloset]]) {
            self.user[@"tutorialStage"] = [NSNumber numberWithInteger:viewedCloset];
            [self.user saveInBackground];
        }
    }
    // push an individual closet view controller that will display the selected closet
    PFObject *closet = self.myClosets[indexPath.row];
    CLOSIndividualClosetViewController *individualvc = [[CLOSIndividualClosetViewController alloc] init];
    individualvc.closet = closet;
    individualvc.user = self.user;
    [self.navigationController pushViewController:individualvc animated:YES];
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // return the number of closets self.user owns
    return [self.myClosets count];
}

- (IBAction)settings:(id)sender
{
    if ([self.user[@"tutorialStage"] isEqual:@(sawGroups)]) { // need to update tutorial stage
        self.user[@"tutorialStage"] = [NSNumber numberWithInteger:done];
        [self.user saveInBackground];
    }
    
    CLOSSettingsViewController *settings = [[CLOSSettingsViewController alloc] init];
    [self.navigationController pushViewController:settings animated:YES];
}

- (void) options:(id) sender
{
    UIActionSheet *optionsActionSheet = [[UIActionSheet alloc] initWithTitle:@"Options"
                                                                    delegate:self cancelButtonTitle:@"Cancel"
                                                      destructiveButtonTitle:@"Report This User"
                                                           otherButtonTitles: nil];
    optionsActionSheet.tag = 23;
    [optionsActionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)profileViewTapped
{
    UIActionSheet *cameraSheet;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            //linked with fb and has camera
            cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Change Profile Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take A Photo", @"Choose From Library", @"Import From Facebook", @"Set to Default", nil];
        } else {
            //not linked with fb and has camera
            cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Change Profile Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take A Photo", @"Choose From Library", @"Set to Default", nil];
        }
    } else {
        if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
            //linked with fb and don't have camera
            cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Change Profile Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Choose From Library", @"Import From Facebook", @"Set to Default", nil];
        } else {
            //not linked with fb and don't have camera
            cameraSheet = [[UIActionSheet alloc] initWithTitle:@"Change Profile Picture" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Choose From Library", @"Set to Default", nil];
        }
    }
    cameraSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [cameraSheet showFromTabBar:self.tabBarController.tabBar];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 123) { // clicked pending
        if (buttonIndex == actionSheet.destructiveButtonIndex) { // yes, cancel the request
            PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
            [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
            [followQuery whereKey:@"to" equalTo:self.user];
            [followQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                for (PFObject *follow in objects) { // delete follow request
                    [follow deleteInBackground];
                }
            }];
            self.pendingButton.hidden = YES;
            self.isFollowingButton.hidden = NO;
        }
    }
    else if (actionSheet.tag == 23) { // clicked options on other user's profile
        if (buttonIndex == actionSheet.destructiveButtonIndex) { // want to report a user
            CLOSReportAUserViewController *reportAUservc = [[CLOSReportAUserViewController alloc] init];
            reportAUservc.userToReport = self.user;
            [self presentViewController:reportAUservc animated:YES completion:NULL];
        }
    }
    else {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            //camera is available
            if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                //Current user is linked with fb
                if (buttonIndex == 0) {
                    //Take a photo
                    [self presentCameraImagePicker];
                } else if (buttonIndex == 1) {
                    //Choose from library
                    [self presentLibraryImagePicker];
                } else if (buttonIndex == 2) {
                    //Import from Facebook
                    [self getFacebookProfilePicture];
                } else if (buttonIndex == 3) {
                    //Set default image
                    [self makeDefaultProfilePicture];
                }
            } else {
                //Not connected to Facebook
                if (buttonIndex == 0) {
                    [self presentCameraImagePicker];
                } else if (buttonIndex == 1) {
                    //Choose from library
                    [self presentLibraryImagePicker];
                } else if (buttonIndex == 2) {
                    //Set default image
                    [self makeDefaultProfilePicture];
                }
            }
        } else {
            //camera is not available
            if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                //Linked to Facebook
                if (buttonIndex == 0) {
                    //Choose from library
                    [self presentLibraryImagePicker];
                } else if (buttonIndex == 1) {
                    //Import from Facebook
                    [self getFacebookProfilePicture];
                } else if (buttonIndex == 2) {
                    //Set default image
                    [self makeDefaultProfilePicture];
                }
            } else {
                //Not linked with Facebook
                if (buttonIndex == 0) {
                    //Choose from library
                    [self presentLibraryImagePicker];
                } else if (buttonIndex == 1) {
                    //Set default image
                    [self makeDefaultProfilePicture];
                }
            }
        }
    }
}

-(void)presentCameraImagePicker
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.showsCameraControls = YES;
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    self.imagePicker = imagePicker;
    
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

-(void)presentLibraryImagePicker
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    self.imagePicker = imagePicker;
    
    [self presentViewController:imagePicker animated:YES completion:NULL];
}

-(void)getFacebookProfilePicture
{
    //disable imageview touch response
    self.profileView.userInteractionEnabled = NO;
    [FBRequestConnection startWithGraphPath:@"/me?fields=name" parameters:nil HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // URL should point to https://graph.facebook.com/{facebookId}/picture?width=200&height=200&return_ssl_resources=1
            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=200&height=200&return_ssl_resources=1", result[@"id"]]];
            self.profileView.image = nil;
            self.imageData = [[NSMutableData alloc] init];
            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2.0f];
            // Run network request asynchronously
            __unused NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
        } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            [PFUser logOut];
            UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The Facebook session was invalidated. Please login again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [invalidSession show];
            [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while getting the profile picture from Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [errorAlert show];
        }
    }];
}

-(void)makeDefaultProfilePicture
{
    UIImage *image = [UIImage imageNamed:@"PICA.jpg"];
    self.profileView.image = image;
    NSData *imageData = UIImageJPEGRepresentation(image, 0.85f);
    PFUser *currentUser = [PFUser currentUser];
    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@ProfilePicture.jpg", currentUser.username] data:imageData];
    [imageFile saveInBackground];
    currentUser[@"profilePicture"] = imageFile;
    [currentUser saveInBackground];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    //resize the image to 200 * 200
    UIGraphicsBeginImageContext(CGSizeMake(200, 200));
    [image drawInRect: CGRectMake(0, 0, 200, 200)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.profileView.image = smallImage;
    //store the image on parse
    NSData *imageData = UIImageJPEGRepresentation(smallImage, 0.85f);
    PFUser *currentUser = [PFUser currentUser];
    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@ProfilePicture.jpg", currentUser.username] data:imageData];
    [imageFile saveInBackground];
    currentUser[@"profilePicture"] = imageFile;
    [currentUser saveInBackground];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.imageData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Set the image as current user's profile picture
    PFUser *currentUser = [PFUser currentUser];
    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@ProfilePicture.jpg", currentUser.username] data:self.imageData];
    [imageFile saveInBackground];
    currentUser[@"profilePicture"] = imageFile;
    [currentUser saveInBackground];
    self.profileView.image = [UIImage imageWithData:self.imageData];
    //reenable image view touch response
    self.profileView.userInteractionEnabled = YES;
}


# pragma mark - Reachability
- (void) checkReachability {
    /*
     Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the method reachabilityChanged will be called.
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    
    //Change the host name here to change the server you want to monitor.
    NSString *remoteHostName = @"www.apple.com";
    
    self.hostReachability = [Reachability reachabilityWithHostName:remoteHostName];
    [self.hostReachability startNotifier];
   // [self updateInterfaceWithReachability:self.hostReachability];
    
    self.internetReachability = [Reachability reachabilityForInternetConnection];
    [self.internetReachability startNotifier];
   // [self updateInterfaceWithReachability:self.internetReachability];
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    //[self updateInterfaceWithReachability:self.wifiReachability];
    
}


/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
	[self updateInterfaceWithReachability:curReach];
}

- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    // update reachability

    // static variable to make sure label isn't created and shown twice
    static int isShowing = 0;
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    if (netStatus == NotReachable) {
        // no internet
        if (isShowing == 0) { // label not already being shown
            // configure the no internet label to be displayed in the main window
            CGRect navFrame = self.navigationController.navigationBar.frame;
            self.noInternetLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, navFrame.size.height+10, navFrame.size.width, 30)];
            self.noInternetLabel.text = @"No Internet. Nothing you do will be saved.";
            self.noInternetLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:15.0];
            self.noInternetLabel.textColor = [UIColor whiteColor];
            self.noInternetLabel.textAlignment = NSTextAlignmentCenter;
            self.noInternetLabel.backgroundColor = [UIColor darkGrayColor];
            [[[UIApplication sharedApplication] keyWindow] addSubview:self.noInternetLabel];
            // increase isShowing so that label won't be made twice even though this update method is called multiple times whenever connection changes
            isShowing++;
        }
    }
    else { // there is internet
        isShowing = 0; // reset is showing because label isn't showing
        [self.noInternetLabel removeFromSuperview];
        self.noInternetLabel.hidden = YES;
        self.noInternetLabel = nil;
    }
    
}

-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.myClosets.count - 10 && self.endOfQuerying == NO) {
        if ([self.user.username isEqualToString:[PFUser currentUser].username]){
            // get the current user's closets
            PFRelation *relation = [self.user relationForKey:@"ownedClosets"];
            PFQuery *query = [relation query];
            query.skip = [self.myClosets count];
            query.limit = 20;
            [query orderByDescending:@"createdAt"];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                [self.loadingIndicator stopAnimating];
                if (error) {
                    // clear out closets shown before if can't reach parse
                    NSInteger counter = [self.myClosets count];
                    NSMutableArray *indexPaths = [NSMutableArray array];
                    for (NSInteger i = 0; i < counter; i++) {
                        NSIndexPath *ip = [NSIndexPath indexPathForRow: i inSection:0];
                        [indexPaths addObject:ip];
                    }
                    self.myClosets = nil;
                    self.numberOfClosets = -1;
                    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
                    UIAlertView *failAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                                        message:@"Cannot reach the internet. Please check your internet connection before loading the app again."
                                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [failAlert show];
                    [self.hasNoPublicClosetsLabel setText:@"no internet"];
                    self.hasNoPublicClosetsLabel.hidden = NO;
                }
                else {
                    if ([objects count] > 0) {
                        NSInteger lastRow = [self.myClosets count];
                        [self.myClosets addObjectsFromArray:objects];
                        self.numberOfClosets = self.myClosets.count;
                        NSInteger counter = [objects count];
                        NSMutableArray *indexPaths = [NSMutableArray array];
                        for (NSInteger i = 0; i < counter; i++) {
                            NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                            [indexPaths addObject:ip];
                        }
                        [self.collectionView insertItemsAtIndexPaths:indexPaths];
                    } else {
                        self.endOfQuerying = YES;
                        self.numberOfClosets = self.myClosets.count;
                        if ([self.myClosets count] == 0) {// if current user has no closets show the label
                            self.hasNoPublicClosetsLabel.hidden = NO;
                        }
                    }
                }
            }];


        }
        else if (self.isFollowing == YES || [self.user[@"isPrivate"] isEqual:@NO]){
            //if not current user's profile
            //check if the following this user or if the user is public
            //if already following this user or user is public, get all closets to display and put them into self.myClosets
            PFRelation *relation = [self.user relationForKey:@"ownedClosets"];
            PFQuery *query = [relation query];
            query.skip = [self.myClosets count];
            query.limit = 20;
            [query whereKey:@"isPrivate" notEqualTo:@YES]; // don't get any private closets
            [query orderByDescending:@"createdAt"];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if ([objects count] > 0) {
                    NSInteger lastRow = [self.myClosets count];
                    [self.myClosets addObjectsFromArray:objects];
                    self.numberOfClosets = self.myClosets.count;
                    NSInteger counter = [objects count];
                    NSMutableArray *indexPaths = [NSMutableArray array];
                    for (NSInteger i = 0; i < counter; i++) {
                        NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                        [indexPaths addObject:ip];
                    }
                    [self.collectionView insertItemsAtIndexPaths:indexPaths];
                } else {
                    self.numberOfClosets = self.myClosets.count;
                    self.endOfQuerying = YES;
                    if ([self.myClosets count] == 0) {// if current user has no closets show the label
                        self.hasNoPublicClosetsLabel.hidden = NO;
                    }
                }
            }];
        }
    }
}
@end
