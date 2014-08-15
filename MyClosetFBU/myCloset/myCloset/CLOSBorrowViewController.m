//
//  CLOSBorrowViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSBorrowViewController.h"
#import <Parse/Parse.h>

@interface CLOSBorrowViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate,UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UITextView *locationField;
@property (weak, nonatomic) IBOutlet UITextView *messageField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) IBOutlet UIView *dataView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic) NSDate *borrowDate;
@property (nonatomic) NSDate *returnDate;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

typedef NS_ENUM(NSInteger, datePickerStates) {
    noDatePicker = 1,
    borrowDatePicker = 2,
    returnDatePicker = 3
};
@property (nonatomic) datePickerStates datePickerPhase;
typedef NS_ENUM(NSInteger, transactionStates)  {
    requested = 1,
    accepted = 2,
    rejected = 3,
    borrowed = 4,
    returned = 5
};
@end

@implementation CLOSBorrowViewController

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
    // make compatible for 3.5 inch
    if ([UIScreen mainScreen].bounds.size.height != 568) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        sv.scrollEnabled = YES;
        sv.contentSize = CGSizeMake(320, 568);
        sv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
        [sv addSubview:self.view];
        self.view = sv;
    }
    //Make both booleans false first
    self.datePickerPhase = noDatePicker;
    self.messageField.text = @"Special instruction, phone number...";
    self.messageField.textColor = [UIColor lightGrayColor];
    
    //Set fonts
    self.locationField.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    self.messageField.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    self.locationLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.messageLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    
    self.locationField.layer.borderWidth = 0.5;
    self.locationField.layer.borderColor = [[UIColor grayColor] CGColor];
    self.messageField.layer.borderWidth = 0.5;
    self.messageField.layer.borderColor = [[UIColor grayColor] CGColor];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(backgroundTouched)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    [self createDateFormatter];

    self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);

    //Set the buttons to be round
    self.doneButton.layer.cornerRadius = 8.0f;
    self.cancelButton.layer.cornerRadius = 8.0f;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveDown:) name:UIKeyboardWillHideNotification object:nil];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isDescendantOfView:self.tableView]) {
        return NO;
    }
    return YES;
}

-(BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (textView == self.messageField && [textView.text isEqualToString:@"Special instruction, phone number..."]) {
        textView.text = @"";
        textView.textColor = [UIColor whiteColor];
    }
    return YES;
}

//Limit number of characters in textView
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@""]) return YES;
    if ([textView.text length] - range.length + text.length > 140) return NO;
    return YES;
}

- (IBAction)donePressed:(id)sender {
    PFUser *currentUser = [PFUser currentUser];
    
    /* extract data user entered in, making sure that all fields are filled */
    NSString *locationText = self.locationField.text;
    if ([[locationText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you write in a suggested location!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }

    if ([self.borrowDate timeIntervalSinceNow] < 0 || [self.returnDate timeIntervalSinceNow] < 0) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Your dates are invalid!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        [self.tableView reloadData];
        return;
    }
    if (!self.borrowDate){
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure to choose a borrow date!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;

    }
    if (!self.returnDate){
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure to choose a return date!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;

    }
    //TODO: checking if there are other transactions the curren user have with this item that is in between the date range?

    //resetting message field if text is the default (unlikely the user would reenter the default text)
    NSString *messageText = self.messageField.text;
    if ([messageText isEqualToString:@"Special instruction, phone number..."]) messageText = @"";
    /* end extracting data */

    /* create transaction item */
    PFObject *transaction = [PFObject objectWithClassName:@"ItemTransaction"];
    transaction[@"borrower"] = currentUser;
    transaction[@"item"] = self.item;
    transaction[@"owner"] = self.itemOwner;

    //Make sure that user chooses a borrow and return date
        transaction[@"plannedLendDate"] = self.borrowDate;
    transaction[@"plannedReturnDate"] = self.returnDate;
    transaction[@"borrowLocationString"] = locationText;
    transaction[@"message"] = messageText;
    transaction[@"transactionState"] = @(requested);
    transaction[@"hasUpdatedForOwner"] = @YES;
    transaction[@"hasUpdatedForBorrower"] = @NO;
    [transaction saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded) {
            /* send push notification to item's owner */
            PFQuery *pushQuery = [PFInstallation query];
            [pushQuery whereKey:@"username" equalTo:self.itemOwner.username];

            // Send push notification to query
            PFPush *push = [[PFPush alloc] init];
            [push setQuery:pushQuery]; // Set our Installation query

            NSString *message = [NSString stringWithFormat:@"%@ requested to borrow %@", [PFUser currentUser].username, self.itemName];
            NSDictionary *data = @{@"alert":message,@"isTransactionRequest" : @"YES"};
            [push setData:data];
            [push sendPushInBackground];

            /* end sending push notification */
        }
    }];
    /* end create transaction item */
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)cancelPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)backgroundTouched
{
    [self.view endEditing:YES];
    //Close the date picker if is showing
    if (self.datePickerPhase != noDatePicker) {
        //has date picker
        CGRect frame = self.tableView.frame;
        frame.size.height = 88;
        self.tableView.frame = frame;
        CGRect dataFrame = self.dataView.frame;
        dataFrame.origin.y -= 216;
        self.dataView.frame = dataFrame;
        self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 40);
        self.datePickerPhase = noDatePicker;
        [self.tableView reloadData];
    }
}
- (IBAction)dateEditingBegin:(id)sender
{
    //TODO: optimize by casting sender as datePicker and delete datePicker property
    [self.view endEditing:YES];
    //Set text of cell to be the date chosen by user
    if (self.datePickerPhase == borrowDatePicker) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        NSArray *subviews = cell.contentView.subviews;
        ((UILabel *)subviews[1]).text = [self.dateFormatter stringFromDate:self.datePicker.date];
        cell.textLabel.text = @"Borrow";
        //Set text of 'Choose borrow date' to be the date chosen by user
        self.borrowDate = self.datePicker.date;
    }
    else if (self.datePickerPhase == returnDatePicker) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        NSArray *subviews = cell.contentView.subviews;
        ((UILabel *)subviews[1]).text = [self.dateFormatter stringFromDate:self.datePicker.date];
        cell.textLabel.text = @"Return";
        //Set text of 'Choose return date' to be the date chosen by user
        self.returnDate = self.datePicker.date;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //set height of cells based on datePickerPhase to adjust for cell size for the datePicker
    if (self.datePickerPhase == noDatePicker) {
        if (indexPath.row == 0){
            return 44;
        }
        if (indexPath.row == 1) {
            return 44;
        }
    }
    else if (self.datePickerPhase == borrowDatePicker){
        if (indexPath.row == 0){
            return 44;
        }
        if (indexPath.row == 1){
            return 216;
        }
        if (indexPath.row ==2){
            return 44;
        }
    }
    else if (self.datePickerPhase == returnDatePicker) {
        if (indexPath.row == 0){
            return 44;
        }
        if (indexPath.row == 1) {
            return 44;
        }
        if (indexPath.row == 2) {
            return 216;
        }
    }
    return 0;
}

//Format the date
- (void)createDateFormatter {
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    
    [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
}



//Check if need to add an extra row for the date picker
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.datePickerPhase == noDatePicker){
        return 2;
    }
    else {
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.5];
    cell.opaque = NO;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    
    //Create a label
    UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(140, 4, 210, 40)];
    infoLabel.textColor = [UIColor whiteColor];
    infoLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    
    switch (self.datePickerPhase) {
        case noDatePicker:
            //Set the titles of the two cells that are initially displayed
            if (indexPath.row == 0) {
                //Only add infoLabel if not in datePicker
                [cell.contentView addSubview:infoLabel];
                //Check if a date has already been selected
                if (!self.borrowDate || [self.borrowDate timeIntervalSinceNow] < 0) {
                    infoLabel.text = @"";
                    cell.textLabel.text = @"Choose a borrow date";
                    self.borrowDate = nil;
                }
                else {
                    //If a date has already been selected display the date and the textLabel
                    cell.textLabel.text = @"Borrow";
                    infoLabel.text = [self.dateFormatter stringFromDate: self.borrowDate];
                }
            }
            if (indexPath.row == 1) {
                //Only add infoLabel if not in datePicker
                [cell.contentView addSubview:infoLabel];
                //Check if a date has already been selected
                if (!self.returnDate || [self.returnDate timeIntervalSinceNow] < 0){
                    infoLabel.text = @"";
                    cell.textLabel.text = @"Choose a return date";
                    self.returnDate = nil;
                }
                else {
                    //If a date has already been selected display the date and the textLabel
                    cell.textLabel.text = @"Return";
                    infoLabel.text = [self.dateFormatter stringFromDate:self.returnDate];
                }
                
            }
            break;
        case borrowDatePicker:
            if (indexPath.row == 0) {
                //If you in datePickerPhase borrowDatePicker
                //the first cell should display 'Borrow' and the current date is no date has been picked
                //or 'Borrow' and the date if date has been picked
                //Only add infoLabel if not in datePicker

                [cell.contentView addSubview:infoLabel];
                cell.textLabel.text = @"Borrow";
                if (!self.borrowDate || [self.borrowDate timeIntervalSinceNow] < 0){
                    //if the date is no longer in the future, reset it to current time; if no date was picked, set it to current time
                    infoLabel.text = [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:60]];
                    self.borrowDate = [NSDate dateWithTimeIntervalSinceNow:60];
                } else {
                    //If a date has already been selected display the date and the textLabel
                    infoLabel.text = [self.dateFormatter stringFromDate: self.borrowDate];
                }
                //infoLabel should be red while editing a date
                infoLabel.textColor = [UIColor redColor];
            }
            if (indexPath.row == 1){
                UIDatePicker *borrowDatePicker = [[UIDatePicker alloc] init];
                [cell addSubview:borrowDatePicker];
                borrowDatePicker.backgroundColor = [UIColor whiteColor];
                borrowDatePicker.tintColor = [UIColor redColor];
                //Check if date has already been selected
                if (self.borrowDate) borrowDatePicker.date = self.borrowDate;
                //Set minimum date that user can pick to the current date
                borrowDatePicker.minimumDate = [NSDate dateWithTimeIntervalSinceNow:60];
                //Set the maximum date to be the return date
                borrowDatePicker.maximumDate = self.returnDate;
                self.datePicker = borrowDatePicker;
                [self.datePicker addTarget:self action:@selector(dateEditingBegin:) forControlEvents:UIControlEventValueChanged];
            }
            if (indexPath.row == 2) {
                //Only add infoLabel if not in datePicker
                [cell.contentView addSubview:infoLabel];
                if (!self.returnDate || [self.returnDate timeIntervalSinceNow] < 0){
                    infoLabel.text = @"";
                    cell.textLabel.text = @"Choose a return date";
                    self.returnDate = nil;
                }
                else {
                    //If a date has already been selected display the date and the textLabel
                    cell.textLabel.text = @"Return";
                    infoLabel.text = [self.dateFormatter stringFromDate:self.returnDate];
                }
            }
            break;
        case returnDatePicker:
            //Set cells to display the borrow date information in row 0
            //the return information in row 1
            //and the return datePicker in row 2
            if (indexPath.row == 0) {
                //Only add infoLabel if not in datePicker
                [cell.contentView addSubview:infoLabel];
                if (!self.borrowDate || [self.borrowDate timeIntervalSinceNow] < 0){
                    infoLabel.text = @"";
                    cell.textLabel.text = @"Choose a borrow date";
                    self.borrowDate = nil;
                }
                else {
                    //If a date has already been selected display the date and the textLabel
                    cell.textLabel.text = @"Borrow";
                    infoLabel.text = [self.dateFormatter stringFromDate: self.borrowDate];
                }
            }
            if (indexPath.row == 1) {
                //Only add infoLabel if not in datePicker
                [cell.contentView addSubview:infoLabel];
                cell.textLabel.text = @"Return";
                if (!self.returnDate || [self.returnDate timeIntervalSinceNow] < 0) {
                    //If no date has been selected, display the current date if no borrow date and borrow date if borrow date
                    if (self.borrowDate && [self.borrowDate timeIntervalSinceNow] >= 0) {
                        infoLabel.text = [self.dateFormatter stringFromDate:self.borrowDate];
                        self.returnDate = self.borrowDate;
                    } else {
                        infoLabel.text = [self.dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:60]];
                        self.returnDate = [NSDate dateWithTimeIntervalSinceNow:60];
                    }
                }
                else {
                    //If a date has already been selected display the date and the textLabel
                    infoLabel.text = [self.dateFormatter stringFromDate:self.returnDate];
                }
                //InfoLabel should be red while editing
                infoLabel.textColor = [UIColor redColor];
            }
            if (indexPath.row == 2){
                UIDatePicker *returnDatePicker = [[UIDatePicker alloc] init];
                [cell addSubview:returnDatePicker];
                returnDatePicker.backgroundColor = [UIColor whiteColor];
                returnDatePicker.tintColor = [UIColor redColor];
                if (self.returnDate) returnDatePicker.date = self.returnDate;
                //Set minimum date that user can pick to the borrow date
                returnDatePicker.minimumDate = self.borrowDate;
                self.datePicker = returnDatePicker;
                [self.datePicker addTarget:self action:@selector(dateEditingBegin:) forControlEvents:UIControlEventValueChanged];
            }

            break;
            
        default:
            break;
    }
    

    return cell;
    
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.view endEditing:YES];
    
    //Check phase where no datePicker is shown
    if (self.datePickerPhase == noDatePicker) {
        //Check which row is chosen
        //Check if selected first cell to enter borrow date
        if (indexPath.row == 0) {
            self.datePickerPhase = borrowDatePicker;
            CGRect frame = self.tableView.frame;
            frame.size.height = 304;
            self.tableView.frame = frame;
            CGRect dataFrame = self.dataView.frame;
            dataFrame.origin.y += 216;
            self.dataView.frame = dataFrame;
            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 216 - 40);
            [self.tableView reloadData];
            return;
        }
        //Check of selected secpnd cell to enter return date
        else if (indexPath.row == 1) {
            self.datePickerPhase = returnDatePicker;
            CGRect frame = self.tableView.frame;
            frame.size.height = 304;
            self.tableView.frame = frame;
            CGRect dataFrame = self.dataView.frame;
            dataFrame.origin.y += 216;
            self.dataView.frame = dataFrame;
            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + 216 - 40);
            [self.tableView reloadData];
            return;
        }
    }
    
    //Check phase where borrowDatePicker is shown
    if (self.datePickerPhase == borrowDatePicker) {
        //Should close the borrowDate Picker if you click on it again
        if (indexPath.row == 0) {
            self.datePickerPhase = noDatePicker;
            CGRect frame = self.tableView.frame;
            frame.size.height = 88;
            self.tableView.frame = frame;
            CGRect dataFrame = self.dataView.frame;
            dataFrame.origin.y -= 216;
            self.dataView.frame = dataFrame;
            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 40);
            [self.tableView reloadData];
            return;
        }
        //check if select return date picker when you already have borrow date picker open
        else if (indexPath.row == 2) {
            self.datePickerPhase = returnDatePicker;
            [self.tableView reloadData];
            return;
        }

    }
    
    if (self.datePickerPhase == returnDatePicker) {
        //if select return date picker row, show hide return date picker again
        if (indexPath.row == 1) {
            self.datePickerPhase = noDatePicker;
            CGRect frame = self.tableView.frame;
            frame.size.height = 88;
            self.tableView.frame = frame;
            CGRect dataFrame = self.dataView.frame;
            dataFrame.origin.y -= 216;
            self.dataView.frame = dataFrame;
            self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 40);
            [self.tableView reloadData];
            return;
        }
        else if (indexPath.row == 0){
            //Should open the borrowDatePicker
            self.datePickerPhase = borrowDatePicker;
            [self.tableView reloadData];
            return;
        }
        
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//Animations to move up/down view when keyboard appears/disappears
-(void)moveUp:(NSNotification *)aNotification
{
    //Get user info
    NSDictionary *userInfo = [aNotification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    //animate
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    //Close the date picker if is showing
    if (self.datePickerPhase != noDatePicker) {
        //has date picker
        CGRect frame = self.tableView.frame;
        frame.size.height = 88;
        self.tableView.frame = frame;
        CGRect dataFrame = self.dataView.frame;
        dataFrame.origin.y -= 216;
        self.dataView.frame = dataFrame;
        self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - 40);
        self.datePickerPhase = noDatePicker;
        [self.tableView reloadData];
    }
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - keyboardFrame.size.height + 40, self.view.frame.size.width, self.view.frame.size.height)];
    [UIView commitAnimations];
}

-(void)moveDown:(NSNotification *)aNotification
{
    //Get user info
    NSDictionary *userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardFrame;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    
    [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] getValue:&keyboardFrame];
    //animate
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationDuration:animationDuration];
    
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + keyboardFrame.size.height - 40, self.view.frame.size.width, self.view.frame.size.height)];
    [UIView commitAnimations];
}

//Make status bar text white
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
