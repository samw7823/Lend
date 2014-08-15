//
//  CLOSSignUpDetailViewController.m
//  myCloset
//
//  Created by Samantha Wiener on 7/24/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSSignUpDetailViewController.h"
#import "CLOSProfileViewController.h"
#import "CLOSCameraViewController.h"
#import "CLOSSearchViewController.h"
#import "CLOSInventoryViewController.h"
#import "CLOSloginViewController.h"
#import "CLOSAppDelegate.h"
#import "CLOSScreenshotsViewController.h"

@interface CLOSSignUpDetailViewController () <UITextFieldDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *facebookUserLabel;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIImageView *profilePicture;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *chooseProfilePictureButton;
@property (strong, nonatomic) NSMutableData *imageData;

@end

@implementation CLOSSignUpDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)cancelPressed:(id)sender {
    //serves as a check to see if user isAuthenticated
    //then we can delete the current user from parse
    if (self.user){
        [[PFUser currentUser] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // back to login view controller
            [FBSession.activeSession closeAndClearTokenInformation];
            [self dismissViewControllerAnimated:YES completion:NULL];
        }];
    } else if (!self.user) {
        //No user for this view; came from "make a new account" w/o facebook
        [self dismissViewControllerAnimated:YES completion:NULL];
    }

    
}
- (IBAction)signUpPressed:(id)sender {

    //Disable the buttons to prevent double tapping
    self.signUpButton.enabled = NO;
    self.cancelButton.enabled = NO;
    self.errorLabel.hidden = YES;
    
    // make sure username only has lowercase letters and numbers
    NSMutableCharacterSet *lowercaseLettersAndNumbers = [[NSCharacterSet lowercaseLetterCharacterSet] mutableCopy];
    [lowercaseLettersAndNumbers formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"0123456789"]];
    if (![[self.usernameTextField.text stringByTrimmingCharactersInSet:lowercaseLettersAndNumbers] isEqualToString:@""]) {
        // there are characters other than a-z and 0-9
        self.errorLabel.hidden = NO;
        self.errorLabel.text = @"username must be only numbers and lowercase letters";
        [self.errorLabel sizeToFit];
        self.signUpButton.enabled = YES;
        self.cancelButton.enabled = YES;
        return;
    }
    
    //Check if password is secure and correct
    if ([self.passwordTextField.text length] < 8) {
        //Password is shorter than 8
        self.errorLabel.hidden = NO;
        self.errorLabel.text = @"password must be at least 8 characters long";
        [self.errorLabel sizeToFit];
        self.signUpButton.enabled = YES;
        self.cancelButton.enabled = YES;
        return;
    }

    if ([self.passwordTextField.text rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound || [self.passwordTextField.text rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) {
        //Password does not have a letter / a number
        self.errorLabel.hidden = NO;
        self.errorLabel.text = @"password needs at least a letter and a number";
        [self.errorLabel sizeToFit];
        self.signUpButton.enabled = YES;
        self.cancelButton.enabled = YES;
        return;
    }

    if (![self.passwordTextField.text isEqualToString:self.confirmPasswordTextField.text]) {
        self.errorLabel.hidden = NO;
        self.errorLabel.text = @"passwords do not match";
        [self.errorLabel sizeToFit];
        self.signUpButton.enabled = YES;
        self.cancelButton.enabled = YES;
        return;
    }

    //save user information
    PFUser *newUser;
    if (self.user) {
        //facebook login user
        newUser = self.user;
    } else {
        //regular login user
        newUser = [PFUser user];
    }
    newUser.username = self.usernameTextField.text;
    newUser.password = self.passwordTextField.text;
    newUser[@"lowercaseUsername"] = [self.usernameTextField.text lowercaseString];
    newUser[@"email"] = self.emailTextField.text;
    newUser[@"isPrivate"] = @NO;
    newUser[@"weightedActivity"] = @0;

    if (self.user) {
        //already has a user - came from FB
        [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                //save profile picture as data
                if (self.profilePicture.image) {
                    //selected an image for profile picture
                    UIImage *image = self.profilePicture.image;
                    UIGraphicsBeginImageContext(CGSizeMake(200, 200));
                    [image drawInRect: CGRectMake(0, 0, 200, 200)];
                    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    NSData *imageData = UIImageJPEGRepresentation(smallImage, 0.85f);
                    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@ProfilePicture.jpg", newUser.username] data:imageData];
                    [imageFile saveInBackground];
                    //save image to the user
                    newUser[@"profilePicture"] = imageFile;
                    [newUser saveInBackground];
                }
                //Show alert view to notify about privacy settings
                UIAlertView *setPrivacy = [[UIAlertView alloc] initWithTitle:@"Privacy Settings" message:@"Your profile is by default public. A public profile allows your friends to find you and other people to see and request your items. You can also change the privacy setting of each closet you create. Do you want to set your profile to private?"  delegate:self cancelButtonTitle:@"Set to Private" otherButtonTitles:@"Remain Public", nil];
                [setPrivacy show];
            } else {
                self.errorLabel.hidden = NO;
                if (error.code == 100) {
                    self.errorLabel.text = @"The Internet connection appears to be offline.";
                } else {
                    self.errorLabel.text = error.userInfo[@"error"];
                }
                [self.errorLabel sizeToFit];
                //Reenable the buttons
                self.cancelButton.enabled = YES;
                self.signUpButton.enabled = YES;
            }
        }];

    } else {
        //No user - came from sign up w/o FB
        self.user = newUser;
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                if (self.profilePicture.image) {
                    //selected an image for profile picture
                    NSData *imageData = UIImageJPEGRepresentation(self.profilePicture.image, 0.85f);
                    PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@ProfilePicture.jpg", newUser.username] data:imageData];
                    [imageFile saveInBackground];
                    //Save image to the user
                    newUser[@"profilePicture"] = imageFile;
                    [newUser saveInBackground];
                }
                //Show alert view to notify about privacy settings
                UIAlertView *setPrivacy = [[UIAlertView alloc] initWithTitle:@"Privacy Settings" message:@"Your profile is by default public. A public profile allows your friends to find you and other people to see and request your items. You can also change the privacy setting of each closet you create. Do you want to set your profile to private?"  delegate:self cancelButtonTitle:@"Set to Private" otherButtonTitles:@"Remain Public", nil];
                [setPrivacy show];
            } else {
                self.errorLabel.hidden = NO;
                self.errorLabel.text = error.userInfo[@"error"];
                [self.errorLabel sizeToFit];
                //Reenable the buttons
                self.cancelButton.enabled = YES;
                self.signUpButton.enabled = YES;
                self.user = nil;
            }
            
        }];
        
    }

}

- (IBAction)chooseProfilePicturePressed:(id)sender {
    //Show image picker - library only
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [imagePicker.navigationBar setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0]}];
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:NULL];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Get picked image from info dictionary and create a new item
    UIImage *image = info[UIImagePickerControllerEditedImage];
    self.profilePicture.image = image;
    [picker dismissViewControllerAnimated:YES completion:NULL];
}


-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //user pressed Set to Private
        [self.user setValue:@YES forKey:@"isPrivate"];
        [self.user incrementKey:@"weightedActivity" byAmount:@-1000];
        [self.user saveInBackground];
    }
    //Set stored name for login vc
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.usernameTextField.text forKey:CLOSUsernamePrefsKey];
    // launch tutorial
    [self presentViewController:[[CLOSScreenshotsViewController alloc] init] animated:YES completion:NULL];
    //Save current user to installation
    PFInstallation *myInstallation = [PFInstallation currentInstallation];
    [myInstallation setObject:[PFUser currentUser].username forKey:@"username"];
    [myInstallation saveInBackground];
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

    //Set disabled sign up button appearance
    [self.signUpButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    self.signUpButton.enabled = NO;

    //tap recognizer that dismisses keyboard
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    //hide error label
    self.errorLabel.hidden = YES;
    if (self.user) {
        //Came from fb
        // Create request for user's Facebook data
        FBRequest *request = [FBRequest requestForMe];
        
        // Send request to Facebook
        [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // result is a dictionary with the user's Facebook data
                NSDictionary *userData = (NSDictionary *)result;
                
                NSString *facebookID = userData[@"id"];
                NSString *name = userData[@"name"];
                self.facebookUserLabel.text = name;
                [self.facebookUserLabel sizeToFit];
                
                //get profile picture
                // Download the user's facebook profile picture
                self.imageData = [[NSMutableData alloc] init]; // the data will be loaded in here
                
                // URL should point to https://graph.facebook.com/{facebookId}/picture?height=200&width=200&return_ssl_resources=1
                NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?height=200&width=200&return_ssl_resources=1", facebookID]];
                
                NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL
                                                                          cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                      timeoutInterval:2.0f];
                // Run network request asynchronously
                __unused NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
                // Now add the data to the UI elements
            } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                [PFUser logOut];
                UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The facebook session was invalidated. Please login again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [invalidSession show];
                [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while connecting to Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];
                [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser]];
            }
        }];
    } else {
        //Regular sign up
        self.facebookUserLabel.hidden = YES;
    }

    //Set buttons to be round
    self.signUpButton.layer.cornerRadius = 8.0f;
    self.cancelButton.layer.cornerRadius = 8.0f;
    self.chooseProfilePictureButton.layer.cornerRadius = 8.0f;

    //Add method to detect textfield change
    [self.usernameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.confirmPasswordTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.emailTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //adjust the placement when click on keyboard
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveDown:) name:UIKeyboardWillHideNotification object:nil];

}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //Remove self from notification for animation when keyboard appears
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.imageData appendData:data]; // Build the image
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Set the image in the header imageView
    self.profilePicture.image = [UIImage imageWithData:self.
                             imageData];
}

-(void)backgroundTapped
{
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - keyboardFrame.size.height+38, self.view.frame.size.width, self.view.frame.size.height)];
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
    
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + keyboardFrame.size.height-38, self.view.frame.size.width, self.view.frame.size.height)];
    [UIView commitAnimations];
}

-(void)textFieldDidChange:(UITextField *)textField
{
    BOOL usernameIsEmpty = [[self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
    BOOL passwordIsEmpty = [[self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
    BOOL confirmPasswordIsEmpty = [[self.confirmPasswordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
    BOOL emailIsEmpty = [[self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
    if (usernameIsEmpty || passwordIsEmpty || confirmPasswordIsEmpty || emailIsEmpty) {
        self.signUpButton.enabled = NO;
    } else {
        //All text fields are filled
        self.signUpButton.enabled = YES;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField) {
        //next pressed in username
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        //next pressed in password
        [self.confirmPasswordTextField becomeFirstResponder];
    } else if (textField == self.confirmPasswordTextField) {
        //next pressed in confirm password
        [self.emailTextField becomeFirstResponder];
    } else {
        //done pressed in email
        [self signUpPressed:textField];
    }
    return YES;
}

@end
