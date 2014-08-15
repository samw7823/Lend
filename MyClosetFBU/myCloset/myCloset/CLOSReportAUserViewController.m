//
//  CLOSReportAUserViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSReportAUserViewController.h"
#import "CLOSReportAUserView.h"
#import <MessageUI/MessageUI.h>

@interface CLOSReportAUserViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *optionsToProvide;

#define option1 @"User is creating inappropriate content"
#define option2 @"User is requesting to borrow items too often"
#define option3 @"User is requesting to follow me too often"
#define option4 @"User is using a fake Facebook account"
#define optionOther @"Other..."

#define row_height 60

@end

@implementation CLOSReportAUserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) loadView
{
    // initialize view
    CLOSReportAUserView *view = [[CLOSReportAUserView alloc] init];
    
    // set data source for table view
    self.optionsToProvide = @[option1, option2, option3, option4, optionOther];
    
    // set table view to adjust its frame to the specified row height and number of rows
    [view.tableView setFrame:CGRectMake(0, 60, [[UIScreen mainScreen] bounds].size.width, row_height * [self.optionsToProvide count])];
    
    // set the table view's delegate and data source
    view.tableView.delegate = self;
    view.tableView.dataSource = self;
    
    // set the buttons and according to frame of table view
    [view.sendButton setFrame:CGRectMake(20, view.tableView.frame.origin.y + view.tableView.frame.size.height + 20, [[UIScreen mainScreen] bounds].size.width - 40, 60)];
    [view.cancelButton setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 50, 20, 40, view.tableView.frame.origin.y - 20)];
    
    
    // set actions for the buttons and disable to send button until an option is selected
    [view.cancelButton addTarget:self
                          action:@selector(cancel:)
                forControlEvents:UIControlEventTouchUpInside];
    [view.sendButton addTarget:self
                        action:@selector(send:)
              forControlEvents:UIControlEventTouchUpInside];
    view.sendButton.hidden = YES;
    
    
    // set the view just made as the view controller's view
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.optionsToProvide count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue a cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    // allow for two lines of text and display the option for the specified row
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.text = self.optionsToProvide[indexPath.row];
    
    // set display options for the cell
    [cell.textLabel setFont:[UIFont fontWithName:@"STHeitiTC-Medium" size:18.0]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return row_height;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.superview) {
        CLOSReportAUserView *reportAUserView = (CLOSReportAUserView *)tableView.superview;
        if (reportAUserView.sendButton.hidden == YES) // something has been selected so it should be enabled
            reportAUserView.sendButton.hidden = NO;
    }
    // when selected, add checkmark
    UITableViewCell *cellSelected = [tableView cellForRowAtIndexPath:indexPath];
    cellSelected.accessoryType = UITableViewCellAccessoryCheckmark;
    cellSelected.backgroundColor = [UIColor clearColor];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // when deselected, get rid of checkmark
    UITableViewCell *cellSelected = [tableView cellForRowAtIndexPath:indexPath];
    cellSelected.accessoryType = UITableViewCellAccessoryNone;
    cellSelected.backgroundColor = [UIColor clearColor];
}

- (void) cancel: (id) sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void) send: (id) sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailvc = [[MFMailComposeViewController alloc] init];
        mailvc.mailComposeDelegate = self;
        
        // set subject
        [self.userToReport fetchIfNeeded];
        [mailvc setSubject:[NSString stringWithFormat:@"[ReportAUser] Report Regarding %@", self.userToReport.username]];
        
        // set message
        CLOSReportAUserView *reportAUserView = (CLOSReportAUserView *)self.view;
        NSString *issue = self.optionsToProvide[reportAUserView.tableView.indexPathForSelectedRow.row];
        [mailvc setMessageBody:[NSString stringWithFormat:@"REPORT:\n%@\n\nDETAILS:\n <please include details here>\n",issue] isHTML:NO];
        
        // set recipients
        [mailvc setToRecipients:@[@"lendfbu@gmail.com"]];
        
        [self presentViewController:mailvc animated:YES completion:NULL];
    }
}

// mail composer
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent) {
        [self dismissViewControllerAnimated:YES completion:NULL];
        UIAlertView *sentAlert = [[UIAlertView alloc] initWithTitle:@"Message Sent" message:@"Thank you for the feedback!" delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
        NSTimeInterval t = 2.0;
        [self performSelector:@selector(dismiss:) withObject:sentAlert afterDelay:t];
        [sentAlert show];
    }
    else if (result == MFMailComposeResultCancelled) {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
    else if (result == MFMailComposeResultFailed) {
        UIAlertView *failedAlert = [[UIAlertView alloc] initWithTitle:@"Message Failed to Send" message:error.description delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
        failedAlert.tag = -1;
        NSTimeInterval t = 2.0;
        [self performSelector:@selector(dismiss:) withObject:failedAlert afterDelay:t];
    }
}

- (void) dismiss: (id) sender
{
    UIAlertView *alert = (UIAlertView *)sender;
    [alert dismissWithClickedButtonIndex:0 animated:YES];
    if (alert.tag != -1)
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
