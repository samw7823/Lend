//
//  CLOSTransactionViewController.m
//  myCloset
//
//  Created by Samantha Wiener on 7/17/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

//#import <Parse/Parse.h>
#import "CLOSTransactionViewController.h"
#import "CLOSInventoryViewController.h"
#import <Parse/Parse.h>
#import <EventKit/EventKit.h>

@interface CLOSTransactionViewController () <UIImagePickerControllerDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *locationInfo;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UITextView *messageInfo;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *dateInfo;
@property (weak, nonatomic) IBOutlet UILabel *returnDateInfo;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *nameInfo;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;
@property (weak, nonatomic) IBOutlet UIButton *borrowedButton;
@property (weak, nonatomic) IBOutlet UIButton *returnedButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UIButton *addToiCalButton;

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

@implementation CLOSTransactionViewController

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
    // make compatible for 3.5 inch
    if ([UIScreen mainScreen].bounds.size.height != 568) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        sv.scrollEnabled = YES;
        sv.contentSize = CGSizeMake(320, 568);
        sv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
        [sv addSubview:self.view];
        self.view = sv;
    }

    // customize buttons

    // make buttons rounded
    self.acceptButton.layer.cornerRadius = 8.0f;
    self.rejectButton.layer.cornerRadius = 8.0f;
    self.borrowedButton.layer.cornerRadius = 8.0f;
    self.returnedButton.layer.cornerRadius = 8.0f;
    self.statusLabel.layer.cornerRadius = 8.0f;
    self.cancelButton.layer.cornerRadius = 8.0f;
    
    // set font
    self.acceptButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0];
    self.rejectButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0];
    self.borrowedButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    self.returnedButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    self.cancelButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    
    // set font color on buttons
    self.acceptButton.titleLabel.textColor = [UIColor whiteColor];
    self.rejectButton.titleLabel.textColor = [UIColor whiteColor];
    self.borrowedButton.titleLabel.textColor = [UIColor lightGrayColor];
    self.returnedButton.titleLabel.textColor = [UIColor lightGrayColor];
    self.cancelButton.titleLabel.textColor = [UIColor lightGrayColor];

    //make buttons obvious
    CGColorRef color = [[UIColor darkGrayColor] CGColor];
    self.borrowedButton.layer.borderWidth = 2.0;
    self.borrowedButton.layer.borderColor = color;
    self.returnedButton.layer.borderWidth = 2.0;
    self.returnedButton.layer.borderColor = color;
    self.cancelButton.layer.borderWidth = 2.0;
    self.cancelButton.layer.borderColor = color;
    
    NSString *title = [NSString stringWithFormat:@"%@",self.transaction[@"item"][@"name"]];
    [self setTitle:title];
    self.borrowedButton.hidden = YES;
    self.returnedButton.hidden = YES;
    self.cancelButton.hidden = YES;

    //Display Borrower
    if (self.isMyRequests == NO){
        //for items requested of you, show the info of the person requesting the item
        self.statusLabel.hidden = YES;
        NSString *borrower = [NSString stringWithFormat:@"%@", self.transaction[@"borrower"][@"username"]];
        [self.nameInfo setText:borrower];
        NSString *borrowerLabel = [NSString stringWithFormat:@"Borrower:"];
        [self.nameLabel setText:borrowerLabel];
        
        switch ([(NSNumber *)self.transaction[@"transactionState"] integerValue]) {
            case accepted:
                [self.acceptButton setTitle:@"ACCEPTED" forState:UIControlStateNormal];
                //self.acceptButton.backgroundColor = [UIColor whiteColor];
                self.statusLabel.hidden = YES;
                self.acceptButton.enabled = NO;
                self.rejectButton.hidden = YES;
                self.rejectButton.enabled = NO;
                break;
            case rejected:
                [self.rejectButton setTitle:@"REJECTED" forState:UIControlStateNormal];
               // self.rejectButton.backgroundColor = [UIColor whiteColor];
                self.statusLabel.hidden = YES;
                self.rejectButton.enabled = NO;
                self.acceptButton.hidden = YES;
                self.acceptButton.enabled = NO;
                break;
            case borrowed:
                self.returnedButton.hidden = NO;
                self.acceptButton.hidden = YES;
                self.acceptButton.enabled = NO;
                [self.statusLabel setText:@"item is lent out"];
                [self.statusLabel setBackgroundColor:[UIColor colorWithRed:22.0f/255.0f green:67.0f/255.0f blue:1.0f alpha:.6]];
                self.statusLabel.hidden = NO;
                self.rejectButton.hidden = YES;
                self.rejectButton.enabled = NO;
                // the owner has seen the update, so mark it as "read"
//                self.transaction[@"hasUpdatedForOwner"] = @NO;
//                [self.transaction saveInBackground];
                break;
            case returned:
                self.acceptButton.hidden = YES;
                self.rejectButton.hidden = YES;
                [self.statusLabel setText:@"item has been returned"];
                self.statusLabel.backgroundColor = [UIColor clearColor];
                self.statusLabel.hidden = NO;
                self.returnedButton.hidden = YES;
                break;
            case expired:
                self.acceptButton.hidden = YES;
                self.rejectButton.hidden = YES;
                [self.statusLabel setText:@"EXPIRED"];
                self.statusLabel.backgroundColor = [UIColor colorWithRed:136.0f/255.0f green:19.0f/255.0f blue:15.0f/255.0f alpha:.6];
                self.statusLabel.hidden = NO;
                self.returnedButton.hidden = YES;
                break;
            case cancelled:
                self.acceptButton.hidden = YES;
                self.rejectButton.hidden = YES;
                [self.statusLabel setText:@"transaction has been cancelled"];
                self.statusLabel.backgroundColor = [UIColor darkGrayColor];
                self.statusLabel.hidden = NO;
                self.returnedButton.hidden = YES;
                break;
            default:
                break;
        }

    }
    else {
        //for items you have requested show the info of the items owner
        NSString *owner = [NSString stringWithFormat:@"%@", self.transaction[@"owner"][@"username"]];
        [self.nameInfo setText:owner];
        NSString *ownerLabel = [NSString stringWithFormat:@"Owner:"];
        [self.nameLabel setText:ownerLabel];
        
        //Disbale accept/reject buttons and dispaly status label
        self.acceptButton.hidden = YES;
        self.acceptButton.enabled = NO;
        self.rejectButton.hidden = YES;
        self.rejectButton.enabled = NO;
        
        //Display status label
        self.statusLabel.hidden = NO;
        
        //Show text on status label based on transaction state
        
        switch ([(NSNumber *)self.transaction[@"transactionState"] integerValue]) {
            case accepted:
                [self.statusLabel setText:@"ACCEPTED"];
                self.statusLabel.backgroundColor = [UIColor colorWithRed:14.0f/255.0f green:114.0f/255.0f blue:0.0 alpha:.6];
                
                self.borrowedButton.hidden = NO;
                break;
            case rejected:
                [self.statusLabel setText:@"REJECTED"];
                self.statusLabel.backgroundColor = [UIColor colorWithRed:255.0f/255.0f green:48.0f/255.0f blue:0.0 alpha:.6];
                break;
            case borrowed:
                self.borrowedButton.hidden = YES;
                //TODO: put in a button that allows the borrower to send a push notification to the owner when they have
                //returned the item to remind the owner to mark it as returned
                
                [self.statusLabel setText:@"you have this item"];
                [self.statusLabel setBackgroundColor:[UIColor colorWithRed:22.0f/255.0f green:67.0f/255.0f blue:1.0f alpha:.6]];
                self.statusLabel.hidden = NO;
                break;
            case returned:
                [self.statusLabel setText:@"you returned this item"];
                self.statusLabel.backgroundColor = [UIColor clearColor];
                self.statusLabel.hidden = NO;
                break;
            case expired:
                [self.statusLabel setText:@"EXPIRED"];
                self.statusLabel.backgroundColor = [UIColor colorWithRed:136.0f/255.0f green:19.0f/255.0f blue:15.0f/255.0f alpha:.6];
                self.statusLabel.hidden = NO;
                break;
            case cancelled:
                [self.statusLabel setText:@"CANCELLED"];
                self.statusLabel.backgroundColor = [UIColor darkGrayColor];
                self.statusLabel.hidden = NO;
                break;
            default:
                [self.statusLabel setText:@"PENDING"];
                self.statusLabel.backgroundColor = [UIColor colorWithRed:177.0f/255.0f green:74.0f/255.0f blue:1.0 alpha:.6];
                self.statusLabel.hidden = NO;
                self.cancelButton.hidden = NO;
                break;
        }
        
    }
    
    
    //Display plannedLendDate
    NSDate *lendDate = self.transaction[@"plannedLendDate"];
    [self.dateInfo setText:[self.dateFormatter stringFromDate:lendDate]];
    [self.dateInfo sizeToFit];
    
    //Display plannedReturnDate
    NSDate *returnDate = self.transaction[@"plannedReturnDate"];
    [self.returnDateInfo setText:[self.dateFormatter stringFromDate:returnDate]];
    [self.returnDateInfo sizeToFit];

    //Display Location
    NSString *location = [NSString stringWithFormat:@"%@", self.transaction[@"borrowLocationString"]];
    [self.locationInfo setText:location];
    
    //Display message
    NSAttributedString *message = [[NSAttributedString alloc] initWithString:self.transaction[@"message"] attributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [self.messageInfo setAttributedText:message];
    
    
    PFFile *imageFile = self.transaction[@"item"][@"itemImage"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
        UIImage *image = [UIImage imageWithData:imageData];
        self.image.image = image;
    }];
    

}
- (IBAction)accept:(id)sender {
    self.transaction[@"transactionState"] = @(accepted); //Update transactionState
    self.transaction[@"hasUpdatedForBorrower"] = @YES;
    self.transaction[@"hasUpdatedForOwner"] = @NO;

    [self.transaction saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",[self.navigationController.tabBarItem.badgeValue intValue] - 1 ];
            if ([self.navigationController.tabBarItem.badgeValue intValue] <= 0)
                self.navigationController.tabBarItem.badgeValue = nil;
            [self.acceptButton setTitle:@"accepted" forState:UIControlStateNormal];
            self.statusLabel.hidden = YES;
            self.rejectButton.hidden = YES;
            self.rejectButton.enabled = NO;
            self.acceptButton.enabled = NO;

            if ([(NSDate *)self.transaction[@"plannedLendDate"] timeIntervalSinceNow] > 7*60) {
                //Send a local notification 5 minutes before borrow date
                UILocalNotification *transactionNotification = [[UILocalNotification alloc] init];
                transactionNotification.fireDate = [(NSDate *)self.transaction[@"plannedLendDate"] dateByAddingTimeInterval:-5*60];
                transactionNotification.timeZone = [NSTimeZone defaultTimeZone];
                if ([[self.transaction[@"message"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])
                    transactionNotification.alertBody = [NSString stringWithFormat:@"%@ will borrow %@ in 5 minutes.\nTime: %@\nLocation: %@",
                                                         self.transaction[@"borrower"][@"username"],
                                                         self.transaction[@"item"][@"name"],
                                                         [self.dateFormatter stringFromDate: self.transaction[@"plannedLendDate"]],
                                                         self.transaction[@"borrowLocationString"]];
                else
                    transactionNotification.alertBody = [NSString stringWithFormat:@"%@ will borrow %@ in 5 minutes.\nTime: %@\nLocation: %@\nMessage: %@",
                                                         self.transaction[@"borrower"][@"username"],
                                                         self.transaction[@"item"][@"name"],
                                                         [self.dateFormatter stringFromDate: self.transaction[@"plannedLendDate"]],
                                                         self.transaction[@"borrowLocationString"],
                                                         self.transaction[@"message"]];
                transactionNotification.userInfo = @{@"transactionId": self.transaction.objectId};
                [[UIApplication sharedApplication] scheduleLocalNotification:transactionNotification];
            }
        } else NSLog(@"%@", error.userInfo[@"error"]);
    }];
    
    //Query user requesting to borrow
    PFQuery *pushQuery = [PFInstallation query];
    PFUser *userToSendTo = self.transaction[@"borrower"];
    [pushQuery whereKey:@"username" equalTo:userToSendTo.username];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    PFObject *item = self.transaction[@"item"];
    NSString *message = [NSString stringWithFormat:@"%@ accepted your request to borrow %@", [PFUser currentUser].username, item[@"name"]];
    NSDictionary *data = @{@"alert":message,@"isAcceptTransactionRequest" : @"YES"};
    [push setData:data];
    [push sendPushInBackground];
    
}

- (IBAction)reject:(id)sender {

    self.transaction[@"transactionState"] = @(rejected); //Update transactionState
    self.transaction[@"hasUpdatedForBorrower"] = @YES;
    self.transaction[@"hasUpdatedForOwner"] = @NO;

    [self.transaction saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            self.navigationController.tabBarItem.badgeValue = [NSString stringWithFormat:@"%d",[self.navigationController.tabBarItem.badgeValue intValue] - 1 ];
            if ([self.navigationController.tabBarItem.badgeValue intValue] <= 0)
                self.navigationController.tabBarItem.badgeValue = nil;
            [self.rejectButton setTitle:@"rejected" forState:UIControlStateNormal];
            self.statusLabel.hidden = YES;
            self.acceptButton.hidden = YES;
            self.acceptButton.enabled = NO;
            self.rejectButton.enabled = NO;
        } else NSLog(@"%@", error.userInfo[@"error"]);
    }];

    
    //Send push notification
    PFQuery *pushQuery = [PFInstallation query];
    PFUser *userToSendTo = self.transaction[@"borrower"];
    
    [pushQuery whereKey:@"username" equalTo:userToSendTo.username];
    
    // Send push notification to query
    PFPush *push = [[PFPush alloc] init];
    [push setQuery:pushQuery]; // Set our Installation query
    PFObject *item = self.transaction[@"item"];
    NSString *message = [NSString stringWithFormat:@"%@ rejected your request to borrow %@", [PFUser currentUser].username, item[@"name"]];
    NSDictionary *data = @{@"alert":message,@"isRejectTransactionRequest" : @"YES"};
    [push setData:data];
    [push sendPushInBackground];
}

- (IBAction)borrowed:(id)sender
{
    self.borrowedButton.hidden = YES;
    //TODO: put in a button that allows the borrower to send a push notification to the owner when they have
    //returned the item to remind the owner to mark it as returned

    [self.statusLabel setText:@"you have this item"];
   // [self.statusLabel sizeToFit];
    self.statusLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:.4];
    self.statusLabel.hidden = NO;

    self.transaction[@"transactionState"] = @(borrowed);
    self.transaction[@"hasUpdatedForBorrower"] = @NO;
    self.transaction[@"hasUpdatedForOwner"] = @YES;
    self.transaction[@"lendDate"] = [NSDate date];
    [self.transaction saveInBackground];

    // update item as currently lent out
    PFObject *item = self.transaction[@"item"];
    [item setObject:@YES forKey:@"isBorrowed"];
    [item saveInBackground];

    //Set a local notification to return the item 5 minutes before return date
    if ([(NSDate *)self.transaction[@"plannedReturnDate"] timeIntervalSinceNow] > 7*60) {
        //Send a local notification 5 minutes before borrow date
        UILocalNotification *transactionNotification = [[UILocalNotification alloc] init];
        transactionNotification.fireDate = [(NSDate *)self.transaction[@"plannedReturnDate"] dateByAddingTimeInterval:-5*60];
        transactionNotification.timeZone = [NSTimeZone defaultTimeZone];
        transactionNotification.alertBody = [NSString stringWithFormat:@"%@ needs to be returned to %@ in 5 minutes.\nTime: %@",
                                             self.transaction[@"item"][@"name"],
                                             self.transaction[@"owner"][@"username"],
                                             [self.dateFormatter stringFromDate: self.transaction[@"plannedReturnDate"]]];
        transactionNotification.userInfo = @{@"transactionId": self.transaction.objectId};
        [[UIApplication sharedApplication] scheduleLocalNotification:transactionNotification];
    }

}
- (IBAction)addEventToiCal:(id)sender {
    EKEventStore *store = [[EKEventStore alloc] init];
    [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        if (!granted) {
            return;
        }
        EKEvent *event = [EKEvent eventWithEventStore:store];
        if (self.isMyRequests == NO) {
            //if it is my requests
            NSString *lendEventString = [NSString stringWithFormat:@"Lend %@ to %@", self.transaction[@"item"][@"name"],self.transaction[@"borrower"][@"username"]];
            event.title = lendEventString;
        }
        else{
            NSString *borrowEventString = [NSString stringWithFormat:@"Borrow %@ from %@", self.transaction[@"item"][@"name"],self.transaction[@"owner"][@"username"]];
            event.title = borrowEventString;
        }
        event.startDate = self.transaction[@"plannedLendDate"];
        event.endDate = self.transaction[@"plannedReturnDate"];
        event.location = self.transaction[@"borrowLocationString"];
        [event setCalendar:[store defaultCalendarForNewEvents]];
        
//        NSLog(@"Started saving");
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//            //on secondary therad here, so do saving here
//            
//
//        });
        NSError *err = nil;
        [store saveEvent:event span:EKSpanThisEvent commit:YES error:&err];
        if (!err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Event saved"
                                                                    message:@"Event saved to iCal"
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            });
        }
        //NSString *savedEventId = event.eventIdentifier; // to access this event later
        //show alert that event has saved
        NSLog(@"showing alert view");
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Event saved"
//                                                           message:@"Event saved to iCal"
//                                                          delegate:self
//                                                 cancelButtonTitle:@"OK"
//                                                 otherButtonTitles:nil];
//        [alertView show];
//        NSLog(@"showed alert view");
//        return;

        
    }];
}

- (IBAction)returned:(id)sender
{
    self.statusLabel.hidden = NO;
    self.returnedButton.hidden = YES;
    [self.statusLabel setText:@"item has been returned"];
    self.statusLabel.backgroundColor = [UIColor clearColor];
    //[self.statusLabel sizeToFit];
    self.transaction[@"transactionState"] = @(returned);
    self.transaction[@"hasUpdatedForBorrower"] = @YES;
    self.transaction[@"hasUpdatedForOwner"] = @NO;
    self.transaction[@"actualReturnDate"] = [NSDate date];
    [self.transaction saveInBackground];
    
    // update item as not currently lent out
    PFObject *item = self.transaction[@"item"];
    [item setObject:@NO forKey:@"isBorrowed"];
    [item saveInBackground];
    
    //if returned an item (transaction is closed), weighted activity for current user increase by 5
    [[PFUser currentUser] incrementKey:@"weightedActivity" byAmount:@5];
    [[PFUser currentUser] saveInBackground];
}
- (IBAction)cancelRequest:(id)sender
{
    PFUser *userToSendTo = self.transaction[@"owner"];
    PFObject *item = self.transaction[@"item"];
    [self.transaction deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        //Send push notification
        PFQuery *pushQuery = [PFInstallation query];
        [pushQuery whereKey:@"username" equalTo:userToSendTo.username];

        // Send push notification to query
        PFPush *push = [[PFPush alloc] init];
        [push setQuery:pushQuery]; // Set our Installation query
        NSString *message = [NSString stringWithFormat:@"%@ cancelled the request for your item %@", [PFUser currentUser].username, item[@"name"]];
        NSDictionary *data = @{@"alert":message,@"isCancelTransactionRequest" : @"YES"};
        [push setData:data];
        [push sendPushInBackground];
        
        [self.navigationController.viewControllers[([self.navigationController.viewControllers count] - 2)] handleRefresh:NULL];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
