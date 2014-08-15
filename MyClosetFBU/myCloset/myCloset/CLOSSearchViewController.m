//
//  CLOSSearchViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSSearchViewController.h"

#import <Parse/Parse.h>

#import "CLOSItemViewController.h"
#import "CLOSProfileViewController.h"
#import "CLOSSearchTableViewCell.h"

@interface CLOSSearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchControl;
@property (weak, nonatomic) IBOutlet UITableView *userTableView;
@property (weak, nonatomic) IBOutlet UITableView *itemTableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;

@property (nonatomic, copy) NSArray *userSearchDisplayData; //List of users satisfying search term
@property (nonatomic, copy) NSArray *itemSearchDisplayData; //List of items satisfying search term
@property (nonatomic, copy) NSArray *userData; //List of all users
@property (nonatomic, copy) NSArray *itemData; //List of all items
@property (nonatomic, copy) NSArray *followingSearchDisplayData; //list of users followed by current user satisfying search term

@property (nonatomic, copy) NSArray *following; //List of following objects the users the current user is following
@property (nonatomic, copy) NSArray *followers; //List of follower objects the users following the current user

@property (nonatomic, strong) NSTimer *searchDelay;
@property (nonatomic, assign) BOOL isUpdatingData;

typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@end

@implementation CLOSSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // Fixing random white space above tableview
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.userTableView.hidden = YES;
    self.itemTableView.hidden = YES;
    self.loadingLabel.hidden = NO;
    //Querying for all following
    PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
    [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
    [followQuery whereKey:@"verificationState" equalTo:@(approved)];
    [followQuery includeKey:@"to"];
    [followQuery findObjectsInBackgroundWithBlock:^(NSArray *following, NSError *error) {
        self.following = following;
        self.followingSearchDisplayData = [following valueForKey:@"to"];
        //get an array of following usernames
        NSArray *followingUsernames = [following valueForKeyPath:@"to.username"];
        //Query for users
        PFQuery *userQuery = [PFUser query];
        //want users that are not followings
        [userQuery whereKey:@"username" notContainedIn:followingUsernames];
        //want users that are not user himself/herself
        [userQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];
        userQuery.limit = 14;
        [userQuery orderByDescending:@"weightedActivity"];
        [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            //since search string is nil, show all users queried
            self.userSearchDisplayData = objects;
            self.userData = objects;
            [self.userTableView reloadData];
        }];


    }];
    //Querying for all followers
    PFQuery *followerQuery = [PFQuery queryWithClassName:@"Follow"];
    [followerQuery whereKey:@"to" equalTo:[PFUser currentUser]];
    [followerQuery whereKey:@"verificationState" equalTo:@(approved)];
    [followerQuery findObjectsInBackgroundWithBlock:^(NSArray *followers, NSError *error) {
        self.followers = followers;
        [self.userTableView reloadData];
        self.loadingLabel.hidden = YES;
        if (self.switchControl.selectedSegmentIndex == 0) { // only show the table if on that switch
            self.userTableView.hidden = NO;
            self.itemTableView.hidden = YES;
        }
    }];
    //if the switch changes, switchChanged will be called to change searchDisplayData accordingly
    [self.switchControl addTarget:self action:@selector(switchChanged) forControlEvents:UIControlEventValueChanged];

    //Register nib for cell
    UINib *cellNib = [UINib nibWithNibName:@"CLOSSearchTableViewCell" bundle:nil];
    [self.userTableView registerNib:cellNib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];
    [self.itemTableView registerNib:cellNib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];
    //add a refresh control to allow refreshing of data - no other time is the data refreshed
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];

    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Loading..."];
    [refreshString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [refreshString length])];
    [refreshString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"STHeitiTC-Medium" size:13.0] range:NSMakeRange(0, [refreshString length])];
    refreshControl.attributedTitle = refreshString;

    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.userTableView addSubview:refreshControl];
    UIRefreshControl *itemRefreshControl = [[UIRefreshControl alloc] init];
    itemRefreshControl.attributedTitle = refreshString;

    [itemRefreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.itemTableView addSubview:itemRefreshControl];
    //Change background color and text style of search bar
    for (UIView *subview in self.searchBar.subviews) {
        if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
            [subview removeFromSuperview];
            break;
        }
    }
    self.searchBar.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.6];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];

    //Set switch control font
    [self.switchControl setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0]} forState:UIControlStateNormal];
    //set navigation controller font and style
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0]}];

    self.userTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.itemTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView == self.userTableView) return 2;
    else return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.userTableView && section == 0)
        return [self.followingSearchDisplayData count];
    else if (tableView == self.userTableView)
        return [self.userSearchDisplayData count];
    else return [self.itemSearchDisplayData count];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //paging ahead of time - 6 from the bottom for users or 9 from the bottom for items
    NSInteger pagingCellIndex;
    if (tableView == self.userTableView) {
        //showing user
        pagingCellIndex = [self.userSearchDisplayData count] - 6;
        if (indexPath.section == 1 && indexPath.row == pagingCellIndex && self.isUpdatingData == NO) {
            self.isUpdatingData = YES;
            [self updateData];
        }
    } else {
        //showing item
        pagingCellIndex = [self.itemSearchDisplayData count] - 9;
        if (indexPath.row == pagingCellIndex && self.isUpdatingData == NO) {
            self.isUpdatingData = YES;
            [self updateData];
        }
    }
}

-(void)updateData
{
    if (self.switchControl.selectedSegmentIndex == 0) {
        //load more user data - current limit is 14
        if ([self.searchBar.text isEqualToString:@""]) {
            //no search string; query 14 more users to present in the table view
            PFQuery *userQuery = [PFUser query];

            userQuery.skip = [self.userData count];
            userQuery.limit = 14;
            [userQuery orderByDescending:@"weightedActivity"];
            //get an array of following usernames
            NSArray *followingUsernames = [self.following valueForKeyPath:@"to.username"];
            //want users that are not followings
            [userQuery whereKey:@"username" notContainedIn:followingUsernames];
            //want users that are not user himself/herself
            [userQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];

            [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    NSInteger lastRow = [self.userData count];
                    self.userData = [self.userData arrayByAddingObjectsFromArray:objects];
                    self.userSearchDisplayData = self.userData;
                    //for each item in object, prepare for insertion
                    NSInteger counter = [objects count];
                    NSMutableArray *indexPaths = [NSMutableArray array];
                    for (NSInteger i = 0; i < counter; i++) {
                        NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:1];
                        [indexPaths addObject:ip];
                    }

                    [self.userTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                    self.isUpdatingData = NO;
                }
            }];
        } else {
            //searh string exists; query 14 more users that satisfies the search string
            PFQuery *searchQueryBeginning = [PFUser query];
            [searchQueryBeginning whereKey:@"lowercaseUsername" hasPrefix:[self.searchBar.text lowercaseString]];

            PFQuery *searchQueryMiddle = [PFUser query];
            [searchQueryMiddle whereKey:@"lowercaseUsername" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

            PFQuery *searchQuery = [PFQuery orQueryWithSubqueries:@[searchQueryBeginning, searchQueryMiddle]];

            //don't want users following
            [searchQuery whereKey:@"username" notContainedIn:[self.following valueForKeyPath:@"to.username"]];
            //don't want current user
            [searchQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];

            searchQuery.skip = [self.userSearchDisplayData count];
            searchQuery.limit = 14;

            [searchQuery orderByDescending:@"weightedActivity"];
            [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    NSInteger lastRow = [self.userSearchDisplayData count];
                    self.userSearchDisplayData = [self.userSearchDisplayData arrayByAddingObjectsFromArray:objects];

                    //for each item in object, prepare for insertion
                    NSInteger counter = [objects count];
                    NSMutableArray *indexPaths = [NSMutableArray array];
                    for (NSInteger i = 0; i < counter; i++) {
                        NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:1];
                        [indexPaths addObject:ip];
                    }
                    //inserting new users based on search
                    [self.userTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                    self.isUpdatingData = NO;
                }

            }];

        }
    } else {
        //load more item data
        if ([self.searchBar.text isEqualToString:@""]) {
            //search string is empty; query 20 more items to present
            PFQuery *itemQuery = [self itemQueryWithoutSearchText];
            itemQuery.skip = [self.itemData count];

            [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                NSInteger lastRow = [self.itemData count];
                self.itemData = [self.itemData arrayByAddingObjectsFromArray:objects];
                self.itemSearchDisplayData = self.itemData;

                //for each item in object, prepare for insertion
                NSInteger counter = [objects count];
                NSMutableArray *indexPaths = [NSMutableArray array];
                for (NSInteger i = 0; i < counter; i++) {
                    NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                    [indexPaths addObject:ip];
                }
                //inserting new items
                [self.itemTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                self.isUpdatingData = NO;

            }];
        } else {
            //search string exists; query 20 more items that satisfies the predicate
            PFQuery *searchQuery = [self itemQueryWithSearchText];

            searchQuery.skip = [self.itemSearchDisplayData count];

            [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    NSInteger lastRow = [self.itemSearchDisplayData count];
                    self.itemSearchDisplayData = [self.itemSearchDisplayData arrayByAddingObjectsFromArray:objects];

                    //for each item in object, prepare for insertion
                    NSInteger counter = [objects count];
                    NSMutableArray *indexPaths = [NSMutableArray array];
                    for (NSInteger i = 0; i < counter; i++) {
                        NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                        [indexPaths addObject:ip];
                    }
                    //inserting new items based on search
                    [self.itemTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                    self.isUpdatingData = NO;
                }

            }];

        }

    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSSearchTableViewCell *cell;
    if ([tableView isEqual:self.userTableView]) {
        cell = [self.userTableView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell" forIndexPath:indexPath];
        //Clear all fields that wait for loading
        cell.image.image = nil;
        cell.itemDescription.text = @"";
        cell.optionsButton.hidden = YES;
        PFUser *cellUser;
        if (indexPath.section == 1) {
            //selected user from search display data
            cellUser = self.userSearchDisplayData[indexPath.row];
        } else {
            //selected user that is following
            cellUser = self.followingSearchDisplayData[indexPath.row];
        }
        cell.itemName.text = cellUser.username;

        //Get the profile picture of the suer
        PFFile *imageFile = cellUser[@"profilePicture"];
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            UIImage *image = [UIImage imageWithData:data];
            cell.image.image = image;
        }];
        //check if cellUser is a follower/being followed
        NSArray *cellUserFollowers = [self.followers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"from.objectId matches %@", cellUser.objectId]]; //Is there a more efficient way?
        NSArray *cellUserFollowing = [self.following filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"to.objectId matches %@", cellUser.objectId]];
        if ([cellUserFollowers count] != 0 && [cellUserFollowing count] != 0) cell.itemDescription.text = @"You are following each other";
        else if ([cellUserFollowers count] != 0) cell.itemDescription.text = @"This user is following you";
        else if ([cellUserFollowing count] != 0) cell.itemDescription.text = @"You are following this user";
    } else {
        cell = [self.itemTableView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell" forIndexPath:indexPath];
        //Clear all fields that wait for loading
        cell.image.image = nil;
        cell.itemDescription.text = @"";
        cell.optionsButton.hidden = YES;
        //selected item
        cell.itemName.text = (NSString *)self.itemSearchDisplayData[indexPath.row][@"name"];
        cell.itemDescription.text = (NSString *)self.itemSearchDisplayData[indexPath.row][@"ownerUsername"];
        //Get the image of the item
        PFFile *imageFile = self.itemSearchDisplayData[indexPath.row][@"itemImage"];
        [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            UIImage *image = [UIImage imageWithData:data];
            cell.image.image = image;
        }];
    }
    return cell;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchDelay invalidate];
    self.searchDelay = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateTable) userInfo:nil repeats:NO];
}

-(void)updateTable
{
    if ([self.searchBar.text isEqualToString:@""]) {
        //empty string
        if (self.switchControl.selectedSegmentIndex == 0)
            self.userTableView.hidden = NO;
        else self.itemTableView.hidden = NO;
        self.loadingLabel.hidden = YES;
        //Empty string - display all users/items currently stored (instead of fetching)
        if (self.switchControl.selectedSegmentIndex == 0)
        {
            //user table shown
            self.followingSearchDisplayData = [self.following valueForKey:@"to"];
            self.userSearchDisplayData = self.userData;
            [self.userTableView reloadData];
        }
        else {
            //item table shown
            if (!self.itemData) {
                self.itemTableView.hidden = YES;
                self.loadingLabel.hidden = NO;
                PFQuery *itemQuery = [self itemQueryWithoutSearchText];
                [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    self.itemData = objects;
                    if ([self.searchBar.text isEqualToString:@""] && self.switchControl.selectedSegmentIndex == 0) {
                        self.itemSearchDisplayData = self.itemData;
                        [self.itemTableView reloadData];
                        self.itemTableView.hidden = NO;
                        self.loadingLabel.hidden = YES;
                    }
                }];
            } else {
                self.itemSearchDisplayData = self.itemData;
                [self.itemTableView reloadData];
            }
        }
    } else {
        //has search string
        if (self.switchControl.selectedSegmentIndex == 0) {
            self.userTableView.hidden = YES;
            self.loadingLabel.hidden = NO;
            //filter the following array for people that satisfy the search text
            self.followingSearchDisplayData = [[self.following valueForKey:@"to"]
                                               filteredArrayUsingPredicate:
                                               [NSPredicate predicateWithFormat:@"lowercaseUsername BEGINSWITH[cd] %@ OR lowercaseUsername CONTAINS[cd] %@",
                                                [self.searchBar.text lowercaseString],
                                                [NSString stringWithFormat:@" %@",
                                                 [self.searchBar.text lowercaseString]]]];
            //Fetching 14 users not following that satisfy the predicate
            PFQuery *searchQueryBeginning = [PFUser query];
            [searchQueryBeginning whereKey:@"lowercaseUsername" hasPrefix:[self.searchBar.text lowercaseString]];

            PFQuery *searchQueryMiddle = [PFUser query];
            [searchQueryMiddle whereKey:@"lowercaseUsername" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

            PFQuery *searchQuery = [PFQuery orQueryWithSubqueries:@[searchQueryBeginning, searchQueryMiddle]];
            //don't want users following
            [searchQuery whereKey:@"username" notContainedIn:[self.following valueForKeyPath:@"to.username"]];
            //don't want current user
            [searchQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];
            searchQuery.limit = 14;
            [searchQuery orderByDescending:@"weightedActivity"];
            NSString *searchText = self.searchBar.text;
            [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                //TODO: possibly move all search requests to one thread and if a new job comes, override the previous ones
                if ([searchText isEqualToString:self.searchBar.text] && self.switchControl.selectedSegmentIndex == 0) {
                    self.userSearchDisplayData = objects;
                    [self.userTableView reloadData];
                    if (self.switchControl.selectedSegmentIndex == 0) { // only show the table if on that switch still
                        self.userTableView.hidden = NO;
                    }
                    self.loadingLabel.hidden = YES;
                }
            }];
        } else {
            self.itemTableView.hidden = YES;
            self.loadingLabel.hidden = NO;
            //Fetching 20 items satisfying the predicate
            PFQuery *searchQuery = [self itemQueryWithSearchText];

            NSString *searchText = self.searchBar.text;
            [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if ([searchText isEqualToString:self.searchBar.text] && self.switchControl.selectedSegmentIndex == 1) {
                    self.itemSearchDisplayData = objects;
                    [self.itemTableView reloadData];
                    self.itemTableView.hidden = NO;
                    self.loadingLabel.hidden = YES;
                }
            }];
        }
    }
}

-(void)switchChanged
{
    [self.view endEditing:YES];

    [self.searchDelay invalidate];
    self.searchDelay = [NSTimer scheduledTimerWithTimeInterval:0.4 target:self selector:@selector(switchUpdate) userInfo:nil repeats:NO];
}

-(void)switchUpdate
{
    if (self.switchControl.selectedSegmentIndex == 0) {
        //changed to user search
        //Note: userData is always initialized by viewDidLoad
        NSString *searchText = self.searchBar.text;
        if (![searchText isEqualToString:@""]) {
            //filter the following array for people that satisfy the search text
            self.followingSearchDisplayData = [[self.following valueForKey:@"to"]
                                               filteredArrayUsingPredicate:
                                               [NSPredicate predicateWithFormat:@"lowercaseUsername BEGINSWITH[cd] %@ OR lowercaseUsername CONTAINS[cd] %@",
                                                [searchText lowercaseString],
                                                [NSString stringWithFormat:@" %@",
                                                 [searchText lowercaseString]]]];
            //Not empty search string; fetch 14 users that satisfy the predicate
            PFQuery *searchQueryBeginning = [PFUser query];
            [searchQueryBeginning whereKey:@"lowercaseUsername" hasPrefix:[searchText lowercaseString]];

            PFQuery *searchQueryMiddle = [PFUser query];
            [searchQueryMiddle whereKey:@"lowercaseUsername" containsString:[NSString stringWithFormat:@" %@", [searchText lowercaseString]]];

            PFQuery *searchQuery = [PFQuery orQueryWithSubqueries:@[searchQueryBeginning, searchQueryMiddle]];
            //don't want users following
            [searchQuery whereKey:@"username" notContainedIn:[self.following valueForKeyPath:@"to.username"]];
            //don't want current user
            [searchQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];
            searchQuery.limit = 14;
            [searchQuery orderByDescending:@"weightedActivity"];
            self.userTableView.hidden = YES;
            self.itemTableView.hidden = YES;
            self.loadingLabel.hidden = NO;
            [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                //Display the data
                if (self.switchControl.selectedSegmentIndex == 0 && [self.searchBar.text isEqualToString:searchText]) {
                    self.userSearchDisplayData = objects;
                    [self.userTableView reloadData];
                    self.userTableView.hidden = NO;
                    self.loadingLabel.hidden = YES;
                }
            }];
        } else {
            //Empty search string; display the userData already fetched
            self.userSearchDisplayData = self.userData;
            [self.userTableView reloadData];
            self.userTableView.hidden = NO;
            self.itemTableView.hidden = YES;
            self.loadingLabel.hidden = YES;
        }
    } else {
        //changed to item search
        NSString *searchText = self.searchBar.text;
        if (![searchText isEqualToString:@""]) {
            self.userTableView.hidden = YES;
            self.itemTableView.hidden = YES;
            self.loadingLabel.hidden = NO;
            //Not empty search string; fetch 20 items that satisfy the predicate
            PFQuery *searchQuery = [self itemQueryWithSearchText];

            [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (self.switchControl.selectedSegmentIndex == 1 && [self.searchBar.text isEqualToString:searchText]) {
                    self.itemSearchDisplayData = objects;
                    [self.itemTableView reloadData];
                    self.itemTableView.hidden = NO;
                    self.loadingLabel.hidden = YES;
                }
            }];
        } else {
            //Empty search string; display the itemData already fetched if fetched
            if (!self.itemData) {
                self.userTableView.hidden = YES;
                self.itemTableView.hidden = YES;
                self.loadingLabel.hidden = NO;
                //itemData hasn't been fetched - fetch 20 items
                PFQuery *itemQuery = [self itemQueryWithoutSearchText];
                [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
                    self.itemData = items;
                    if (self.switchControl.selectedSegmentIndex == 1 && [self.searchBar.text isEqualToString:@""]) {
                        self.itemSearchDisplayData = self.itemData;
                        [self.itemTableView reloadData];
                        self.itemTableView.hidden = NO;
                        self.loadingLabel.hidden = YES;
                    }
                }];
            } else {
                self.itemSearchDisplayData = self.itemData;
                [self.itemTableView reloadData];
                self.itemTableView.hidden = NO;
                self.userTableView.hidden = YES;
                self.loadingLabel.hidden = YES;
            }
        }
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    if (tableView == self.userTableView) {
        //Create a profile view
        CLOSProfileViewController *profilevc = [[CLOSProfileViewController alloc] init];
        if (indexPath.section == 0) {
            profilevc.user = self.followingSearchDisplayData[indexPath.row];
        } else {
            profilevc.user = self.userSearchDisplayData[indexPath.row];
        }
        [self.navigationController pushViewController:profilevc animated:YES];
        [self.userTableView deselectRowAtIndexPath:indexPath animated:YES];
    } else {
        //Create a item view
        CLOSItemViewController *itemvc = [[CLOSItemViewController alloc] init];
        itemvc.item = self.itemSearchDisplayData[indexPath.row];
        [self.navigationController pushViewController:itemvc animated:YES];
        [self.itemTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

-(IBAction)handleRefresh:(id)sender
{
    [self.view endEditing:YES];

    if (self.switchControl.selectedSegmentIndex == 0) {
        //Update user data and display data
        if ([self.searchBar.text isEqualToString:@""]) {
            //Querying for all following
            PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
            [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
            [followQuery whereKey:@"verificationState" equalTo:@(approved)];
            [followQuery includeKey:@"to"];
            [followQuery findObjectsInBackgroundWithBlock:^(NSArray *following, NSError *error) {
                self.following = following;
                self.followingSearchDisplayData = [following valueForKey:@"to"];
                //get an array of following usernames
                NSArray *followingUsernames = [following valueForKeyPath:@"to.username"];
                //Query for users
                PFQuery *userQuery = [PFUser query];
                //want users that are not followings
                [userQuery whereKey:@"username" notContainedIn:followingUsernames];
                //want users that are not user himself/herself
                [userQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];
                userQuery.limit = 14;
                [userQuery orderByDescending:@"weightedActivity"];
                [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    //since search string is nil, show all users queried
                    self.userData = objects;
                    if (self.switchControl.selectedSegmentIndex == 0 && [self.searchBar.text isEqualToString:@""]) {
                        self.userSearchDisplayData = objects;
                        [self.userTableView reloadData];
                    }
                     [(UIRefreshControl *)sender endRefreshing];
                }];
            }];

            //Querying for followers for refresh
            PFQuery *followerQuery = [PFQuery queryWithClassName:@"Follow"];
            [followerQuery whereKey:@"to" equalTo:[PFUser currentUser]];
            [followerQuery whereKey:@"verificationState" equalTo:@(approved)];
            [followerQuery findObjectsInBackgroundWithBlock:^(NSArray *followers, NSError *error) {
                self.followers = followers;
                if (self.switchControl.selectedSegmentIndex == 0 && [self.searchBar.text isEqualToString:@""])
                    [self.userTableView reloadData];
            }];
        } else {
            //string is not empty, query the initial 14 users that satisfy the predicate
            //Not empty search string; fetch 14 users that satisfy the predicate
            NSString *searchText = self.searchBar.text;
            //Querying for following for refresh
            PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
            [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
            [followQuery whereKey:@"verificationState" equalTo:@(approved)];
            [followQuery includeKey:@"to"];
            [followQuery findObjectsInBackgroundWithBlock:^(NSArray *following, NSError *error) {
                self.following = following;

                PFQuery *searchQueryBeginning = [PFUser query];
                [searchQueryBeginning whereKey:@"lowercaseUsername" hasPrefix:[searchText lowercaseString]];

                PFQuery *searchQueryMiddle = [PFUser query];
                [searchQueryMiddle whereKey:@"lowercaseUsername" containsString:[NSString stringWithFormat:@" %@", [searchText lowercaseString]]];

                PFQuery *searchQuery = [PFQuery orQueryWithSubqueries:@[searchQueryBeginning, searchQueryMiddle]];
                //don't want users following
                [searchQuery whereKey:@"username" notContainedIn:[self.following valueForKeyPath:@"to.username"]];
                //don't want current user
                [searchQuery whereKey:@"username" notEqualTo:[PFUser currentUser].username];
                searchQuery.limit = 14;
                [searchQuery orderByDescending:@"weightedActivity"];
                [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    if (self.switchControl.selectedSegmentIndex == 0 && [self.searchBar.text isEqualToString:searchText]) {
                        self.userSearchDisplayData = objects;
                        self.followingSearchDisplayData = [[self.following valueForKey:@"to"]
                                                           filteredArrayUsingPredicate:
                                                           [NSPredicate predicateWithFormat:@"lowercaseUsername BEGINSWITH[cd] %@ OR lowercaseUsername CONTAINS[cd] %@",
                                                            [self.searchBar.text lowercaseString],
                                                            [NSString stringWithFormat:@" %@",
                                                             [self.searchBar.text lowercaseString]]]];
                        [self.userTableView reloadData];
                    }
                    [(UIRefreshControl *)sender endRefreshing];
                }];

            }];

            //Querying for follower for refresh
            PFQuery *followerQuery = [PFQuery queryWithClassName:@"Follow"];
            [followerQuery whereKey:@"to" equalTo:[PFUser currentUser]];
            [followerQuery whereKey:@"verificationState" equalTo:@(approved)];
            [followerQuery findObjectsInBackgroundWithBlock:^(NSArray *followers, NSError *error) {
                self.followers = followers;
                if (self.switchControl.selectedSegmentIndex == 0 && [self.searchBar.text isEqualToString:searchText])
                    [self.userTableView reloadData];
            }];
        }
    } else {
        //Update item data and display data
        if ([self.searchBar.text isEqualToString:@""]) {
            //string is empty, query the initial 20 items
            PFQuery *itemQuery = [self itemQueryWithoutSearchText];
            [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
                self.itemData = items;
                if (self.switchControl.selectedSegmentIndex == 1 && [self.searchBar.text isEqualToString:@""]) {
                    self.itemSearchDisplayData = items;
                    [self.itemTableView reloadData];
                }
                [(UIRefreshControl *)sender endRefreshing];
            }];
        } else {
            //string is not empty, query the initial 20 items satisfying the predicate
            NSString *searchText = self.searchBar.text;
            PFQuery *searchQuery = [self itemQueryWithSearchText];

            [searchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (self.switchControl.selectedSegmentIndex == 1 && [self.searchBar.text isEqualToString:searchText]) {
                    self.itemSearchDisplayData = objects;
                    [self.itemTableView reloadData];
                }
                [(UIRefreshControl *)sender endRefreshing];
            }];
        }
    }
}

-(PFQuery *)itemQueryWithoutSearchText
{
    //Query items that are owned by people you are following in a public closet
    PFQuery *followingItemQuery = [PFQuery queryWithClassName:@"Item"];
    //an array of usernames of the people you follow (that were approved if they were private)
    NSArray *followingUsernames = [self.following valueForKeyPath:@"to.username"];
    [followingItemQuery whereKey:@"ownerUsername" containedIn:followingUsernames];
    //Require item to not be in private closet
    [followingItemQuery whereKey:@"isInPrivateCloset" equalTo:@NO];

    //Query items current user own regardless of closet privacy
    PFQuery *ownedItemQuery = [PFQuery queryWithClassName:@"Item"];
    [ownedItemQuery whereKey:@"ownerUsername" equalTo:[PFUser currentUser].username];

    //Subquery of all public users
    PFQuery *publicUserQuery = [PFUser query];
    [publicUserQuery whereKey:@"isPrivate" equalTo:@NO];
    //query for all items that is owned by a public user in a public closet
    PFQuery *publicItemQuery = [PFQuery queryWithClassName:@"Item"];
    [publicItemQuery whereKey:@"owner" matchesQuery:publicUserQuery];
    [publicItemQuery whereKey:@"isInPrivateCloset" equalTo:@NO];
    PFQuery *itemQuery = [PFQuery orQueryWithSubqueries:@[publicItemQuery, ownedItemQuery, followingItemQuery]];

    [itemQuery orderByDescending:@"createdAt"];

    itemQuery.limit = 20;
    return itemQuery;
}

-(PFQuery *)itemQueryWithSearchText
{
    //check public items that begins with search string
    PFQuery *followingItemQueryBeginning = [PFQuery queryWithClassName:@"Item"];
    //an array of usernames of the people you follow (that were approved if they were private)
    NSArray *followingUsernames = [self.following valueForKeyPath:@"to.username"];
    [followingItemQueryBeginning whereKey:@"ownerUsername" containedIn:followingUsernames];
    //Require item to not be in private closet
    [followingItemQueryBeginning whereKey:@"isInPrivateCloset" equalTo:@NO];
    [followingItemQueryBeginning whereKey:@"lowercaseName" hasPrefix:[self.searchBar.text lowercaseString]];

    //check public items that contains search string as the beginning of a word
    PFQuery *followingItemQueryMiddle = [PFQuery queryWithClassName:@"Item"];
    [followingItemQueryMiddle whereKey:@"ownerUsername" containedIn:followingUsernames];
    //Require item to not be in private closet
    [followingItemQueryMiddle whereKey:@"isInPrivateCloset" equalTo:@NO];
    [followingItemQueryMiddle whereKey:@"lowercaseName" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

    //Query items current user own regardless of closet privacy
    //check owned items that begin with search string
    PFQuery *ownedItemQueryBeginning = [PFQuery queryWithClassName:@"Item"];
    [ownedItemQueryBeginning whereKey:@"ownerUsername" equalTo:[PFUser currentUser].username];
    [ownedItemQueryBeginning whereKey:@"lowercaseName" hasPrefix:[self.searchBar.text lowercaseString]];

    //check owned items that has search string as the beginning of a word
    PFQuery *ownedItemQueryMiddle = [PFQuery queryWithClassName:@"Item"];
    [ownedItemQueryMiddle whereKey:@"ownerUsername" equalTo:[PFUser currentUser].username];
    [ownedItemQueryMiddle whereKey:@"lowercaseName" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

    //Subquery of all public users
    PFQuery *publicUserQuery = [PFUser query];
    [publicUserQuery whereKey:@"isPrivate" equalTo:@NO];
    PFQuery *publicItemQueryBeginning = [PFQuery queryWithClassName:@"Item"];
    [publicItemQueryBeginning whereKey:@"owner" matchesQuery:publicUserQuery];
    [publicItemQueryBeginning whereKey:@"isInPrivateCloset" equalTo:@NO];
    [publicItemQueryBeginning whereKey:@"lowercaseName" hasPrefix:[self.searchBar.text lowercaseString]];

    PFQuery *publicItemQueryMiddle = [PFQuery queryWithClassName:@"Item"];
    [publicItemQueryMiddle whereKey:@"owner" matchesQuery:publicUserQuery];
    [publicItemQueryMiddle whereKey:@"isInPrivateCloset" equalTo:@NO];
    [publicItemQueryMiddle whereKey:@"lowercaseName" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

    //check public items whose description begins with search string
    PFQuery *followingItemQueryDescriBeginning = [PFQuery queryWithClassName:@"Item"];
    //Query based on the users you are following
    [followingItemQueryDescriBeginning whereKey:@"ownerUsername" containedIn:followingUsernames];
    //Require item to not be in private closet
    [followingItemQueryDescriBeginning whereKey:@"isInPrivateCloset" equalTo:@NO];
    [followingItemQueryDescriBeginning whereKey:@"lowercaseDescription" hasPrefix:[self.searchBar.text lowercaseString]];

    //check public items whose description contains search string as the beginning of a word
    PFQuery *followingItemQueryDescriMiddle = [PFQuery queryWithClassName:@"Item"];
    //an array of usernames of the people you follow (that were approved if they were private)
    //Query based on users you are following
    [followingItemQueryDescriMiddle whereKey:@"ownerUsername" containedIn:followingUsernames];
    //Require item to not be in private closet
    [followingItemQueryDescriMiddle whereKey:@"isInPrivateCloset" equalTo:@NO];
    [followingItemQueryDescriMiddle whereKey:@"lowercaseDescription" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

    //Query items (with description) current user own regardless of closet privacy
    //check owned items that begin with search string
    PFQuery *ownedItemQueryDescriBeginning = [PFQuery queryWithClassName:@"Item"];
    [ownedItemQueryDescriBeginning whereKey:@"ownerUsername" equalTo:[PFUser currentUser].username];
    [ownedItemQueryDescriBeginning whereKey:@"lowercaseDescription" hasPrefix:[self.searchBar.text lowercaseString]];

    //check owned items that has search string as the beginning of a word
    PFQuery *ownedItemQueryDescriMiddle = [PFQuery queryWithClassName:@"Item"];
    [ownedItemQueryDescriMiddle whereKey:@"ownerUsername" equalTo:[PFUser currentUser].username];
    [ownedItemQueryDescriMiddle whereKey:@"lowercaseDescription" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

    PFQuery *publicItemQueryDescriBeginning = [PFQuery queryWithClassName:@"Item"];
    [publicItemQueryDescriBeginning whereKey:@"owner" matchesQuery:publicUserQuery];
    [publicItemQueryDescriBeginning whereKey:@"isInPrivateCloset" equalTo:@NO];
    [publicItemQueryDescriBeginning whereKey:@"lowercaseDescription" hasPrefix:[self.searchBar.text lowercaseString]];

    PFQuery *publicItemQueryDescriMiddle = [PFQuery queryWithClassName:@"Item"];
    [publicItemQueryDescriMiddle whereKey:@"owner" matchesQuery:publicUserQuery];
    [publicItemQueryDescriMiddle whereKey:@"isInPrivateCloset" equalTo:@NO];
    [publicItemQueryDescriMiddle whereKey:@"lowercaseDescription" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

    PFQuery *nameQuery = [PFQuery orQueryWithSubqueries:@[followingItemQueryBeginning, followingItemQueryMiddle,
                                                            ownedItemQueryBeginning, ownedItemQueryMiddle,
                                                            publicItemQueryBeginning, publicItemQueryMiddle
                                                            ]];
    PFQuery *descriQuery = [PFQuery orQueryWithSubqueries:@[followingItemQueryDescriBeginning, followingItemQueryDescriMiddle,
                                                             ownedItemQueryDescriBeginning, ownedItemQueryDescriMiddle,
                                                             publicItemQueryDescriBeginning, publicItemQueryDescriMiddle
                                                             ]];
    PFQuery *searchQuery = [PFQuery orQueryWithSubqueries:@[nameQuery, descriQuery]];
    [searchQuery orderByDescending:@"createdAt"];
    searchQuery.limit = 20;

    return searchQuery;
}

@end
