//
//  CLOSInventoryViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/15/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSInventoryViewController.h"
#import <Parse/Parse.h>
#import "CLOSItemViewController.h"
#import "CLOSProfileViewController.h"
#import "CLOSInventoryTableViewCell.h"
#import "CLOSTransactionViewController.h"

@interface CLOSInventoryViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UISegmentedControl *switchController;
@property (weak, nonatomic) IBOutlet UITableView *requestedOfYouTableView;
@property (weak, nonatomic) IBOutlet UITableView *requestedTableView;

@property (nonatomic, copy) NSArray *requestedOfYouTransactions;
@property (nonatomic, copy) NSArray *requestedTransactions;
@property (nonatomic) NSUInteger *selectedIndex;
@property (weak, nonatomic) IBOutlet UILabel *loadinglabel;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

typedef NS_ENUM(NSInteger, transactionStates)  {
    requested = 1,
    accepted = 2,
    rejected = 3,
    borrowed = 4,
    returned = 5,
    expired = 6,
    cancelled = 7
};

@end

@implementation CLOSInventoryViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationItem.title = @"Inventory";

    
    [self.switchController setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0]} forState:UIControlStateNormal];
    
    //Set up switch controller
    [self.switchController addTarget:self action:@selector(changedSwitch) forControlEvents:UIControlEventValueChanged];
    
    //Register nib
    UINib *cellNib = [UINib nibWithNibName:@"CLOSInventoryTableViewCell" bundle:nil];
    [self.requestedOfYouTableView registerNib:cellNib forCellReuseIdentifier:@"CLOSInventoryTableViewCell"];
    [self.requestedTableView registerNib:cellNib forCellReuseIdentifier:@"CLOSInventoryTableViewCell"];
    
    //Set up refresh control for requested of you table
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Loading..."];
    [refreshString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [refreshString length])];
    [refreshString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"STHeitiTC-Medium" size:13.0] range:NSMakeRange(0, [refreshString length])];
    refreshControl.attributedTitle = refreshString;
    
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.requestedOfYouTableView addSubview:refreshControl];

    //refresh control for requested table
    UIRefreshControl *requestedRefreshControl = [[UIRefreshControl alloc] init];
    requestedRefreshControl.attributedTitle = refreshString;
    
    [requestedRefreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.requestedTableView addSubview:requestedRefreshControl];

    PFQuery *transactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    
    //query for transactions - always start on items requested of you
    [transactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
    [transactionQuery includeKey:@"borrower"];
    [transactionQuery includeKey:@"item"];
    [transactionQuery orderByDescending:@"createdAt"];
    //Load initial 15 items
    transactionQuery.limit = 15;
    
    self.loadinglabel.hidden = NO;
    self.requestedOfYouTableView.hidden = YES;
    self.requestedTableView.hidden = YES;
    [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.requestedOfYouTransactions = objects;
        [self.requestedOfYouTableView reloadData];
        self.loadinglabel.hidden = YES;
        self.requestedOfYouTableView.hidden = NO;
    }];
    //Add invisible footer to remove separators at the end
    self.requestedOfYouTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.requestedTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.requestedOfYouTableView) {
        return [self.requestedOfYouTransactions count];
    } else {
        return [self.requestedTransactions count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSInventoryTableViewCell *cell;
    if (tableView == self.requestedOfYouTableView) {
        cell = [self.requestedOfYouTableView dequeueReusableCellWithIdentifier:@"CLOSInventoryTableViewCell" forIndexPath:indexPath];

        PFObject *transaction = self.requestedOfYouTransactions[indexPath.row];

        //        /* make a button label that has the row of the cell selected to send as a subview of the accept/reject buttons */
        //        UILabel *buttonLabel = [[UILabel alloc] init];
        //        buttonLabel.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];

        //Items requested of you - get borrower information
        PFUser *borrower = transaction[@"borrower"];
        cell.userName.text = borrower.username;

        //get item information
        PFObject *item = transaction[@"item"];
        cell.itemName.text = item[@"name"];

        //get date information
        NSDate *borrowDate = transaction[@"plannedLendDate"];
        cell.itemDate.text = [NSString stringWithFormat:@"%@ to",[self.dateFormatter stringFromDate:borrowDate]];

        NSDate *returnDate = transaction[@"plannedReturnDate"];
        cell.returnDate.text = [self.dateFormatter stringFromDate:returnDate];


        switch ([(NSNumber *)transaction[@"transactionState"] integerValue]) {
            case accepted:
                cell.acceptButton.hidden = YES;
                cell.rejectButton.hidden = YES;
                cell.requestStatusLabel.hidden = NO;
                [cell.requestStatusLabel setText:@"ACCEPTED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:14.0f/255.0f green:114.0f/255.0f blue:0.0 alpha:.6];
                break;
            case rejected:
                cell.acceptButton.hidden = YES;
                cell.rejectButton.hidden = YES;
                cell.requestStatusLabel.hidden = NO;
                [cell.requestStatusLabel setText:@"REJECTED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:48.0f/255.0f blue:0.0 alpha:.6];
                break;
            case requested:
                if ([borrowDate compare:[NSDate date]] == NSOrderedAscending || [borrowDate compare:[NSDate date]] == NSOrderedSame) { // transaction expired so that should be set
                    transaction[@"transactionState"] = @(expired);
                    [transaction saveInBackground];
                    [cell.requestStatusLabel setText:@"EXPIRED"];
                    cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:136.0f/255.0f green:19.0f/255.0f blue:15.0f/255.0f alpha:.6];
                    cell.requestStatusLabel.hidden = NO;
                    cell.acceptButton.hidden = YES;
                    cell.rejectButton.hidden = YES;
                    break;
                }
                else {
                    cell.requestStatusLabel.hidden = YES;
                    /*Configure accept and reject buttons*/
                    [cell.acceptButton addTarget:self action:@selector(accept:) forControlEvents:UIControlEventTouchUpInside];
                    cell.acceptButton.tag = indexPath.row;

                    [cell.rejectButton addTarget:self action:@selector(reject:) forControlEvents:UIControlEventTouchUpInside];
                    cell.rejectButton.tag = indexPath.row;
                    cell.acceptButton.hidden = NO;
                    cell.acceptButton.enabled = YES;
                    cell.rejectButton.hidden = NO;
                    cell.rejectButton.enabled = YES;
                    /* end configure accept and reject buttons */
                    break;
                }
            case borrowed:
                cell.acceptButton.hidden = YES;
                cell.rejectButton.hidden = YES;
                cell.requestStatusLabel.hidden = NO;
                [cell.requestStatusLabel setText:@"BORROWED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:22.0f/255.0f green:67.0f/255.0f blue:1.0f alpha:.6];
                break;
            case returned:
                cell.acceptButton.hidden = YES;
                cell.rejectButton.hidden = YES;
                cell.requestStatusLabel.hidden = NO;
                [cell.requestStatusLabel setText:@"RETURNED"];
                cell.requestStatusLabel.backgroundColor = [UIColor clearColor];
                break;
            case expired:
                cell.acceptButton.hidden = YES;
                cell.rejectButton.hidden = YES;
                cell.requestStatusLabel.hidden = NO;
                [cell.requestStatusLabel setText:@"EXPIRED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:136.0f/255.0f green:19.0f/255.0f blue:15.0f/255.0f alpha:.6];
                break;
            case cancelled:
                cell.acceptButton.hidden = YES;
                cell.rejectButton.hidden = YES;
                cell.requestStatusLabel.hidden = NO;
                cell.requestStatusLabel.text = @"CANCELLED";
                cell.requestStatusLabel.backgroundColor = [UIColor darkGrayColor];
                break;
            default:
                break;
        }


        //Set background of cell based on update of the transaction
        if ([transaction[@"hasUpdatedForOwner"]  isEqual: @YES]) {
            cell.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.5];
            if ([(NSNumber *)transaction[@"transactionState"] integerValue] == borrowed ||
                [(NSNumber *)transaction[@"transactionState"] integerValue] == expired ||
                [(NSNumber *)transaction[@"transactionState"] integerValue] == cancelled) {
                transaction[@"hasUpdatedForOwner"] = @NO;
                [transaction saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",[self.navigationController.tabBarItem.badgeValue intValue] - 1 ];
                    if ([self.navigationController.tabBarItem.badgeValue intValue] <= 0)
                        self.navigationController.tabBarItem.badgeValue = nil;
                }];

                if ([(NSNumber *)transaction[@"transactionState"] integerValue] == borrowed) {
                    //Set a local notification to return the item 5 minutes before return date if the item has been borrowed
                    if ([(NSDate *)transaction[@"plannedReturnDate"] timeIntervalSinceNow] > 7*60) {
                        //Send a local notification 5 minutes before borrow date
                        UILocalNotification *transactionNotification = [[UILocalNotification alloc] init];
                        transactionNotification.fireDate = [(NSDate *)transaction[@"plannedReturnDate"] dateByAddingTimeInterval:-5*60];
                        transactionNotification.timeZone = [NSTimeZone defaultTimeZone];
                        transactionNotification.alertBody = [NSString stringWithFormat:@"%@ will return %@ in 5 minutes.\nTime: %@",
                                                             transaction[@"borrower"][@"username"],
                                                             transaction[@"item"][@"name"],
                                                             [self.dateFormatter stringFromDate: transaction[@"plannedReturnDate"]]];
                        transactionNotification.userInfo = @{@"transactionId": transaction.objectId};
                        [[UIApplication sharedApplication] scheduleLocalNotification:transactionNotification];
                    }
                }

            }
        } else {
            cell.backgroundColor = [UIColor clearColor];
        }

    } else { //items you have requested
        cell = [self.requestedTableView dequeueReusableCellWithIdentifier:@"CLOSInventoryTableViewCell" forIndexPath:indexPath];

        PFObject *transaction = self.requestedTransactions[indexPath.row];

        cell.acceptButton.enabled = NO;
        cell.rejectButton.enabled = NO;
        cell.acceptButton.hidden = YES;
        cell.rejectButton.hidden = YES;
        cell.requestStatusLabel.hidden = NO;

        //Set owner information
        PFUser *owner = transaction[@"owner"];
        cell.userName.text = owner[@"username"];

        //Set item information
        PFObject *item = transaction[@"item"];
        cell.itemName.text = item[@"name"];

        //Set date information
        NSDate *borrowDate = transaction[@"plannedLendDate"];
        cell.itemDate.text = [NSString stringWithFormat:@"%@ to",[self.dateFormatter stringFromDate:borrowDate]];

        NSDate *returnDate = transaction[@"plannedReturnDate"];
        cell.returnDate.text = [self.dateFormatter stringFromDate:returnDate];

        switch ([(NSNumber *)transaction[@"transactionState"] integerValue]) {
            case accepted:
                [cell.requestStatusLabel setText:@"ACCEPTED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:14.0f/255.0f green:114.0f/255.0f blue:0.0 alpha:.6];
                break;
            case rejected:
                [cell.requestStatusLabel setText:@"REJECTED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:48.0f/255.0f blue:0.0 alpha:.6];
                break;
            case borrowed:
                [cell.requestStatusLabel setText:@"BORROWED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:22.0f/255.0f green:67.0f/255.0f blue:1.0f alpha:.6];
                break;
            case returned:
                [cell.requestStatusLabel setText:@"RETURNED"];
                cell.requestStatusLabel.backgroundColor = [UIColor clearColor];
                break;
            case expired:
                [cell.requestStatusLabel setText:@"EXPIRED"];
                cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:136.0f/255.0f green:19.0f/255.0f blue:15.0f/255.0f alpha:.6];
                break;
            case cancelled:
                cell.requestStatusLabel.text = @"CANCELLED";
                cell.requestStatusLabel.backgroundColor = [UIColor darkGrayColor];
                break;
            default:
                if ([borrowDate compare:[NSDate date]] == NSOrderedAscending || [borrowDate compare:[NSDate date]] == NSOrderedSame) { // transaction expired so that should be set
                    transaction[@"transactionState"] = @(expired);
                    transaction[@"hasUpdatedForBorrower"] = @YES;
                    transaction[@"hasUpdatedForOwner"] = @YES;
                    [transaction saveInBackground];
                    [cell.requestStatusLabel setText:@"EXPIRED"];
                    cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:136.0f/255.0f green:19.0f/255.0f blue:15.0f/255.0f alpha:.6];
                    cell.requestStatusLabel.hidden = NO;
                    break;
                }
                else {
                    [cell.requestStatusLabel setText:@"PENDING"];
                    cell.requestStatusLabel.backgroundColor = [UIColor colorWithRed:177.0f/255.0f green:74.0f/255.0f blue:1.0f alpha:.6];
                    break;
                }
        }
        
        
        //Set background of cell based on update of the transaction
        if ([transaction[@"hasUpdatedForBorrower"] isEqual:@YES]) {
            cell.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.5];
            transaction[@"hasUpdatedForBorrower"] = @NO;
            [transaction saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",[self.navigationController.tabBarItem.badgeValue intValue] - 1 ];
                if ([self.navigationController.tabBarItem.badgeValue intValue] <= 0)
                    self.navigationController.tabBarItem.badgeValue = nil;
            }];
            if ([transaction[@"transactionState"] integerValue] == accepted) {
                if ([(NSDate *)transaction[@"plannedLendDate"] timeIntervalSinceNow] > 7*60) {
                    //Send a local notification 5 minutes before borrow date
                    UILocalNotification *transactionNotification = [[UILocalNotification alloc] init];
                    transactionNotification.fireDate = [(NSDate *)transaction[@"plannedLendDate"] dateByAddingTimeInterval:-5*60];
                    transactionNotification.timeZone = [NSTimeZone defaultTimeZone];
                    transactionNotification.alertBody = [NSString stringWithFormat:@"You will borrow %@ from %@ in 5 minutes.\nTime: %@\nLocation: %@\n",
                                                         transaction[@"item"][@"name"],
                                                         transaction[@"owner"][@"username"],
                                                         [self.dateFormatter stringFromDate: transaction[@"plannedLendDate"]],
                                                         transaction[@"borrowLocationString"]];
                    transactionNotification.userInfo = @{@"transactionId": transaction.objectId};
                    [[UIApplication sharedApplication] scheduleLocalNotification:transactionNotification];
                }
                
                if ([transaction[@"transactionState"] integerValue] == returned) {
                    //if returned an item (transaction is closed), weighted activity for current user increase by 5
                    [[PFUser currentUser] incrementKey:@"weightedActivity" byAmount:@5];
                    [[PFUser currentUser] saveInBackground];
                }
            }
        } else {
            cell.backgroundColor = [UIColor clearColor];
        }

    }

    return cell;
}

-(IBAction)accept:(id)sender
{
    // don't allow a double click
    self.view.userInteractionEnabled = NO;
    
    UIButton *button = (UIButton *)sender;
    
    PFObject *transaction = self.requestedOfYouTransactions[button.tag];
    transaction[@"transactionState"] = @(accepted); //Update transactionState
    transaction[@"hasUpdatedForBorrower"] = @YES;
    transaction[@"hasUpdatedForOwner"] = @NO;

    [transaction saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"error saving transaction: %@", error.userInfo[@"error"]);
            // make sure interaction is re-enabled
            self.view.userInteractionEnabled = YES;
        }
        else {
            // make sure interaction re-enabled
            self.view.userInteractionEnabled = YES;
            
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [self.navigationController.tabBarItem.badgeValue intValue] - 1 ];
            if ([self.navigationController.tabBarItem.badgeValue intValue] <= 0)
                self.navigationController.tabBarItem.badgeValue = nil;
            [self.requestedOfYouTableView reloadData];
            if ([(NSDate *)transaction[@"plannedLendDate"] timeIntervalSinceNow] > 7*60) {
                //Send a local notification 5 minutes bofore planned lend date
                UILocalNotification *transactionNotification = [[UILocalNotification alloc] init];
                transactionNotification.fireDate = [(NSDate*)transaction[@"plannedLendDate"] dateByAddingTimeInterval:-5*60];
                transactionNotification.timeZone = [NSTimeZone defaultTimeZone];
                if ([[transaction[@"message"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
                    //there isn't a message
                    transactionNotification.alertBody = [NSString stringWithFormat:@"%@ will borrow %@ in 5 minutes.\nTime:%@\nLocation: %@",
                                                         transaction[@"borrower"][@"username"],
                                                         transaction[@"item"][@"name"],
                                                         [self.dateFormatter stringFromDate: transaction[@"plannedLendDate"]],
                                                         transaction[@"borrowLocationString"]];
                else
                    //there is a message
                    transactionNotification.alertBody = [NSString stringWithFormat:@"%@ will borrow %@ in 5 minutes.\nTime:%@\nLocation: %@\nMessage: %@",
                                                         transaction[@"borrower"][@"username"],
                                                         transaction[@"item"][@"name"],
                                                         [self.dateFormatter stringFromDate: transaction[@"plannedLendDate"]],
                                                         transaction[@"borrowLocationString"],
                                                         transaction[@"message"]];
                transactionNotification.userInfo = @{@"transactionId":transaction.objectId};
                [[UIApplication sharedApplication] scheduleLocalNotification:transactionNotification];
            }
            // moving sending the push to inside of the block to make sure transaction saved successfully before sending the other user a notification
            //Query user requesting to borrow
            PFQuery *pushQuery = [PFInstallation query];
            PFUser *userToSendTo = transaction[@"borrower"];
            [pushQuery whereKey:@"username" equalTo:userToSendTo.username];
            
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query
            PFObject *item = transaction[@"item"];
            NSString *message = [NSString stringWithFormat:@"%@ accepted your request to borrow %@", [PFUser currentUser].username, item[@"name"]];
            NSDictionary *data = @{@"alert":message,@"isAcceptTransactionRequest" : @"YES"};
            [push setData:data];
            [push sendPushInBackground];

        }
    }];

}

-(IBAction)reject:(id)sender
{
    // don't allow double clicking
    self.view.userInteractionEnabled = NO;
    
    UIButton *button = (UIButton *)sender;
    
    PFObject *transaction = self.requestedOfYouTransactions[button.tag];
    transaction[@"transactionState"] = @(rejected);
    transaction[@"hasUpdatedForBorrower"] = @YES;
    transaction[@"hasUpdatedForOwner"] = @NO;

    [transaction saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"error saving transaction: %@", error.userInfo[@"error"]);
            // make sure interaction re-enabled
            self.view.userInteractionEnabled = YES;
        }
        else {
            // make sure interaction re-enabled
            self.view.userInteractionEnabled = YES;
            
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",[self.navigationController.tabBarItem.badgeValue intValue] - 1 ];
            if ([self.navigationController.tabBarItem.badgeValue intValue] <= 0)
                self.navigationController.tabBarItem.badgeValue = nil;
            [self.requestedOfYouTableView reloadData];
            
            // moving sending the push to inside of the block to make sure transaction saved successfully before sending the other user a notification
            //Send push notification
            PFQuery *pushQuery = [PFInstallation query];
            PFUser *userToSendTo = transaction[@"borrower"];
            
            [pushQuery whereKey:@"username" equalTo:userToSendTo.username];
            
            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query
            PFObject *item = transaction[@"item"];
            NSString *message = [NSString stringWithFormat:@"%@ rejected your request to borrow %@", [PFUser currentUser].username, item[@"name"]];
            NSDictionary *data = @{@"alert":message,@"isRejectTransactionRequest" : @"YES"};
            [push setData:data];
            [push sendPushInBackground];
        }
    }];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // don't allow double clicking anywhere
    self.view.userInteractionEnabled = NO;
    //use the transaction corresponding to the tableview selected
    PFObject *transaction = (tableView == self.requestedOfYouTableView) ? self.requestedOfYouTransactions[indexPath.row] : self.requestedTransactions[indexPath.row];
    
    CLOSTransactionViewController *transactionvc = [[CLOSTransactionViewController alloc] init];
    transactionvc.transaction = transaction;
    
    if (tableView == self.requestedOfYouTableView) {
        //if you are looking at what was requested of you, show the info of the person asking to borrow
        transactionvc.requestedOfUser = transaction[@"borrower"];
        transactionvc.isMyRequests = NO;
    } else {
        //if you are looking at what you have requested to borrow, pass the info of the item owner
        transactionvc.requestToBorrow = transaction[@"owner"];
        transactionvc.isMyRequests = YES;
    }
    [self.navigationController pushViewController:transactionvc animated:YES];
}

//TODO: do we want to do lazy query here?
- (void)changedSwitch
{
    //make sure interaction enabled
    self.view.userInteractionEnabled = YES;
    
    //query again
    PFQuery *transactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [transactionQuery includeKey:@"item"];
    [transactionQuery orderByDescending:@"createdAt"];
    //query initial 15 items
    transactionQuery.limit = 15;
    //hides all table views and show the loading label
    self.loadinglabel.hidden = NO;
    self.requestedTableView.hidden = YES;
    self.requestedOfYouTableView.hidden = YES;
    if (self.switchController.selectedSegmentIndex == 0) {
        //query for requested of you
        [transactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        [transactionQuery includeKey:@"borrower"];
        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.requestedOfYouTransactions = objects;
            [self.requestedOfYouTableView reloadData];
            if (self.switchController.selectedSegmentIndex == 0) {
                //show the appropriate table view
                self.loadinglabel.hidden = YES;
                self.requestedOfYouTableView.hidden = NO;
                self.requestedTableView.hidden = YES;
            }
        }];

    } else {
        //query for requested of the current user
        [transactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
        [transactionQuery includeKey:@"owner"];
        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.requestedTransactions = objects;
            [self.requestedTableView reloadData];
            if (self.switchController.selectedSegmentIndex == 1) {
                //show the appropriate table view
                self.loadinglabel.hidden = YES;
                self.requestedTableView.hidden = NO;
                self.requestedOfYouTableView.hidden = YES;
            }
        }];

    }
    
    //query for number of transactions that haven't been checked
    PFQuery *lendTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [lendTransactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
    [lendTransactionQuery whereKey:@"hasUpdatedForOwner" equalTo:@YES];

    PFQuery *borrowTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [borrowTransactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
    [borrowTransactionQuery whereKey:@"hasUpdatedForBorrower" equalTo:@YES];

    PFQuery *countTransactionQuery = [PFQuery orQueryWithSubqueries:@[lendTransactionQuery, borrowTransactionQuery]];
    [countTransactionQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (number > 0)
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", number];
        else
            self.navigationController.tabBarItem.badgeValue = nil;
    }];


}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.requestedOfYouTableView reloadData];
    [self.requestedTableView reloadData];
    
    // make sure interaction enabled
    self.view.userInteractionEnabled = YES;
}

-(void)tableView: (UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //load more data when the 5th last cell is shown for that table view
    NSInteger pagingIndex = (tableView == self.requestedOfYouTableView) ? ([self.requestedOfYouTransactions count] - 5) : ([self.requestedTransactions count] - 5);
    if (indexPath.row == pagingIndex) {
        [self updateData];
    }
}

-(void)updateData
{
    PFQuery *transactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [transactionQuery includeKey:@"item"];
    [transactionQuery orderByDescending:@"createdAt"];
    //Load only 15 more items
    transactionQuery.limit = 15;
    if (self.switchController.selectedSegmentIndex == 0) {
        //Load more items requested of you
        [transactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        [transactionQuery includeKey:@"borrower"];
        transactionQuery.skip = [self.requestedOfYouTransactions count];
        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSInteger lastRow = [self.requestedOfYouTransactions count];

                self.requestedOfYouTransactions = [self.requestedOfYouTransactions arrayByAddingObjectsFromArray:objects];
                NSMutableArray *indexPaths = [NSMutableArray array];
                //for each item in object, prepare for insertion
                for (NSInteger i = 0; i < [objects count]; i++) {
                    NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                    [indexPaths addObject:ip];
                }
                [self.requestedOfYouTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
            }
        }];

    } else {
        //Load more items you've requested
        [transactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
        [transactionQuery includeKey:@"owner"];
        transactionQuery.skip = [self.requestedTransactions count];
        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSInteger lastRow = [self.requestedTransactions count];

                self.requestedTransactions = [self.requestedTransactions arrayByAddingObjectsFromArray:objects];
                NSMutableArray *indexPaths = [NSMutableArray array];
                //for each item in object, prepare for insertion
                for (NSInteger i = 0; i < [objects count]; i++) {
                    NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                    [indexPaths addObject:ip];
                }
                [self.requestedTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationRight];
            }
        }];

    }

}

-(void)handleRefresh:(id)sender
{
    PFQuery *transactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [transactionQuery includeKey:@"item"];
    [transactionQuery orderByDescending:@"createdAt"];
    //query initial 15 items
    transactionQuery.limit = 15;

    if (self.switchController.selectedSegmentIndex == 0)
    {
        //query for items requested of you
        [transactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
        [transactionQuery includeKey:@"borrower"];
        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.requestedOfYouTransactions = objects;
            [self.requestedOfYouTableView reloadData];
            [(UIRefreshControl *)sender endRefreshing];
        }];
    } else {
        //query for items you've requested
        [transactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
        [transactionQuery includeKey:@"owner"];
        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            self.requestedTransactions = objects;
            [self.requestedTableView reloadData];
            [(UIRefreshControl *)sender endRefreshing];
        }];

    }
    //query for number of transactions that haven't been checked
    PFQuery *lendTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [lendTransactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
    [lendTransactionQuery whereKey:@"hasUpdatedForOwner" equalTo:@YES];

    PFQuery *borrowTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [borrowTransactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
    [borrowTransactionQuery whereKey:@"hasUpdatedForBorrower" equalTo:@YES];

    PFQuery *countTransactionQuery = [PFQuery orQueryWithSubqueries:@[lendTransactionQuery, borrowTransactionQuery]];
    [countTransactionQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (number > 0)
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", number];
        else
            self.navigationController.tabBarItem.badgeValue = nil;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
