//
//  CLOSSettingsFindFriendsViewController.m
//  myCloset
//
//  Created by Samantha Wiener on 7/25/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//
#import "CLOSSettingsFindFriendsViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#import <Parse/Parse.h>

#import "CLOSFriendListViewController.h"
#import "CLOSNewsFeedViewController.h"
#import "CLOSProfileViewController.h"
#import "CLOSSearchTableViewCell.h"
#import "CLOSloginViewController.h"

@interface CLOSSettingsFindFriendsViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSArray *facebookFriendsUsingAppData; //list of Facebook friends also using the app not already following
@property (nonatomic, copy) NSArray *following;
@property (weak, nonatomic) IBOutlet UIButton *allButton;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@end

@implementation CLOSSettingsFindFriendsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationItem.title = @"Find Friends to Follow";
    
    //Set up refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Loading..."];
    [refreshString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [refreshString length])];
    [refreshString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"STHeitiTC-Medium" size:13.0] range:NSMakeRange(0, [refreshString length])];
    refreshControl.attributedTitle = refreshString;
    
    //call method handleRefresh
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

    UINib *cellNib = [UINib nibWithNibName:@"CLOSSearchTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];

    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.allButton.layer.cornerRadius = 8.0f;

}

-(void)viewWillAppear:(BOOL)animated
{
    if ([PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        //requery the data when you go back to the page
        //Querying for all following
        self.loadingLabel.hidden = NO;
        self.allButton.hidden = YES;
        self.tableView.hidden = YES;
        PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
        [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
        [followQuery includeKey:@"to"];
        [followQuery findObjectsInBackgroundWithBlock:^(NSArray *following, NSError *error) {
            self.following = following;
            NSArray *followingUsers = [following valueForKeyPath:@"to.username"];
            // Create request for user's friends Facebook data
            FBRequest* friendsRequest = [FBRequest requestForMyFriends];

            // Send request to Facebook
            [friendsRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    // result is a dictionary with the user's Facebook data
                    NSArray *friendObjects = [result objectForKey:@"data"];
                    NSArray *friendIds = [friendObjects valueForKey:@"id"];
                    // Construct a PFUser query that will find friends whose facebook ids
                    // are not contained in the current user's friend list.
                    PFQuery *friendQuery = [PFUser query];
                    [friendQuery whereKey:@"fbId" containedIn:friendIds];
                    [friendQuery whereKey:@"username" notContainedIn:followingUsers];
                    [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *fbNotFollowingUsers, NSError *error) {
                        self.facebookFriendsUsingAppData = fbNotFollowingUsers;
                        if ([fbNotFollowingUsers count] == 0) {
                            self.allButton.hidden = YES;
                            self.loadingLabel.hidden = NO;
                            self.loadingLabel.text = @"You have no more friends to follow";
                        } else {
                            self.allButton.hidden = NO;
                            self.loadingLabel.hidden = YES;
                        }
                        self.tableView.hidden = NO;
                        [self.tableView reloadData];
                    }];

                } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                [PFUser logOut];
                UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The Facebook session was invalidated. Please login again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [invalidSession show];
                [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
                } else {
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while getting your friends from Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlert show];
                    self.facebookFriendsUsingAppData = nil;
                    self.loadingLabel.text = @"You have no more friends to follow";
                    self.loadingLabel.hidden = NO;
                    self.tableView.hidden = NO;
                    self.allButton.hidden = YES;
                    [self.tableView reloadData];
                }
            }];

        }];
    } else {
        self.allButton.hidden = YES;
        self.loadingLabel.hidden = NO;
        self.loadingLabel.numberOfLines = 0;
        self.loadingLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.loadingLabel.text = @"You must be linked with Facebook to find friends!";
        self.tableView.hidden = YES;
    }
    
    
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSSearchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell" forIndexPath:indexPath];
    PFUser *cellUser = self.facebookFriendsUsingAppData[indexPath.row];
    cell.optionsButton.hidden = YES;
    cell.itemName.text = cellUser.username;
    cell.itemDescription.text = [NSString stringWithFormat:@"Joined on %@", [self.dateFormatter stringFromDate:cellUser.createdAt]];
    PFFile *imageFile = cellUser[@"profilePicture"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        cell.image.image = image;
    }];
    //only show follow button if the user is not already following the person
    UIButton *followButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.window.frame.size.width - 12 - 80, 8, 80, 42)];
    followButton.layer.cornerRadius = 8.0f;
    followButton.enabled = YES;
    followButton.tag = indexPath.row;
    NSAttributedString *followString = [[NSAttributedString alloc] initWithString:@"+follow" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [followButton setAttributedTitle:followString forState:UIControlStateNormal];
    followButton.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.5];
    [followButton addTarget:self action:@selector(follow:) forControlEvents:UIControlEventTouchUpInside];
    [cell addSubview:followButton];
    return cell;
}

- (void)follow:(id)sender
{
    UIButton *button = (UIButton *)sender;
    // create a new follow object in parse from the current user to the user whose profile is being shown
    PFUser *selectedUser = self.facebookFriendsUsingAppData[button.tag];
    PFObject *follow = [PFObject objectWithClassName:@"Follow"];
    [follow setObject:selectedUser forKey:@"to"];
    [follow setObject:[PFUser currentUser] forKey:@"from"];
    
    if ([selectedUser[@"isPrivate"]  isEqual: @YES]) {
        follow[@"verificationState"] = [NSNumber numberWithInteger:requested];
    }
    else {
        follow[@"verificationState"] = [NSNumber numberWithInteger:approved];
    }

    [follow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        //update array
        NSMutableArray *notFollowing = self.facebookFriendsUsingAppData.mutableCopy;
        //remove the object from the array of facebook friends not yet following on app
        [notFollowing removeObjectAtIndex:button.tag];
        self.facebookFriendsUsingAppData = notFollowing.copy;
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:button.tag inSection:0]] withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView reloadData];
        if ([self.facebookFriendsUsingAppData count] == 0) {
            self.loadingLabel.hidden = NO;
            self.loadingLabel.text = @"You have no more friends to follow";
            self.allButton.hidden = YES;
        } else {
            self.loadingLabel.hidden = YES;
            self.allButton.hidden = NO;
        }
    }];
    
    //Add push notification
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"username" equalTo:selectedUser.username];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    NSString *message;
    if ([selectedUser[@"isPrivate"] isEqual:@YES]) {
        message = [NSString stringWithFormat:@"%@ requested to follow you", [PFUser currentUser].username];
        [push setData:@{@"alert":message, @"isFollowRequest":@YES}];
    } else {
        message = [NSString stringWithFormat:@"%@ started following you", [PFUser currentUser].username];
        [push setMessage:message];
    }
    
    [push sendPushInBackground];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return [self.facebookFriendsUsingAppData count];
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Create a profile view
    CLOSProfileViewController *profilevc = [[CLOSProfileViewController alloc] init];
    profilevc.user = self.facebookFriendsUsingAppData[indexPath.row];
    [self.navigationController pushViewController:profilevc animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
   
}

-(void)handleRefresh:(id)sender
{
    //resond to manual refresh, and re-Query to check facebook friends and all information
    //Querying for all following
    PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
    [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
    [followQuery includeKey:@"to"];
    [followQuery findObjectsInBackgroundWithBlock:^(NSArray *following, NSError *error) {
        self.following = following;
        NSArray *followingUsers = [following valueForKeyPath:@"to.username"];
        // Create request for user's friends Facebook data
        FBRequest* friendsRequest = [FBRequest requestForMyFriends];
        
        // Send request to Facebook
        [friendsRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // result is a dictionary with the user's Facebook data
                NSArray *friendObjects = [result objectForKey:@"data"];
                NSArray *friendIds = [friendObjects valueForKey:@"id"];
                // Construct a PFUser query that will find friends whose facebook ids
                // are not contained in the current user's friend list.
                PFQuery *friendQuery = [PFUser query];
                [friendQuery whereKey:@"fbId" containedIn:friendIds];
                [friendQuery whereKey:@"username" notContainedIn:followingUsers];
                [friendQuery findObjectsInBackgroundWithBlock:^(NSArray *fbNotFollowingUsers, NSError *error) {
                    self.facebookFriendsUsingAppData = fbNotFollowingUsers;
                    if ([fbNotFollowingUsers count] == 0) {
                        self.loadingLabel.text = @"You have no more friends to follow";
                        self.loadingLabel.hidden = NO;
                        self.allButton.hidden = YES;
                    } else {
                        self.loadingLabel.hidden = YES;
                        self.allButton.hidden = NO;
                    }
                    [self.tableView reloadData];
                    [(UIRefreshControl *)sender endRefreshing];
                }];
                
            } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                [PFUser logOut];
                UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The facebook session was invalidated. Please login again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [invalidSession show];
                [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while getting your friends from Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
                self.facebookFriendsUsingAppData = nil;
                self.loadingLabel.text = @"You have no more friends to follow";
                self.loadingLabel.hidden = NO;
                self.tableView.hidden = NO;
                self.allButton.hidden = YES;
                [self.tableView reloadData];
                [(UIRefreshControl *)sender endRefreshing];
            }
        }];
    }];
}


-(IBAction)followAll:(UIButton *)button
{
    // create a new follow object in parse from the current user to the user whose profile is being shown
    //get all of the users taht you are facebook friends with taht are usign taht app that you are not following
    for (PFUser *selectedUser in self.facebookFriendsUsingAppData){
        PFObject *follow = [PFObject objectWithClassName:@"Follow"];
        [follow setObject:selectedUser forKey:@"to"];
        [follow setObject:[PFUser currentUser] forKey:@"from"];
        if ([selectedUser[@"isPrivate"]  isEqual: @YES]) {
            follow[@"verificationState"] = @(requested);
        }
        else {
            follow[@"verificationState"] = @(approved);
        }

        [follow saveInBackground];
        
        //Add push notification
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"username" equalTo:selectedUser[@"username"]];
        
        // Send push notification to query
        PFPush *push = [[PFPush alloc] init];
        [push setQuery:pushQuery]; // Set our Installation query
        if ([selectedUser[@"isPrivate"] isEqual:@YES]) {
            NSString *message = [NSString stringWithFormat:@"%@ requested to follow you", [PFUser currentUser].username];
            [push setData:@{@"alert":message, @"isFollowRequest":@YES}];
        } else {
            NSString *message = [NSString stringWithFormat:@"%@ started following you", [PFUser currentUser].username];
            [push setMessage:message];
        }
        [push sendPushInBackground];
    }
    //set facebookFriendsUsingAppData to empty
    self.facebookFriendsUsingAppData = [NSArray array];
    
    [self.tableView reloadData];
    self.loadingLabel.text = @"You have no more friends to follow";
    self.loadingLabel.hidden = NO;
    self.allButton.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
