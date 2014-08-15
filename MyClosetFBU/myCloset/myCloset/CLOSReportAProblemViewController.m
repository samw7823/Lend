//
//  CLOSReportAProblemViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/1/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSReportAProblemViewController.h"
#import <MessageUI/MessageUI.h>

@interface CLOSReportAProblemViewController () <UITextFieldDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UIButton *sendButton;

@end

@implementation CLOSReportAProblemViewController

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
    
    // configure send button
    self.sendButton.layer.cornerRadius = 8.0f;
    [self.sendButton addTarget:self
                        action:@selector(sendMessage:)
              forControlEvents:UIControlEventTouchUpInside];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}
- (IBAction)backgroundTapped:(id)sender
{
    // lower keyboards if background tapped
    if ([self.subjectTextField isFirstResponder])
        [self.subjectTextField resignFirstResponder];
    else if ([self.messageTextView isFirstResponder])
        [self.messageTextView resignFirstResponder];
}

- (void) sendMessage: (id) sender
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailvc = [[MFMailComposeViewController alloc] init];
        mailvc.mailComposeDelegate = self;
        [mailvc setSubject:self.subjectTextField.text];
        [mailvc setMessageBody:self.messageTextView.text isHTML:NO];
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
        [self.navigationController popViewControllerAnimated:YES];
}

@end
