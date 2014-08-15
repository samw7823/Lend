//
//  CLOSAddMemberToGroupViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//
#import "CLOSAddMemberToGroupViewController.h"

#import <Parse/Parse.h>

#import "CLOSCreateGroupViewController.h"
#import "CLOSSearchTableViewCell.h"

@interface CLOSAddMemberToGroupViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (copy, nonatomic) NSArray *relatedUsers;
@property (copy, nonatomic) NSArray *searchDisplayData;
@property (copy, nonatomic) NSArray *membersSearchDisplayData;
@property (strong, nonatomic) NSMutableArray *selectedUsers;
@property (strong, nonatomic) NSMutableArray *deselectedMembers;
@property (strong, nonatomic) NSTimer *delayTimer;
@end

@implementation CLOSAddMemberToGroupViewController

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
    // Do any additional setup after loading the view from its nib.
    //register cell nib
    UINib *cellNib = [UINib nibWithNibName:@"CLOSSearchTableViewCell" bundle:nil];
    [self.tableView registerNib: cellNib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];

    //Hide the table view until query is done
    self.tableView.hidden = YES;
    self.loadingLabel.hidden = NO;
    self.doneButton.enabled = NO;

    if (self.group) {
        //if a group is already present, query the group for members; no array of members will be passed in
        PFRelation *members = [self.group relationForKey:@"members"];
        PFQuery *memberQuery = [members query];
        //do not include the current user in the list of members (can't remove yourself from this page)
        [memberQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];
        [memberQuery findObjectsInBackgroundWithBlock:^(NSArray *members, NSError *error) {
            if (!error) {
                self.alreadyMembers = members;
                //query the people the current user is following or are following the current user
                [self queryRelatedUsers];
            }
        }];
    } else {
        //if no group, it comes from create group - query the people the current user is following or are following the current user
        //an array of members can be passed in
        [self queryRelatedUsers];
    }

    //set up search bar appearance
    self.searchBar.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.6];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];

    //add an empty footer to avoid lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    //set up gesture recognizer to remove keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTouched)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setFont:[UIFont fontWithName:@"STHeitiTC-Medium" size:14.0]];
}

-(void)queryRelatedUsers
{
    //query the followings and followers
    PFUser *currentUser = [PFUser currentUser];
    PFQuery *followingQuery = [PFQuery queryWithClassName:@"Follow"];
    [followingQuery whereKey:@"from" equalTo:currentUser];
    [followingQuery includeKey:@"to"];
    if (self.alreadyMembers) {
        //if got a list of members either passed in from create group or from initial querying with self.group, don't include those in the people to add
        [followingQuery whereKey:@"to" notContainedIn:self.alreadyMembers];
    }
    [followingQuery whereKey:@"verificationState" equalTo:@1];
    [followingQuery findObjectsInBackgroundWithBlock:^(NSArray *followings, NSError *error) {
        //querying for followers inside the block because we need to delete duplicated users
        PFQuery *followerQuery = [PFQuery queryWithClassName:@"Follow"];
        [followerQuery whereKey:@"to" equalTo:currentUser];
        [followerQuery includeKey:@"from"];
        if (self.alreadyMembers) {
            //if got a list of members either passed in from create group or from initial querying with self.group, don't include those in the people to add
            [followerQuery whereKey:@"from" notContainedIn:self.alreadyMembers];
        }
        [followerQuery whereKey:@"verificationState" equalTo:@1];
        [followerQuery findObjectsInBackgroundWithBlock:^(NSArray *followers, NSError *error) {
            //get an array of users that are either following or followed by current user
            NSArray *followingUsers = [followings valueForKey:@"to"];
            NSArray *followerUsers = [followers valueForKey:@"from"];
            NSMutableSet *relatedUsernames = [NSMutableSet new];
            NSArray *relatedUsersWithDuplicates = [followerUsers arrayByAddingObjectsFromArray:followingUsers];
            if (relatedUsersWithDuplicates.count == 0 && self.alreadyMembers.count == 0) {
                self.loadingLabel.numberOfLines = 0;
                self.loadingLabel.lineBreakMode = NSLineBreakByWordWrapping;
                self.loadingLabel.text = @"To add other people to a group, follow them or have them follow you!";
                [self.loadingLabel sizeToFit];
            } else {
                NSMutableArray *relatedUsers = [NSMutableArray array];
                for (PFUser *user in relatedUsersWithDuplicates) {
                    if (![relatedUsernames containsObject:user.username]) {
                        //the user is not already in the related users and is not already a member
                        [relatedUsernames addObject:user.username];
                        [relatedUsers addObject:user];
                    }
                }
                //sort the users by their usernames
                [relatedUsers sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [((PFUser *)obj1).username compare:((PFUser *)obj2).username];
                }];
                self.relatedUsers = relatedUsers;
                self.searchDisplayData = relatedUsers;
                self.membersSearchDisplayData = self.alreadyMembers;
                [self.tableView reloadData];
                self.tableView.hidden = NO;
                self.loadingLabel.hidden = YES;
            }
        }];

    }];

}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.alreadyMembers) {
        //want to show people already in the group and the people to add
        return 2;
    } else {
        //show people to add only
        return 1;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.alreadyMembers && section == 0)
        //section with members
        return @"Current members";
    else
        //section with followers and following
        return @"Add new members";
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.alreadyMembers && section == 0)
        //section with members
        return self.membersSearchDisplayData.count;
    else
        //section with followers and following
        return self.searchDisplayData.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell"];
    //don't highlight the cell when selected - show checkmarks instead
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.optionsButton.hidden = YES;
    cell.backgroundColor = [UIColor clearColor];
    if (self.alreadyMembers && indexPath.section == 0) {
        //show a current member
        PFUser *cellUser = self.membersSearchDisplayData[indexPath.row];
        cell.itemName.text = cellUser.username;
        cell.itemDescription.text = @"";
        //get the profile image
        PFFile *imageFile = cellUser[@"profilePicture"];
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            UIImage *profileImage = [UIImage imageWithData:data];
            cell.image.image = profileImage;
        }];
        //check if this member has been (selected to be) deselected as a member
        if ([self.deselectedMembers containsObject:cellUser]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }

    } else {
        //show a related user
        PFUser *cellUser = self.searchDisplayData[indexPath.row];
        cell.itemName.text = cellUser.username;
        cell.itemDescription.text = @"";
        //get the profile image
        PFFile *imageFile = cellUser[@"profilePicture"];
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            UIImage *profileImage = [UIImage imageWithData:data];
            cell.image.image = profileImage;
        }];
        //check if this user as been selected to be a member
        if ([self.selectedUsers containsObject:cellUser]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }

    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //enable done button if something is selected - something has been changed
    self.doneButton.enabled = YES;
    if (self.alreadyMembers && indexPath.section == 0) {
        //selected a member - put him/her in the list of members deselected (removed from the group)
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        //make the array if it does not exist yet
        if (!self.deselectedMembers) {
            self.deselectedMembers = [NSMutableArray array];
        }
        [self.deselectedMembers addObject:self.membersSearchDisplayData[indexPath.row]];
    } else {
        //selected a related user - put him/her in the list of members selected (added to the group)
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        //make the array if it does not exist yet
        if (!self.selectedUsers) {
            self.selectedUsers = [NSMutableArray array];
        }
        [self.selectedUsers addObject:self.searchDisplayData[indexPath.row]];
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.alreadyMembers && indexPath.section == 0) {
        //deselected a member - remove him/her from the list of members deselected
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        [self.deselectedMembers removeObject:self.membersSearchDisplayData[indexPath.row]];
    } else {
        //deselected a related user - remove him/her from the list of members selected
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        [self.selectedUsers removeObject:self.searchDisplayData[indexPath.row]];
    }
    //check if anything has been changed - if no, then don't enable the done button
    if ([self.selectedUsers count] > 0 || [self.deselectedMembers count] > 0) {
        self.doneButton.enabled = YES;
    } else {
        self.doneButton.enabled = NO;
    }
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.delayTimer invalidate];
    self.delayTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(searchStringChanged) userInfo:nil repeats:NO];
}

-(void)searchStringChanged
{
    NSString *searchText = self.searchBar.text;
    if ([searchText isEqualToString:@""]) {
        //empty search string - reset display data to full data
        self.searchDisplayData = self.relatedUsers;
        self.membersSearchDisplayData = self.alreadyMembers;
    } else {
        //has a search string - filter out the full data to find the users to show
        self.searchDisplayData = [self.relatedUsers filteredArrayUsingPredicate:
                                  [NSPredicate predicateWithFormat:@"username BEGINSWITH[cd] %@ OR username CONTAINS %@", searchText,
                                   [NSString stringWithFormat:@" %@", searchText]]];
        self.membersSearchDisplayData = [self.alreadyMembers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"username BEGINSWITH[cd] %@ OR username CONTAINS %@", searchText,
                                                                                          [NSString stringWithFormat:@" %@", searchText]]];
    }
    [self.tableView reloadData];
}

-(IBAction)donePressed:(UIBarButtonItem *)doneButton
{
    [self.view endEditing:YES];
    doneButton.enabled = NO;
    if (self.group) {
        //has a group - add/remove the relations directly
        PFRelation *members = [self.group relationForKey:@"members"];
        //add the selected users
        for (PFUser *user in self.selectedUsers) {
            [members addObject:user];
            [self.group incrementKey:@"numberOfMembers"];
        }
        //remove the deselected members
        for (PFUser *user in self.deselectedMembers) {
            [members removeObject:user];
            [self.group incrementKey:@"numberOfMembers" byAmount:@-1];
        }
        [self.group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if ([self.selectedUsers count] > 0) {
                /* send push notification to the people added */
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"username" containedIn:[self.selectedUsers valueForKey:@"username"]];

                // Send push notification to query
                PFPush *push = [[PFPush alloc] init];
                [push setQuery:pushQuery]; // Set our Installation query

                NSString *message = [NSString stringWithFormat:@"%@ added you to the group %@", [PFUser currentUser].username, self.group[@"name"]];
                [push setMessage:message];
                [push sendPushInBackground];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        //no group - comes from create group page
        CLOSCreateGroupViewController *presentingVc = (CLOSCreateGroupViewController *)self.presentingViewController;
        if (presentingVc.members) {
            //members array was passed into already users; add and remove accordingly
            NSMutableArray *members = [presentingVc.members arrayByAddingObjectsFromArray:self.selectedUsers].mutableCopy;
            [members removeObjectsInArray:self.deselectedMembers];
            presentingVc.members = members.copy;
        } else {
            presentingVc.members = self.selectedUsers;
        }
         [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)cancelPressed:(id)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(void)backgroundTouched
{
    [self.view endEditing:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
