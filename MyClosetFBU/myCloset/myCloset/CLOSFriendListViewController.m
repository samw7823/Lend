//
//  CLOSFriendListViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/14/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSFriendListViewController.h"

#import <Parse/Parse.h>

#import "CLOSProfileViewController.h"
#import "CLOSSearchTableViewCell.h"
#import "CLOSPendingFollowRequestsTableViewController.h"

@interface CLOSFriendListViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameToFollowTextField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSArray *following;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@end

typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@implementation CLOSFriendListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        //Set up date formatter for the following since description
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        _dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // register a table view cell
    UINib *cellNib = [UINib nibWithNibName:@"CLOSSearchTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];

    // get rid of header space in table view
    self.automaticallyAdjustsScrollViewInsets = NO;

    //add a refresh control
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Loading..."];
    [refreshString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [refreshString length])];
    [refreshString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"STHeitiTC-Medium" size:13.0] range:NSMakeRange(0, [refreshString length])];
    refreshControl.attributedTitle = refreshString;

    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

    // query to find the follow objects for the user. either following or followers depending on boolean set when view controller was pushed.
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query orderByDescending:@"createdAt"];
    query.limit = 15;
    if (self.isFollowers == YES) {
        [query whereKey:@"to" equalTo:self.user];
        [query whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:approved]];
        [query includeKey:@"from"];
        self.title = @"Followers";
    } else {
        [query whereKey:@"from" equalTo:self.user];
        [query whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:approved]];
        [query includeKey:@"to"];
        self.title = @"Following";
    }
    self.tableView.hidden = YES;
    self.loadingLabel.hidden = NO;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.following = objects;
        [self.tableView reloadData];
        self.tableView.hidden = NO;
        self.loadingLabel.hidden = YES;
    }];
    //Add invisible footer to remove separators at the end
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // make sure every time view shows, user can interact with it
    self.view.userInteractionEnabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self.following count] - 4) {
        //the 4th row from the bottom - paging ahead of time to give smooth scrolling
        [self updateData];
    }
}

-(void)updateData
{
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query orderByDescending:@"createdAt"];
    query.skip = [self.following count];
    query.limit = 10;
    if (self.isFollowers == YES) {
        [query whereKey:@"to" equalTo:self.user];
        [query whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:approved]];
        [query includeKey:@"from"];
    } else {
        [query whereKey:@"from" equalTo:self.user];
        [query whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:approved]];
        [query includeKey:@"to"];
    }

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSInteger lastRow = [self.following count];
            self.following = [self.following arrayByAddingObjectsFromArray:objects];
            NSMutableArray *indexPaths = [NSMutableArray array];

            //for each item in object, prepare for insertion
            for (NSInteger i = 0; i < [objects count]; i++) {
                NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                [indexPaths addObject:ip];
            }
            [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
        }
    }];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get a table view cell
    CLOSSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell" forIndexPath:indexPath];
    PFUser *otherUser;
    if (self.isFollowers == YES) {//want to see who is following the user, so get the "from" value of the follow object
        otherUser = self.following[indexPath.row][@"from"];
        // also allow option to remove follower
        [cell bringSubviewToFront:cell.optionsButton];
        [cell.optionsButton addTarget:self
                               action:@selector(options:)
                     forControlEvents:UIControlEventTouchUpInside];
        cell.optionsButton.tag = indexPath.row;
    }
    else {//want to see who the user is following, so get the "to" value of the following object
        otherUser = self.following[indexPath.row][@"to"];
        // also hide the options button
        cell.optionsButton.hidden = YES;
    }
    // set the text label to show the other user's username
    cell.itemName.text = otherUser.username;
    PFFile *imageFile = otherUser[@"profilePicture"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        cell.image.image = [UIImage imageWithData:data];
    }];
    cell.itemDescription.text = [NSString stringWithFormat:@"Following since %@", [self.dateFormatter stringFromDate:((PFObject *)self.following[indexPath.row]).createdAt]];

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // make sure user can't press it twice
    self.view.userInteractionEnabled = NO;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    PFUser *userSelected;
    if (self.isFollowers == YES) //in followers, so user selected is the "from" value of the follow object
        userSelected = self.following[indexPath.row][@"from"];
    else // in following, so user selected is the "to" value of the follow object
        userSelected = self.following[indexPath.row][@"to"];
    
    //push a profile view controller to display the selected user's profile
    CLOSProfileViewController *profilevc = [[CLOSProfileViewController alloc] init];
    profilevc.user = userSelected;
    
    [self.navigationController pushViewController:profilevc animated:YES];
    
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return the number of follow relationships a user has (either follow objects where the user is the follower or follow objects where the user is being followed, depending on what the page is displaying)
    return [self.following count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.user[@"isPrivate"] isEqual:@YES] && self.isFollowers && [self.user.username isEqualToString:[PFUser currentUser].username])
        return 44;
    else
        return 0;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.user[@"isPrivate"] isEqual:@YES] && self.isFollowers && [self.user.username isEqualToString:[PFUser currentUser].username]) { // make sure current user with a private account in their followers page
       // UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, self.navigationController.navigationBar.frame.size.width, 44)];
        UIButton *seeRequests = [[UIButton alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height, self.navigationController.navigationBar.frame.size.width, 44)];
        [seeRequests addTarget:self action:@selector(seeRequests:) forControlEvents:UIControlEventTouchUpInside];
        seeRequests.backgroundColor = [UIColor colorWithWhite:.33 alpha:.5];
        [seeRequests setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [seeRequests setTitle:@"See Pending Follow Requests" forState:UIControlStateNormal];
        seeRequests.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
        return seeRequests;
    }
    else
        return [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) seeRequests: (id) sender
{
    // make sure user can't press it twice
    self.view.userInteractionEnabled = NO;
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"to" equalTo:self.user];
    [query includeKey:@"from"];
    [query whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:requested]];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        CLOSPendingFollowRequestsTableViewController *pendingvc = [[CLOSPendingFollowRequestsTableViewController alloc] init];
        pendingvc.pendingRequests = objects;
        [self.navigationController pushViewController:pendingvc animated:YES];
    }];
}

- (void) options: (id) sender
{
    UIActionSheet *optionsSheet = [[UIActionSheet alloc] initWithTitle:@"Options"
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:@"Remove From Followers"
                                                     otherButtonTitles: nil];
    optionsSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    [optionsSheet showFromTabBar:self.tabBarController.tabBar];
    optionsSheet.tag = ((UIButton *)sender).tag;
}

- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // user clicked options
        if (buttonIndex == actionSheet.destructiveButtonIndex) { // block the user
            PFObject *follow = self.following[actionSheet.tag]; // get the follow object and delete it
            [follow deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded)
                    [self handleRefresh:NULL];
            }];
        }
}

-(void)handleRefresh:(id)sender
{
    PFQuery *query = [PFQuery queryWithClassName:@"Follow"];
    [query orderByDescending:@"createdAt"];
    query.limit = 15;
    if (self.isFollowers == YES) {
        [query whereKey:@"to" equalTo:self.user];
        [query whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:approved]];
        [query includeKey:@"from"];
    } else {
        [query whereKey:@"from" equalTo:self.user];
        [query whereKey:@"verificationState" equalTo:[NSNumber numberWithInteger:approved]];
        [query includeKey:@"to"];
    }

    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.following = objects;
        [self.tableView reloadData];
        [(UIRefreshControl *)sender endRefreshing];
    }];

}
@end
