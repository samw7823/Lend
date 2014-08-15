//
//  CLOSLikesViewController.m
//  myCloset
//
//  Created by Samantha Wiener on 8/4/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSLikesViewController.h"
#import "CLOSProfileViewController.h"
#import "CLOSSearchTableViewCell.h"
#import <Parse/Parse.h>

@interface CLOSLikesViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSArray *followingLikeUsers;
@property (nonatomic, copy) NSArray *notFollowingLikeUsers;
@property (nonatomic, copy) NSArray *following;
typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@end

@implementation CLOSLikesViewController

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
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    if (self.isGroupMembers) {
        self.navigationItem.title = @"Group Members";
    }
    else {
        //get number of likes
        NSInteger numOfLikes = [self.likeUsers count];
        NSString *likeTitle = [NSString stringWithFormat:@"%ld likes", (long)numOfLikes];
        self.navigationItem.title = likeTitle;
    }
    
    //check if the current user has liked the item
    if ([[self.likeUsers valueForKey:@"objectId"] containsObject:((PFObject *)[PFUser currentUser]).objectId]){
        //if the current user has, then remove the current user from the like user array
        NSMutableArray *likeUsersMut = self.likeUsers.mutableCopy;
        for (PFUser *user in self.likeUsers) {
            if ([user.objectId isEqual:[PFUser currentUser].objectId]) {
                [likeUsersMut removeObject:user];
                break;
            }
        }
        //then insert the current user back into the array at index 0
        [likeUsersMut insertObject:[PFUser currentUser] atIndex:0];
        self.likeUsers = [NSArray arrayWithArray:likeUsersMut];
    }
    
    //register the reuseable cell
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    //user the searchtableview as reuseable cell
     UINib *cellNib = [UINib nibWithNibName:@"CLOSSearchTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];

}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //query for following
    PFQuery *followQuery = [PFQuery queryWithClassName:@"Follow"];
    [followQuery whereKey:@"from" equalTo:[PFUser currentUser]];
    [followQuery includeKey:@"to"];
    [followQuery findObjectsInBackgroundWithBlock:^(NSArray *followingObjects, NSError *error) {
        //gives all users that you are following
        self.following = followingObjects;
        [self.tableView reloadData];
    }];
    if (self.isGroupMembers) {
        self.navigationItem.title = @"Group Members";
    }
    else {
        //get number of likes
        NSInteger numOfLikes = [self.likeUsers count];
        NSString *likeTitle = [NSString stringWithFormat:@"%ld likes", (long)numOfLikes];
        self.navigationItem.title = likeTitle;
    }

}
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSSearchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell" forIndexPath:indexPath];
    //clear all fields that wait for loading
    cell.image.image = nil;
    cell.itemDescription.text = @"";
    cell.optionsButton.hidden = YES;
    cell.backgroundColor = [UIColor clearColor];
    cell.itemName.textColor = [UIColor whiteColor];
    cell.itemName.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    NSArray *likeUsersArray = [NSArray arrayWithArray:self.likeUsers];
    PFUser *likeUser = likeUsersArray[indexPath.row];
    
    //check if the current user has liked the item and check that the row is 0Upd
    if (indexPath.row == 0 && [[PFUser currentUser][@"username"] isEqualToString:likeUser[@"username"]]) {
        NSString *likeUsername = [NSString stringWithFormat:@"%@ (you)", [PFUser currentUser][@"username"]];
        cell.itemName.text = likeUsername;
    }
    else{
        NSString *likeUsername = [NSString stringWithFormat:@"%@", likeUser.username];
        cell.itemName.text = likeUsername;
    }
    PFFile *imageFile = likeUser[@"profilePicture"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        cell.image.image = image;
    }];
    //only show follow button if the user is not already following this person
    if ([self.following count] != 0) {
        UIButton *followButton = [[UIButton alloc] initWithFrame:CGRectMake(200, 5, 80, 40)];
        NSArray *followingUsernames = [self.following valueForKeyPath:@"to.username"];
        if (![followingUsernames containsObject:likeUser[@"username"]]){
            if (![likeUser[@"username"] isEqualToString:[PFUser currentUser][@"username"]]) {
                followButton.enabled = YES;
                followButton.hidden = NO;
                followButton.tag = indexPath.row;
                followButton.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.6];
                [followButton setTitle:@"Follow" forState:UIControlStateNormal];
                followButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
                [followButton addTarget:self action:@selector(follow:) forControlEvents:UIControlEventTouchUpInside];
                [cell addSubview:followButton];
            }
            else{
                followButton.hidden = YES;
                followButton.enabled = NO;
                [cell addSubview:followButton];
            }
            
        }
        else{
            followButton.hidden = YES;
            followButton.enabled = NO;
            [cell addSubview:followButton];
        }
    }
    
    return cell;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.likeUsers count];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    //go to user's profile
    CLOSProfileViewController *profilevc = [[CLOSProfileViewController alloc] init];
    profilevc.user = self.likeUsers[indexPath.row];
    [self.navigationController pushViewController:profilevc animated:YES];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}
-(void)follow:(id)sender
{
    //get current user
    PFUser *currentUser = [PFUser currentUser];
    UIButton *button = (UIButton *)sender;
    button.enabled = NO;
    button.hidden = YES;
    PFUser *selectedUser = self.likeUsers[button.tag];
    PFObject *follow = [PFObject objectWithClassName:@"Follow"];
    [follow setObject:selectedUser forKey:@"to"];
    [follow setObject:currentUser forKey:@"from"];
    
    if ([selectedUser[@"isPrivate"]  isEqual: @YES]) {
        follow[@"verificationState"] = [NSNumber numberWithInteger:requested];
    }
    else {
        follow[@"verificationState"] = [NSNumber numberWithInteger:approved];

    }
    [follow saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        //update the array before you reload data
        NSMutableArray *followingMut = self.following.mutableCopy;
        [followingMut addObject:follow];
        self.following = [NSArray arrayWithArray:followingMut];

        [self.tableView reloadData];
    }];
    //Add push notification
    PFQuery *pushQuery = [PFInstallation query];
    [pushQuery whereKey:@"username" equalTo:selectedUser.username];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    NSString *message;
    if ([currentUser[@"isPrivate"] isEqual:@YES])
        message = [NSString stringWithFormat:@"%@ requested to follow you", currentUser.username];
    else{
        message = [NSString stringWithFormat:@"%@ started following you", currentUser.username];

    }
    [push setMessage:message];
    [push sendPushInBackground];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
