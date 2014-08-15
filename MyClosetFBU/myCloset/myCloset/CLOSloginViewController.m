//
//  CLOSloginViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSloginViewController.h"

#import "CLOSProfileViewController.h"
#import "CLOSSearchViewController.h"
#import "CLOSCameraViewController.h"
#import "CLOSInventoryViewController.h"
#import "CLOSNewsFeedViewController.h"
#import "CLOSAppDelegate.h"

#import "CLOSSignUpDetailViewController.h"

#import <FacebookSDK/FacebookSDK.h>

#import <Parse/Parse.h>

@interface CLOSloginViewController () <UITextFieldDelegate, FBLoginViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *username;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *accountButton;
@property (weak, nonatomic) IBOutlet UIButton *loginWithFbButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;



@end

@implementation CLOSloginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isFromTransactionNotification = NO;
        self.isFromFollowNotification = NO;
    }
    return self;
}


-(IBAction)login:(id)sender
{
    //Standard login - without Facebook
    //Hide the keyboard
    [self.view endEditing:YES];
    
    //Disable the login buttons and account button to prevent double pressing
    self.loginButton.enabled = NO;
    self.accountButton.enabled = NO;
    self.loginWithFbButton.enabled = NO;
    self.forgotPasswordButton.enabled = NO;
    
    // check if an email for username
    if ([self.username.text rangeOfString:@"@"].location != NSNotFound) { // has an @ sign, so must be an attempt to use email
        PFQuery *userQuery = [PFUser query];
        [userQuery whereKey:@"email" equalTo:self.username.text];
        [userQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if ([objects count] != 0) { // a user was found
                    PFUser *user = [objects firstObject];
                    // login in the user with the same code as below instead using the username of the user found in the query
                    [PFUser logInWithUsernameInBackground:user.username password:self.password.text block:^(PFUser *user, NSError *error) {
                        if (user) {
                            //set up tabbar view controller
                            UITabBarController *tbc = [self setUpTbc];
                            [self presentViewController:tbc animated:YES completion:nil];
                            
                            //Set installation for notifications
                            PFInstallation *myInstallation = [PFInstallation currentInstallation];
                            [myInstallation setObject:user.username forKey:@"username"];
                            [myInstallation saveInBackground];
                            
                            //Store the most recent username
                            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                            [defaults setObject:user.username forKey:CLOSUsernamePrefsKey];
                            
                        } else {
                            if (error.code == 100) {
                                //Connection error
                                self.errorLabel.text = @"The Internet connection appears to be offline.";
                            } else {
                                self.errorLabel.text = error.userInfo[@"error"];
                            }
                            [self.errorLabel sizeToFit];
                            //Reenable the buttons
                            if ([[self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] || [[self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                                //Username or password is empty - don't allow standard login
                                self.loginButton.enabled = NO;
                            else self.loginButton.enabled = YES;
                            self.accountButton.enabled = YES;
                            self.loginWithFbButton.enabled = YES;
                            self.forgotPasswordButton.enabled = YES;
                        }
                        
                    }];

                }
            }
        }];
    }
    else {
        [PFUser logInWithUsernameInBackground:self.username.text password:self.password.text block:^(PFUser *user, NSError *error) {
            if (user) {
                //set up tabbar view controller
                UITabBarController *tbc = [self setUpTbc];
                [self presentViewController:tbc animated:YES completion:nil];
                
                //Set installation for notifications
                PFInstallation *myInstallation = [PFInstallation currentInstallation];
                [myInstallation setObject:user.username forKey:@"username"];
                [myInstallation saveInBackground];
                
                //Store the most recent username
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:user.username forKey:CLOSUsernamePrefsKey];
                
            } else {
                if (error.code == 100) {
                    //Connection error
                    self.errorLabel.text = @"The Internet connection appears to be offline.";
                } else {
                    self.errorLabel.text = error.userInfo[@"error"];
                }
                [self.errorLabel sizeToFit];
                //Reenable the buttons
                if ([[self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] || [[self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                    //Username or password is empty - don't allow standard login
                    self.loginButton.enabled = NO;
                else self.loginButton.enabled = YES;
                self.accountButton.enabled = YES;
                self.loginWithFbButton.enabled = YES;
                self.forgotPasswordButton.enabled = YES;
            }
            
        }];
    }
    
}

-(UITabBarController *)setUpTbc
{
    //Initializing profile view
    CLOSProfileViewController *profvc = [[CLOSProfileViewController alloc] init];
    /*set up image */
    UIImage *profImage = [UIImage imageNamed:@"profileTab2.png"];
//    profImage = [self resizeImage:profImage newSize:CGSizeMake(21, 21)];
    /*end image set up */
    UITabBarItem *profItem = [[UITabBarItem alloc] initWithTitle:@"Profile" image:profImage tag:0];
    [profItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:11.0]} forState:UIControlStateNormal];
    UINavigationController *profNav = [[UINavigationController alloc] initWithRootViewController:profvc];
    profNav.tabBarItem = profItem;

    //Initializing camera view
    CLOSCameraViewController *camvc = [[CLOSCameraViewController alloc] init];
    UIImage *cameraImage = [UIImage imageNamed:@"cameraTab2.png"];
//    cameraImage = [self resizeImage:cameraImage newSize:CGSizeMake(21, 21)];
    UITabBarItem *cameraItem = [[UITabBarItem alloc] initWithTitle:@"Camera" image:cameraImage tag:1];
    [cameraItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:11.0]} forState:UIControlStateNormal];
    UINavigationController *camNav = [[UINavigationController alloc] initWithRootViewController:camvc];
    camNav.tabBarItem = cameraItem;

    //Initializing search view
    CLOSSearchViewController *searchvc = [[CLOSSearchViewController alloc] init];
    UINavigationController *searchNav = [[UINavigationController alloc] initWithRootViewController:searchvc];
    searchvc.title = @"Search";
    searchvc.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemSearch tag:2];
    [searchvc.tabBarItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:11.0]} forState:UIControlStateNormal];
    
    //Initializing inventory view
    CLOSInventoryViewController *invenvc = [[CLOSInventoryViewController alloc] init];
    UINavigationController *inventoryNav = [[UINavigationController alloc] initWithRootViewController:invenvc];
    inventoryNav.navigationBar.tintColor = [UIColor whiteColor];
    inventoryNav.navigationBar.barStyle = UIBarStyleBlack;
    inventoryNav.navigationBar.translucent = YES;
    [inventoryNav.navigationBar setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0]}];
    UIImage *inventoryImage = [UIImage imageNamed:@"inventoryTab2.png"];
    //inventoryImage = [self resizeImage:inventoryImage newSize:CGSizeMake(21, 21)];
    UITabBarItem *inventoryItem = [[UITabBarItem alloc] initWithTitle:@"Inventory" image:inventoryImage tag:3];
    [inventoryItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:11.0]} forState:UIControlStateNormal];
    inventoryNav.tabBarItem = inventoryItem;
    
    //Initializing newsfeed view
    CLOSNewsFeedViewController *newsfeedvc = [[CLOSNewsFeedViewController alloc] init];
    UINavigationController *newsfeedNav = [[UINavigationController alloc] initWithRootViewController:newsfeedvc];
    newsfeedNav.navigationBar.tintColor = [UIColor whiteColor];
    newsfeedNav.navigationBar.barStyle = UIBarStyleBlack;
    newsfeedNav.navigationBar.translucent = YES;
    [newsfeedNav.navigationBar setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0]}];
    UIImage *newsfeedImage = [UIImage imageNamed:@"newsfeedTab2.png"];
//    newsfeedImage = [self resizeImage:newsfeedImage newSize:CGSizeMake(17, 17)];
    UITabBarItem *newsfeedItem = [[UITabBarItem alloc] initWithTitle:@"Newsfeed" image:newsfeedImage

                                                                 tag:4];
    [newsfeedItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:11.0]} forState:UIControlStateNormal];
    newsfeedvc.title = @"News";
    newsfeedNav.tabBarItem = newsfeedItem;

    PFQuery *lendTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];

    //query for transactions that haven't been checked
    [lendTransactionQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
    [lendTransactionQuery whereKey:@"hasUpdatedForOwner" equalTo:@YES];

    PFQuery *borrowTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    [borrowTransactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
    [borrowTransactionQuery whereKey:@"hasUpdatedForBorrower" equalTo:@YES];

    PFQuery *transactionQuery = [PFQuery orQueryWithSubqueries:@[lendTransactionQuery, borrowTransactionQuery]];
    [transactionQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (number != 0)
            inventoryItem.badgeValue = [NSString stringWithFormat:@"%d", number];
    }];


    //Making the tab bar
    UITabBarController *tbc = [[UITabBarController alloc] init];
    tbc.viewControllers = @[newsfeedNav, searchNav, camNav, inventoryNav, profNav];
    
    // check if from transaction notification
    if (self.isFromTransactionNotification)
        tbc.selectedIndex = 3;
    else if (self.isFromFollowNotification)
        tbc.selectedIndex = 4;

    CLOSAppDelegate *appDelegate = (CLOSAppDelegate *)[[UIApplication sharedApplication]delegate];
    appDelegate.tbc = tbc;

    tbc.delegate = appDelegate;
    return tbc;
}

-(UIImage *)resizeImage: (UIImage *)image newSize:(CGSize)newSize {
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //Set the quality level to use when rescalaing
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    //Draw into the context, this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    //Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (IBAction)makeNewAccount:(id)sender {
    //Hide the keyboard
    [self.view endEditing:YES];

    //Initializing sign up view
    CLOSSignUpDetailViewController *signUpDetailvc = [[CLOSSignUpDetailViewController alloc] init];
    [self presentViewController:signUpDetailvc animated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // reset tbc of app delegate
    CLOSAppDelegate *appDelegate = (CLOSAppDelegate *)[[UIApplication sharedApplication]delegate];
    appDelegate.tbc = nil;

    //Set notifications to move view up and down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveDown:) name:UIKeyboardWillHideNotification object:nil];

    //update view
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.username.text = [defaults objectForKey:CLOSUsernamePrefsKey];
    self.password.text = @"";
    self.errorLabel.text = @"";
    self.accountButton.enabled = YES;
    self.loginWithFbButton.enabled = YES;
    if ([[self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] || [[self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
        //Username or password is empty - don't allow standard login
        self.loginButton.enabled = NO;
    else self.loginButton.enabled = YES;
    self.forgotPasswordButton.enabled = YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    PFUser *currentUser = [PFUser currentUser];
    
    //Is user cached?
    if (currentUser) {
        //TODO: problem: if user is logged on somewhere else, change is not reflected. causes weird behavior with fb linking and stuff. Should we fetch?
        if (!currentUser.email) {
            //User didn't set up an email - from facebook and never finished sign up
            CLOSSignUpDetailViewController *signUpDetailvc = [[CLOSSignUpDetailViewController alloc] init];
            signUpDetailvc.user = currentUser;
            [self presentViewController:signUpDetailvc animated:YES completion:nil];
        } else {
            //set up tabbar view controller
            UITabBarController *tbc = [self setUpTbc];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:currentUser.username forKey:CLOSUsernamePrefsKey];
            [self presentViewController:tbc animated:NO completion:nil];

            PFInstallation *myInstallation = [PFInstallation currentInstallation];
            [myInstallation setObject:currentUser.username forKey:@"username"];
            [myInstallation saveInBackground];
        }

    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //Remove self as an observer for keyboard
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    //Add tap gesture recognizer
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(backgroundTouched)];
    [self.view addGestureRecognizer:tap];

    //Set facebook logo into the facebook login button
    UIImage *fbLogo =[UIImage imageNamed:@"fb_icon_325x325.png"];
    UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 30, 30)];
    logoImageView.contentMode = UIViewContentModeScaleToFill;
    logoImageView.image = fbLogo;
    [self.loginWithFbButton addSubview:logoImageView];

    //Make buttons round
    self.loginButton.layer.cornerRadius = 8.0f;
    self.accountButton.layer.cornerRadius = 8.0f;
    self.loginWithFbButton.layer.cornerRadius = 8.0f;
    self.forgotPasswordButton.layer.cornerRadius = 8.0f;

    //Set color for disabled buttons
    [self.loginButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self.accountButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self.loginWithFbButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self.forgotPasswordButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    //Disable the login button when view shows for the first time
    self.loginButton.enabled = NO;

    //add method to detect textfield change
    [self.username addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.password addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (IBAction)loginButtonTouchHandler:(id)sender  {
    //Facebook login button
    //Disable the bottons to prevent double tapping
    self.loginWithFbButton.enabled = NO;
    self.accountButton.enabled = NO;
    self.loginButton.enabled = NO;
    self.forgotPasswordButton.enabled = NO;

    // The permissions requested from the user
    NSArray *permissionsArray = @[@"public_profile", @"user_friends", @"user_photos"];

    // Login PFUser using Facebook
    [PFFacebookUtils logInWithPermissions:permissionsArray block:^(PFUser *user, NSError *error) {
        if (!user) {
            //reached an error or user canceled facebook login
            self.loginWithFbButton.enabled = YES;
            self.accountButton.enabled = YES;
            self.forgotPasswordButton.enabled = YES;
            if ([[self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""] || [[self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
                //Username or password is empty - don't allow standard login
                self.loginButton.enabled = NO;
            else self.loginButton.enabled = YES;
            if (!error) {
                //The user cancelled the Facebook login
            } else {
                self.errorLabel.text = error.userInfo[@"error"];
                [self.errorLabel sizeToFit];
            }
        } else if (user.isNew) {
            //New user through fb login
            CLOSSignUpDetailViewController *signUpDetailvc = [[CLOSSignUpDetailViewController alloc] init];
            signUpDetailvc.user = user;
            [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                if (!error) {
                    // Store the current user's Facebook ID on the user
                    [user setObject:[result objectForKey:@"id"]
                                             forKey:@"fbId"];
                    [user saveInBackground];
                    [self presentViewController:signUpDetailvc animated:YES completion:nil];
                } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]){
                    [PFUser logOut];
                    UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The Facebook session was invalidated. Please login again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [invalidSession show];
                    [PFUser logOut];
                } else {
                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while getting your Facebook information." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [errorAlert show];
                    [PFUser logOut];
                }
            }];

        } else {
            //User logged in
            //set up tabbar view controller
            UITabBarController *tbc = [self setUpTbc];
            [self presentViewController:tbc animated:YES completion:nil];

            //Set installation for notifications
            PFInstallation *myInstallation = [PFInstallation currentInstallation];
            [myInstallation setObject:user.username forKey:@"username"];
            [myInstallation saveInBackground];

            //Store the most recent username
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:user.username forKey:CLOSUsernamePrefsKey];
        }
    }];
}
- (IBAction)passwordReset:(id)sender {
    UIAlertView *emailAlert = [[UIAlertView alloc] initWithTitle:@"Password Reset" message:@"Please enter your email." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Done", nil];
    emailAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [emailAlert show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [PFUser requestPasswordResetForEmailInBackground:[alertView textFieldAtIndex:0].text block:^(BOOL succeeded, NSError *error) {
            if (!error) {
                UIAlertView *sentEmail = [[UIAlertView alloc] initWithTitle:@"Email Sent" message:[NSString stringWithFormat:@"You should receive an email at %@ with instructions to reset your password.", [alertView textFieldAtIndex:0].text] delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
                [sentEmail show];
            } else {
                UIAlertView *errorResetting = [[UIAlertView alloc] initWithTitle:@"Reset Failed" message:error.userInfo[@"error"] delegate:self cancelButtonTitle:@"Done" otherButtonTitles:nil];
                [errorResetting show];
            }
        }];
    }
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

    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - keyboardFrame.size.height / 6, self.view.frame.size.width, self.view.frame.size.height)];

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

    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + keyboardFrame.size.height / 6, self.view.frame.size.width, self.view.frame.size.height)];

    [UIView commitAnimations];
}

- (IBAction)backgroundTouched {
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.username) {
        //Next pressed in username field
        [textField resignFirstResponder];
        [self.password becomeFirstResponder];
    } else {
        //Done pressed in password field
        [textField resignFirstResponder];
        [self login:textField];
    }
    return YES;
}

-(void)textFieldDidChange:(UITextField *)textField
{
    BOOL usernameIsEmpty = [[self.username.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
    BOOL passwordIsEmpty = [[self.password.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""];
    if (usernameIsEmpty || passwordIsEmpty) {
        self.loginButton.enabled = NO;
    } else {
        //All text fields are filled
        self.loginButton.enabled = YES;
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
