//
//  CLOSNewsFeedViewController.m
//  myCloset
//
//  Created by Samantha Wiener on 7/28/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSNewsFeedViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <FacebookSDK/FacebookSDK.h>

#import <Parse/Parse.h>

#import "CLOSBorrowViewController.h"
#import "CLOSItemViewController.h"
#import "CLOSLikesViewController.h"
#import "CLOSMapPopoverViewController.h"
#import "CLOSMapViewController.h"
#import "CLOSNewsFeedHeaderView.h"
#import "CLOSNewsFeedTableViewCell.h"
#import "CLOSProfileViewController.h"
#import "CLOSSearchViewController.h"
#import "Reachability.h"

#define NUM_OF_SEC_IN_MIN 60.0
#define NUM_OF_SEC_IN_HOUR (NUM_OF_SEC_IN_MIN * 60)
#define NUM_OF_SEC_IN_DAY (NUM_OF_SEC_IN_HOUR * 24)
#define NUM_OF_SEC_IN_WEEK (NUM_OF_SEC_IN_DAY * 7)
@interface CLOSNewsFeedViewController () <UITableViewDataSource, UITabBarDelegate, UITableViewDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSArray *following;
@property (nonatomic, copy) NSArray *newsFeedItems;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (nonatomic, copy) NSArray *userInfo;
@property (nonatomic, copy) NSArray *itemSectionTitles;
@property (nonatomic, copy) NSArray *itemsLiked;
@property (nonatomic, copy) NSArray *closets;
@property (weak, nonatomic) IBOutlet UIButton *findPeopleToFollowButton;
@property (nonatomic, assign) BOOL isUpdatingData;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UILabel *notFollowingLabel;
typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@end

@implementation CLOSNewsFeedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
//    if ([self.newsFeedItems count] == 0) { // if there are no items, then call refresh
//        [self handleRefresh:NULL];
//    }
    // make sure interaction enabled
//    if ([self.newsFeedItems count] != 0) {
//        self.tableView.hidden = NO;
//    }
    if (self.tableView.hidden == YES) {
        //if the tableview is hidden display the refresh button
        self.refreshButton.hidden = NO;
        self.refreshButton.enabled = YES;
        [self.refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    }

    self.view.userInteractionEnabled = YES;
}

- (void)viewDidLoad
{
    UINavigationController *profNav = (UINavigationController *)[self.tabBarController.viewControllers lastObject];
    CLOSProfileViewController *profInTabBar = (CLOSProfileViewController *)[profNav.viewControllers firstObject];
    [profInTabBar checkReachability];
    
    [super viewDidLoad];
     self.automaticallyAdjustsScrollViewInsets = NO;
    // Do any additional setup after loading the view from its nib.
    //Querying for all following and their most recent posts
    self.findPeopleToFollowButton.hidden = YES;
    self.notFollowingLabel.hidden = YES;
    
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable) { // only query if internet is reachable
        PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
        [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
        [followQuery whereKey:@"verificationState" equalTo:@(approved)];
        [followQuery includeKey:@"to"];
        NSMutableArray *followingUsers = [NSMutableArray array];
        //Create mutable array to add items for news feed
        [followQuery findObjectsInBackgroundWithBlock:^(NSArray *followingObjects, NSError *error) {
            //gives all users that you are following
            for (int i = 0; i < [followingObjects count]; i++) {
                //Make sure that we haven't deleted the user from parse
                if (followingObjects[i][@"to"] != nil) {
                    [followingUsers addObject:followingObjects[i][@"to"]];
                    self.following = [NSArray arrayWithArray:followingUsers];
                }
            }
            //query users public closets
            PFQuery *itemQuery = [PFQuery queryWithClassName:@"Item"];
            [itemQuery whereKey:@"isInPrivateCloset" notEqualTo:@YES];
            [itemQuery whereKey:@"owner" containedIn:self.following];
            [itemQuery includeKey:@"createdAt"];
            [itemQuery orderByDescending:@"createdAt"];
            itemQuery.limit = 5;
            [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
                self.newsFeedItems = items;
                if ([items count] == 0) {
                    self.tableView.hidden = YES;
                    self.findPeopleToFollowButton.hidden = NO;
                    self.findPeopleToFollowButton.enabled = YES;
                    self.notFollowingLabel.hidden = NO;
                    self.notFollowingLabel.text = @"Not following anyone";
                    [self.findPeopleToFollowButton setTitle:@"Find people to Follow" forState:UIControlStateNormal];
                    [self.findPeopleToFollowButton addTarget:self action:@selector(findPeopleToFollow:) forControlEvents:UIControlEventTouchUpInside];
                    self.refreshButton.hidden = NO;
                    self.refreshButton.enabled = YES;
                    [self.refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
                    [self.refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
                }
                else{
                    self.tableView.hidden = NO;
                    self.findPeopleToFollowButton.hidden = YES;
                    self.findPeopleToFollowButton.enabled = NO;
                    self.notFollowingLabel.hidden = YES;
                    self.refreshButton.hidden = YES;
                    self.refreshButton.enabled = NO;
                }
                [self.tableView reloadData];
            }];
        }];
        //query the user class for all of the items that the user has liked
        PFUser *currentUser = [PFUser currentUser];
        PFRelation *itemsLikedRelation = [currentUser relationForKey:@"itemsLiked"];
        PFQuery *itemsLikeQuery = [itemsLikedRelation query];
        //mutable array to keep track of items the current user has liked.
        NSMutableArray *itemsLikedMut = [NSMutableArray array];
        [itemsLikeQuery findObjectsInBackgroundWithBlock:^(NSArray *itemsLiked, NSError *error) {
            [itemsLikedMut addObjectsFromArray:itemsLiked];
            self.itemsLiked = [NSArray arrayWithArray:itemsLikedMut];
            [self.tableView reloadData];
        }];
    }

    //set title
     self.navigationItem.title = @"Newsfeed";

    //Register nib for cell
    UINib *cellNib = [UINib nibWithNibName:@"CLOSNewsFeedTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CLOSNewsFeedTableViewCell"];
    
    //Refresh Control
    //add a refresh control to allow refreshing of data - no other time is the data refreshed
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    
    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Loading..."];
    [refreshString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [refreshString length])];
    [refreshString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"STHeitiTC-Medium" size:13.0] range:NSMakeRange(0, [refreshString length])];
    refreshControl.attributedTitle = refreshString;
    
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

}
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //set up the cells
    CLOSNewsFeedTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"CLOSNewsFeedTableViewCell" forIndexPath:indexPath];
    PFObject *currentCellItem = ((PFObject *)(self.newsFeedItems[indexPath.section]));
    cell.itemName.text = currentCellItem[@"name"];
    cell.itemName.textColor = [UIColor whiteColor];
    
    // make buttons rounded
    cell.viewLikeButton.layer.cornerRadius = 8.0f;
    cell.borrowButton.layer.cornerRadius = 8.0f;
    cell.likeButton.layer.cornerRadius = 8.0f;
    cell.unLikeButton.layer.cornerRadius = 8.0f;
    
    //make button grey background
    cell.borrowButton.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.7];
    
    NSString *likeString;
    NSInteger intergerLikes = [(NSNumber *)currentCellItem[@"likes"] integerValue];
    if (intergerLikes == 1) {
       likeString = @"1 like";
        //set up viewLikeButton
        cell.viewLikeButton.enabled = YES;
        cell.viewLikeButton.tag = indexPath.section;
        cell.viewLikeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [cell.viewLikeButton addTarget:self action:@selector(viewLikes:) forControlEvents:UIControlEventTouchUpInside];
        cell.viewLikeButton.backgroundColor = [UIColor clearColor];
        [cell.viewLikeButton setTitle:likeString forState:UIControlStateNormal];
    }
    else if (intergerLikes != 0){
        likeString = [NSString stringWithFormat:@"%@ likes",currentCellItem[@"likes"]];
        //set up viewLikeButton
        cell.viewLikeButton.enabled = YES;
        cell.viewLikeButton.tag = indexPath.section;
        cell.viewLikeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [cell.viewLikeButton addTarget:self action:@selector(viewLikes:) forControlEvents:UIControlEventTouchUpInside];
        cell.viewLikeButton.backgroundColor = [UIColor clearColor];
        [cell.viewLikeButton setTitle:likeString forState:UIControlStateNormal];
    }
    else{
        likeString = @"0 likes";
        cell.viewLikeButton.enabled = NO;
        cell.likeButton.enabled = YES;
        cell.viewLikeButton.backgroundColor = [UIColor clearColor];
        [cell.viewLikeButton setTitle:likeString forState:UIControlStateNormal];
        cell.viewLikeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

    }
    //if the user has not liked any items then enable the like button for everything
    if (!self.itemsLiked) {
        
        cell.likeButton.enabled = YES;
        cell.likeButton.tag = indexPath.section;
        [cell.likeButton addTarget:self action:@selector(likePressed:) forControlEvents:UIControlEventTouchUpInside];
        
        //set up unlike button
        cell.unLikeButton.enabled = NO;
        cell.unLikeButton.hidden = YES;
        
    }
    //if the user has liked items check if this item has already been liked by the current user
    else{
        //check if the person has already liked the item by filtering using NSPredicate
        NSMutableArray *itemsLikedMutable = [NSMutableArray arrayWithArray:self.itemsLiked];
        NSPredicate *itemPredicate = [NSPredicate predicateWithFormat:@"objectId == %@", ((PFObject *)(self.newsFeedItems[indexPath.section])).objectId];
        NSArray *filteredItemsArray = [itemsLikedMutable filteredArrayUsingPredicate:itemPredicate];
        //if the person has already liked the item
        if ([filteredItemsArray count] > 0) {
            //if item is in the itemsLiked array, then disable the like button
            cell.likeButton.enabled = NO;
            cell.likeButton.hidden = YES; //hide the like button
            cell.unLikeButton.hidden = NO;
            cell.unLikeButton.enabled = YES;
            cell.unLikeButton.tag = indexPath.section;
            [cell.unLikeButton addTarget:self action:@selector(unlikePressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        else{
            //if the user has not liked the item
            cell.likeButton.enabled = YES;
            cell.likeButton.hidden = NO;
            [cell.likeButton addTarget:self action:@selector(likePressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.likeButton.tag = indexPath.section;
            cell.unLikeButton.hidden = YES;
            cell.unLikeButton.enabled = NO;
        }
    }
    //configure borrow button
    cell.borrowButton.enabled = YES;
    [cell.borrowButton setTitle:@"Borrow" forState:UIControlStateNormal];
    cell.borrowButton.tag = indexPath.section;
    [cell.borrowButton addTarget:self action:@selector(borrow:) forControlEvents:UIControlEventTouchUpInside];

    //Get the item image
    PFFile *itemImageFile = self.newsFeedItems[indexPath.section][@"itemImage"];
    [itemImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        cell.itemImage.image = image;
    }];
    return cell;
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == [self.newsFeedItems count] -2) {
        [self loadMoreData];
    }
}
-(void)loadMoreData
{
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable) { // only query if internet is reachable
        PFQuery *itemQuery = [PFQuery queryWithClassName:@"Item"];
        [itemQuery whereKey:@"isInPrivateCloset" notEqualTo:@YES];
        [itemQuery whereKey:@"owner" containedIn:self.following];
        [itemQuery includeKey:@"createdAt"];
        [itemQuery orderByDescending:@"createdAt"];
        itemQuery.skip = [self.newsFeedItems count];
        itemQuery.limit = 5;
        [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
            if (!error) {
                NSInteger lastSection = [self.newsFeedItems count];
                self.newsFeedItems = [self.newsFeedItems arrayByAddingObjectsFromArray:items];
                
                //for each item in items prepare item for insertion
                NSInteger counter = [items count];
                NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
                [indexSet addIndexesInRange:NSMakeRange(lastSection, counter)];
                [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationTop];
            }
            
        }];
    }

}
-(IBAction)handleRefresh:(id)sender
{
    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable) { // only query if internet is reachable
        PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
        [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
        [followQuery includeKey:@"to"];
        NSMutableArray *followingUsers = [NSMutableArray array];
        //Create mutable array to add items for news feed
        NSMutableArray *newsFeedItemsMut = [NSMutableArray array];
        [followQuery findObjectsInBackgroundWithBlock:^(NSArray *followingObjects, NSError *error) {
            //gives all users that you are following
            for (int i = 0; i < [followingObjects count]; i++) {
                //Make sure that we haven't deleted the user from parse
                if (followingObjects[i][@"to"] != nil) {
                    [followingUsers addObject:followingObjects[i][@"to"]];
                    self.following = [NSArray arrayWithArray:followingUsers];
                }
            }
            //query users public closets
            PFQuery *itemQuery = [PFQuery queryWithClassName:@"Item"];
            [itemQuery whereKey:@"isInPrivateCloset" equalTo:@NO];
            [itemQuery whereKey:@"owner" containedIn:followingUsers];
            [itemQuery includeKey:@"createdAt"];
            [itemQuery orderByDescending:@"createdAt"];
            [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
                [newsFeedItemsMut addObjectsFromArray:items];
                [newsFeedItemsMut sortUsingComparator:^NSComparisonResult(id date1, id date2) {
                    NSDate *dateOne = (((PFObject *)(date1)).createdAt);
                    NSDate *dateTwo =(((PFObject *)(date2)).createdAt);
                    //negative sign to order items in descending order
                    return -[dateOne compare:dateTwo];
                }];
                if ([items count] == 0) {
                    self.tableView.hidden = YES;
                    self.findPeopleToFollowButton.hidden = NO;
                    self.findPeopleToFollowButton.enabled = YES;
                    self.notFollowingLabel.hidden = NO;
                    self.notFollowingLabel.text = @"Not following anyone";
                    [self.findPeopleToFollowButton setTitle:@"Find people to Follow" forState:UIControlStateNormal];
                    [self.findPeopleToFollowButton addTarget:self action:@selector(findPeopleToFollow:) forControlEvents:UIControlEventTouchUpInside];
                    self.refreshButton.hidden = NO;
                    self.refreshButton.enabled = YES;
                    [self.refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
                    [self.refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
                }
                else{
                    self.tableView.hidden = NO;
                    self.findPeopleToFollowButton.hidden = YES;
                    self.findPeopleToFollowButton.enabled = NO;
                    self.notFollowingLabel.hidden = YES;
                    self.refreshButton.hidden = YES;
                    self.refreshButton.enabled = NO;
                }
                self.newsFeedItems = [NSArray arrayWithArray:newsFeedItemsMut];
                [self.tableView reloadData];
                [(UIRefreshControl *)sender endRefreshing];
            }];
        }];
        
        //query the user class for all of the items that the user has liked
        PFUser *currentUser = [PFUser currentUser];
        PFRelation *itemsLikedRelation = [currentUser relationForKey:@"itemsLiked"];
        PFQuery *itemsLikeQuery = [itemsLikedRelation query];
        //mutable array to keep track of items the current user has liked.
        NSMutableArray *itemsLikedMut = [NSMutableArray array];
        [itemsLikeQuery findObjectsInBackgroundWithBlock:^(NSArray *itemsLiked, NSError *error) {
            [itemsLikedMut addObjectsFromArray:itemsLiked];
            self.itemsLiked = [NSArray arrayWithArray:itemsLikedMut];
            [self.tableView reloadData];
        }];
    }
    else { // if no internet, end the refresh control
        [(UIRefreshControl *)sender endRefreshing];
    }
}

-(IBAction)likePressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.enabled = NO;
    button.hidden = YES;

    PFObject *likeItem = self.newsFeedItems[button.tag];
    [likeItem incrementKey:@"likes"];
    PFRelation *likeRelation = [likeItem relationForKey:@"likeUser"];
    [likeRelation addObject:[PFUser currentUser]];
    [likeItem saveInBackground];
    
    //update User class on parse for user to keep track of items liked.
    PFUser *currentUser = [PFUser currentUser];
    PFRelation *userLikeRelation = [currentUser relationForKey:@"itemsLiked"];
    [userLikeRelation addObject:likeItem];
    [currentUser saveInBackground];
    //add the item just liked to the array of items liked to keep track of it.
    self.itemsLiked = [self.itemsLiked arrayByAddingObject:likeItem];

    //Add push notification
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"username" equalTo:likeItem[@"ownerUsername"]];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    NSString *message = [NSString stringWithFormat:@"%@ liked your item %@", currentUser.username, likeItem[@"name"]];
    [push setMessage:message];
    [push sendPushInBackground];
    [self.tableView reloadData];
}
-(IBAction)unlikePressed:(id)sender
{
    UIButton *button = (UIButton *)sender;
    button.enabled = NO;
    //Remove User from array of liked users on parse
    PFObject *likeItem = self.newsFeedItems[button.tag];
    //decrement number of likes
    [likeItem incrementKey:@"likes" byAmount:@-1];
    PFRelation *likeRelation = [likeItem relationForKey:@"likeUser"];
    [likeRelation removeObject:[PFUser currentUser]];
    [likeItem saveInBackground];
    
    //update User class on parse for user to keep track of items liked.
    PFUser *currentUser = [PFUser currentUser];
    PFRelation *userLikeRelation = [currentUser relationForKey:@"itemsLiked"];
    [userLikeRelation removeObject:likeItem];
    [currentUser saveInBackground];
    //remove the item just liked to the array of items liked to keep track of it.
    self.itemsLiked = [self.itemsLiked filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"objectId != %@", likeItem.objectId]];
    [self.tableView reloadData];
}

-(void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    //go to the individualItemvc
    CLOSItemViewController *itemvc = [[CLOSItemViewController alloc] init];
    itemvc.item = ((PFObject *)self.newsFeedItems[indexPath.section]);
    [self.navigationController pushViewController:itemvc animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //only one row per section
    return 1;
}
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
     return [self.newsFeedItems count];
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 60.0;
}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CLOSNewsFeedHeaderView *headerView = [[CLOSNewsFeedHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.window.frame.size.width, 60.0)];
    //set location button
    NSArray *itemLocationArray = self.newsFeedItems[section][@"locationArray"];
    //if the item has a location
    if (itemLocationArray) {
        //create a location button if there is a location
        headerView.locationButton.tag = section;
        headerView.locationButton.hidden = NO;
        headerView.locationButton.enabled = YES;
        [headerView.locationButton addTarget:self action:@selector(itemLocation:) forControlEvents:UIControlEventTouchUpInside];
        
        //Format the location array to a string
        if ([itemLocationArray count] > 1) {
             NSArray *locationArrayWithoutCountry = [itemLocationArray subarrayWithRange:NSMakeRange(0, [itemLocationArray count]-1)];
            NSString *locationString = [[locationArrayWithoutCountry valueForKey:@"description"] componentsJoinedByString:@", "];
            [headerView.locationButton setAttributedTitle:[[NSAttributedString alloc] initWithString:locationString attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}]
                                      forState:UIControlStateNormal];
        }
        else{
            //if the location array only contains 1 item, which would be the country, then just display the country
            NSString *locationString = [[itemLocationArray valueForKey:@"description"] componentsJoinedByString:@", "];
            [headerView.locationButton setAttributedTitle:[[NSAttributedString alloc] initWithString:locationString attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}]
                                      forState:UIControlStateNormal];
        }
        
        //add username with location button
        headerView.usernameButton.tag = section;
        headerView.usernameButton.hidden = NO;
        headerView.usernameButton.enabled = YES;
        [headerView.usernameButton addTarget:self action:@selector(itemOwner:) forControlEvents:UIControlEventTouchUpInside]; //or should it be TouchDown
        if (self.newsFeedItems[section][@"ownerUsername"] != nil)
            [headerView.usernameButton setAttributedTitle:[[NSAttributedString alloc] initWithString:self.newsFeedItems[section][@"ownerUsername"] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}]
                                      forState:UIControlStateNormal];
    }
    else {
        //add username with location button in the center
        headerView.usernameButton.tag = section;
        headerView.usernameButton.hidden = NO;
        [headerView.usernameButton addTarget:self action:@selector(itemOwner:) forControlEvents:UIControlEventTouchUpInside]; //or should it be TouchDown
        if (self.newsFeedItems[section][@"ownerUsername"] != nil)
            [headerView.usernameButton setAttributedTitle:[[NSAttributedString alloc] initWithString:self.newsFeedItems[section][@"ownerUsername"] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}]
                                      forState:UIControlStateNormal];
    }

    //format time
    NSAttributedString *timeString;
    
    NSDate *createdDate =((PFObject *)(self.newsFeedItems[section])).createdAt; //this is the reference date
    NSDate *now = [NSDate date];
    NSTimeInterval interval = [now timeIntervalSinceDate:createdDate];
    long seconds = lroundf(interval);
    if (seconds < NUM_OF_SEC_IN_MIN) {
        timeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"     %ld s", seconds] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}] ;
    }
    //if it was more than 60 seconds ago, switch to minutes
    else if (seconds >= NUM_OF_SEC_IN_MIN && seconds < NUM_OF_SEC_IN_HOUR) {
        long mins = seconds / NUM_OF_SEC_IN_MIN;
        //set it equal to mins
        timeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"     %ld m", mins] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}] ;
    }
    //if it was more than 60 minutes ago switch to hours
    //86400.0 is seconds in a day
    else if (seconds >= NUM_OF_SEC_IN_HOUR && seconds < NUM_OF_SEC_IN_DAY){
        long hours = seconds / NUM_OF_SEC_IN_HOUR;
        //set it equal to hours
        timeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"     %ld h", hours] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}] ;
    }
    //if it was more than 24 hours ago switch to days
    //604800.0 is seconds in a week
    else if (seconds >= NUM_OF_SEC_IN_DAY && seconds < NUM_OF_SEC_IN_WEEK){
        long days = seconds/ NUM_OF_SEC_IN_DAY;
        //set it equal to days
        timeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"     %ld d", days] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}] ;
    }
    //if it was more than 7 days ago switch to weeks
    else if (seconds >= NUM_OF_SEC_IN_WEEK){
        long weeks = seconds / NUM_OF_SEC_IN_WEEK;
        timeString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"     %ld w", weeks] attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}] ;
    }
    
    //add time item was created label
    [headerView.timeLabel setAttributedText:timeString];
    //add profile picture
    //query for profile picture
    PFRelation *userRelation = [self.newsFeedItems[section] relationForKey:@"owner"];
    PFQuery *itemOwnerQuery = [userRelation query];
    [itemOwnerQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //Get the item image
        PFFile *profileImageFile = object[@"profilePicture"];
        [profileImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            UIImage *image = [UIImage imageWithData:data];
            headerView.profileView.image = image;
            headerView.profileView.tag = section;
            //TODO: got to profile when click on profile picture
        }];
    }];
    return headerView;
}

-(void)itemLocation:(UIButton *)button
{
    //query for item location
    //go to mapvc and display a pin for the location of the item
    self.view.userInteractionEnabled = NO;
    CLOSMapPopoverViewController *mapPopvc = [[CLOSMapPopoverViewController alloc] init];
    NSString *locationStringWithCountry = [[self.newsFeedItems[button.tag][@"locationArray"] valueForKey:@"description"] componentsJoinedByString:@", "];
    NSMutableArray *itemLocation = [NSMutableArray arrayWithObject:locationStringWithCountry];
    mapPopvc.stringAddressesToAdd = itemLocation;
    mapPopvc.item = (PFObject *)(self.newsFeedItems[button.tag]);
    mapPopvc.following = self.following;
    mapPopvc.locationArray = self.newsFeedItems[button.tag][@"locationArray"];
    [self.navigationController pushViewController:mapPopvc animated:YES];
}
-(void)itemOwner:(id)sender
{
    [self.view endEditing:YES];
    UIButton *button = (UIButton *)sender;
    self.view.userInteractionEnabled = NO;
    //query the item's owner
    PFRelation *itemOwnerRelation = [self.newsFeedItems[button.tag] relationForKey:@"owner"];
    PFQuery *itemOwnerQuery = [itemOwnerRelation query];
    [itemOwnerQuery getFirstObjectInBackgroundWithBlock:^(PFObject *owner, NSError *error) {
        //go to the item owner's profile
        CLOSProfileViewController *profilevc = [[CLOSProfileViewController alloc] init];
        profilevc.user = ((PFUser *)(owner));
        profilevc.profileImage =((PFUser *)(owner))[@"profilePicture"];
        [self.navigationController pushViewController:profilevc animated:YES];
    }];
}
-(void)viewLikes:(id)sender
{
    UIButton *button = (UIButton *)sender;
    [self.view endEditing:YES];
    self.view.userInteractionEnabled = NO;
    PFRelation *likeUserRelation = [self.newsFeedItems[button.tag] relationForKey:@"likeUser"];
    PFQuery *likeUserQuery = [likeUserRelation query];
    [likeUserQuery findObjectsInBackgroundWithBlock:^(NSArray *likeUsers, NSError *error) {
        if (!error) {
            if ([likeUsers count] != 0) {
                //go to likesvc
                CLOSLikesViewController *likesvc = [[CLOSLikesViewController alloc] init];
                likesvc.likeUsers = likeUsers;
                //likesvc.following = self.following;
                [self.navigationController pushViewController:likesvc animated:YES];
            }

        }
        else{
            NSLog(@"%@", error);
        }
    }];
}
-(void)borrow:(id)sender
{
    self.view.userInteractionEnabled = NO;
    UIButton *button = (UIButton *)sender;
    NSString *itemName = self.newsFeedItems[button.tag][@"name"];
    PFObject *item = self.newsFeedItems[button.tag];
    //query the item owner and pass the information to the borrowvc
    PFRelation *ownerRelation = [self.newsFeedItems[button.tag] relationForKey:@"owner"];
    PFQuery *ownerQuery = [ownerRelation query];
    [ownerQuery getFirstObjectInBackgroundWithBlock:^(PFObject *owner, NSError *error) {
        CLOSBorrowViewController *borrowvc = [[CLOSBorrowViewController alloc] init];
        borrowvc.itemName = itemName;
        borrowvc.item = item;
        borrowvc.itemOwner = ((PFUser *)(owner));
        [self presentViewController:borrowvc animated:YES completion:nil];
    }];
}
-(void)findPeopleToFollow:(id)sender
{
    self.view.userInteractionEnabled = NO;
    //go to the search vc tab
    [self.tabBarController setSelectedIndex:1];
}
-(void)refresh:(id)sender
{
    //hide buttons
    //display table view
    self.findPeopleToFollowButton.hidden = YES;
    self.notFollowingLabel.hidden = YES;
    self.following = nil;

    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable) { // only query if internet is reachable
        PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
        [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
        [followQuery whereKey:@"verificationState" equalTo:@(approved)];
        [followQuery includeKey:@"to"];
        NSMutableArray *followingUsers = [NSMutableArray array];
        //Create mutable array to add items for news feed
        [followQuery findObjectsInBackgroundWithBlock:^(NSArray *followingObjects, NSError *error) {
            //gives all users that you are following
            for (int i = 0; i < [followingObjects count]; i++) {
                //Make sure that we haven't deleted the user from parse
                if (followingObjects[i][@"to"] != nil) {
                    [followingUsers addObject:followingObjects[i][@"to"]];
                    self.following = [NSArray arrayWithArray:followingUsers];
                }
            }
            //query users public closets
            PFQuery *itemQuery = [PFQuery queryWithClassName:@"Item"];
            [itemQuery whereKey:@"isInPrivateCloset" notEqualTo:@YES];
            [itemQuery whereKey:@"owner" containedIn:self.following];
            [itemQuery includeKey:@"createdAt"];
            [itemQuery orderByDescending:@"createdAt"];
            itemQuery.limit = 5;
            [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
                self.newsFeedItems = items;
                if ([items count] == 0) {
                    self.tableView.hidden = YES;
                    self.findPeopleToFollowButton.hidden = NO;
                    self.findPeopleToFollowButton.enabled = YES;
                    self.notFollowingLabel.hidden = NO;
                    self.notFollowingLabel.text = @"Not following anyone";
                    [self.findPeopleToFollowButton setTitle:@"Find people to Follow" forState:UIControlStateNormal];
                    [self.findPeopleToFollowButton addTarget:self action:@selector(findPeopleToFollow:) forControlEvents:UIControlEventTouchUpInside];
                    self.refreshButton.hidden = NO;
                    self.refreshButton.enabled = YES;
                    [self.refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
                    [self.refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
                }
                else{
                    self.tableView.hidden = NO;
                    self.findPeopleToFollowButton.hidden = YES;
                    self.findPeopleToFollowButton.enabled = NO;
                    self.notFollowingLabel.hidden = YES;
                    self.refreshButton.hidden = YES;
                    self.refreshButton.enabled = NO;
                }
                [self.tableView reloadData];
            }];
        }];
        //query the user class for all of the items that the user has liked
        PFUser *currentUser = [PFUser currentUser];
        PFRelation *itemsLikedRelation = [currentUser relationForKey:@"itemsLiked"];
        PFQuery *itemsLikeQuery = [itemsLikedRelation query];
        //mutable array to keep track of items the current user has liked.
        NSMutableArray *itemsLikedMut = [NSMutableArray array];
        [itemsLikeQuery findObjectsInBackgroundWithBlock:^(NSArray *itemsLiked, NSError *error) {
            [itemsLikedMut addObjectsFromArray:itemsLiked];
            self.itemsLiked = [NSArray arrayWithArray:itemsLikedMut];
            [self.tableView reloadData];
        }];
    }



}
@end
