//
//  CLOSPendingFollowRequestsTableViewController.m
//  seeFollowRequests
//
//  Created by Rachel Pinsker on 8/4/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSPendingFollowRequestsTableViewController.h"
#import "CLOSPendingFollowRequestsTableViewCell.h"
#import "CLOSProfileViewController.h"
#import <Parse/Parse.h>

@interface CLOSPendingFollowRequestsTableViewController ()

typedef NS_ENUM (NSInteger, verificationState) {
    requested = 0,
    approved = 1,
    rejected = 2,
    blocked = 2
};

@end

@implementation CLOSPendingFollowRequestsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UINib *cellNib = [UINib nibWithNibName:@"CLOSPendingFollowRequestsTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:@"PendingFollowRequestsTableViewCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.pendingRequests count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSPendingFollowRequestsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PendingFollowRequestsTableViewCell" forIndexPath:indexPath];
    
    // get the follow request
   PFObject *follow = self.pendingRequests[indexPath.row];
    
    // get the display objects from the cell
    UILabel *usernameLabel = cell.usernameLabel;
    UIButton *rejectButton = cell.rejectButton;
    UIButton *acceptButton = cell.acceptButton;
    
    // set the text to be the other user's username
    usernameLabel.text = ((PFUser *)follow[@"from"]).username;
    
    if ([follow[@"verificationState"] isEqual:[NSNumber numberWithInteger:requested]]) { // in requested state
        // add actions for reject and accept buttons
        [rejectButton addTarget:self
                         action:@selector(reject:)
               forControlEvents:UIControlEventTouchUpInside];
        rejectButton.tag = indexPath.row;
        
        [acceptButton addTarget:self
                         action:@selector(accept:)
               forControlEvents:UIControlEventTouchUpInside];
        acceptButton.tag = indexPath.row;
    }
    else if ([follow[@"verificationState"] isEqual:[NSNumber numberWithInteger:approved]]) { // was just approved
        [acceptButton setTitle:@"Accepted" forState:UIControlStateNormal];
        acceptButton.enabled = NO;
        rejectButton.hidden = YES;
    }
    else if ([follow[@"verificationState"] isEqual:[NSNumber numberWithInteger:rejected]]) { // was just rejected
        [rejectButton setTitle:@"Rejected" forState:UIControlStateNormal];
        rejectButton.enabled = NO;
        acceptButton.hidden = YES;
    }
    
    // Configure the cell...
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *follow = self.pendingRequests[indexPath.row];
    PFUser *otherUser = follow[@"from"];
    CLOSProfileViewController *profilevc = [[CLOSProfileViewController alloc] init];
    profilevc.user = otherUser;
    
    [self.navigationController pushViewController:profilevc animated:YES];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

- (void) accept: (id) sender
{
    // accept the follow request
    UIButton *acceptButton = (UIButton *) sender;
    PFObject *followToAccept = self.pendingRequests[acceptButton.tag];
    followToAccept[@"verificationState"] = [NSNumber numberWithInteger:approved];
    [followToAccept saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self.tableView reloadData];
    }];
    
}

- (void) reject: (id) sender
{
    UIButton *rejectButton = (UIButton *) sender;
    PFObject *followToReject = self.pendingRequests[rejectButton.tag];
    followToReject[@"verificationState"] = [NSNumber numberWithInteger:rejected];
    [followToReject deleteInBackground];
    [self.tableView reloadData];
}




@end
