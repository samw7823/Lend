//
//  CLOSSettingsViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/21/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSSettingsViewController.h"

#import <Parse/Parse.h>

#import "CLOSAppDelegate.h"
#import "CLOSItemsYouveBorrowedViewController.h"
#import "CLOSPrivacySettingsViewController.h"
#import "CLOSReportAProblemViewController.h"
#import "CLOSSettingsFindFriendsViewController.h"
#import "CLOSloginViewController.h"
#import "CLOSGroupListTableViewController.h"
#import "CLOSScreenshotsViewController.h"
#import "CLOSGeneralViewController.h"

#define NUM_PREFERENCES_CELLS 1
#define NUM_SUPPORT_CELLS 5
#define NUM_OTHER_CELLS 2
#define NUM_ACCOUNT_CELLS 3
#define NUM_SECTIONS 4

@interface CLOSSettingsViewController () <UITableViewDataSource, UITableViewDelegate, UITabBarDelegate, UIAlertViewDelegate, NSURLConnectionDataDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableData *imageData;
@property (nonatomic, copy) NSString *facebookName;
@property (strong, nonatomic) UIImage *profileImage; //If profileImage is not nil, facebookName must also not be nil
@property (nonatomic, assign) BOOL facebookInfoInProcess;
@property (nonatomic, strong) NSURLConnection *largeFbPictureConnection;
@property (strong, nonatomic) NSMutableData *largeImageData;
typedef NS_ENUM(NSInteger, sectionNumbers)  {
    other = 0,
    support = 1,
    preferences = 2,
    account = 3
};

@end

@implementation CLOSSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.facebookInfoInProcess = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.navigationItem.title = @"More";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    // Do any additional setup after loading the view from its nib.
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"%ld.%ld",(long)indexPath.section,(long)indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor =[UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    cell.imageView.image = nil;
    switch (indexPath.section) {
        case other:
            switch (indexPath.row) {
                case 0:
                    [cell.textLabel setText:@"Find People to Follow"];
                    break;
                case 1:
                    [cell.textLabel setText:@"Items I've Borrowed"];
                    break;
                default:
                    break;
            }
            break;
        case support:
            switch (indexPath.row) {
                case 0:
                    [cell.textLabel setText:@"Report a Problem"];
                    break;
                case 1:
                    [cell.textLabel setText:@"Privacy"];
                    break;
                case 2:
                    [cell.textLabel setText:@"Help"];
                    break;
                case 3:
                    [cell.textLabel setText:@"FAQs"];
                    break;
                case 4:
                    [cell.textLabel setText:@"Attributions"];
                    break;
                default:
                    break;
            }
            break;
        case preferences:
            switch (indexPath.row) {
                case 0:
                    [cell.textLabel setText:@"Account Settings"];
                    break;
//                case 1:
//                    [cell.textLabel setText:@"Push Notification Settings"];
//                    break;
                default:
                    break;
            }
            break;
        case account:
            cell.accessoryType = UITableViewCellAccessoryNone;
            switch (indexPath.row) {
                case 0:
                    [cell.textLabel setText:@"Logout"];
                    break;
                case 1:
                    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
                        //Current user is not with facebook
                        [cell.textLabel setText:@"Link With Facebook"];
                        cell.imageView.image = nil;
                        cell.textLabel.numberOfLines = 1;
                        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    } else {
                        //current user is with facebook - show name and prof pic
                        cell.textLabel.numberOfLines = 0;
                        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
                        cell.textLabel.text = @"You are connected to Facebook. Unlink from Facebook?";

                        //make a blank image as placeholder for profile picture
                        UIGraphicsBeginImageContextWithOptions(CGSizeMake(50, 50), NO, 0.0);
                        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        cell.imageView.image = blank;
                        if (self.facebookName) {
                            [cell.textLabel setText:[NSString stringWithFormat:@"You are connected to Facebook as %@. Unlink from Facebook?",self.facebookName]];
                            if (self.profileImage) cell.imageView.image = self.profileImage;
                            //if no image but has facebook name, image is being downloaded - will be set by request complete method
                        } else if (!self.facebookInfoInProcess) {
                            //no facebook name stored/in process - don't have profile image either
                            self.facebookInfoInProcess = YES;
                            [FBRequestConnection startWithGraphPath:@"/me?fields=name" parameters:nil HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                if (!error && [cell.textLabel.text hasPrefix:@"You are connected to Facebook"]) {
                                    self.facebookName = result[@"name"];
                                    [cell.textLabel setText:[NSString stringWithFormat:@"You are connected to Facebook as %@. Unlink from Facebook?",result[@"name"]]];

                                } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                                    [PFUser logOut];
                                    UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The facebook session was invalidated. Please login again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [invalidSession show];
                                    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
                                } else {
                                    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while getting information from Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [errorAlert show];
                                }
                            }];
                            self.imageData = [[NSMutableData alloc] init]; // the data will be loaded in here

                            // URL should point to https://graph.facebook.com/{facebookId}/picture?height=50&width=50&return_ssl_resources=1
                            NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?height=100&width=100&return_ssl_resources=1", [PFUser currentUser][@"fbId"]]];

                            NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2.0f];
                            // Run network request asynchronously
                            __unused NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
                        }
                    }
                    break;
                case 2:
                    [cell.textLabel setText:@"Delete Account"];
                    break;
                default:
                    break;
            }
            break;
        default:
            break;
    }
    
    return cell;
}

// Called every time a chunk of the data is received
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if (connection != self.largeFbPictureConnection) {
        [self.imageData appendData:data]; // Build the image
    } else {
        [self.largeImageData appendData:data];
    }
}

// Called when the entire image is finished downloading
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (connection != self.largeFbPictureConnection) {
        UITableViewCell *facebookCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:account]];
        if (![facebookCell.textLabel.text isEqualToString:@"Link With Facebook"]) {
            // Set the image in the facebook cell
            UIImage *image = [UIImage imageWithData:self.imageData];
            UIGraphicsBeginImageContext(CGSizeMake(50, 50));
            [image drawInRect:CGRectMake(0, 0, 50, 50)];
            UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            self.profileImage = smallImage;

            facebookCell.imageView.image = self.profileImage;
            [facebookCell setNeedsLayout];
        }
        self.facebookInfoInProcess = NO;
    } else {
        PFFile *imageFile = [PFFile fileWithName:[NSString stringWithFormat:@"%@ProfilePicture.jpg", [PFUser currentUser].username] data:self.largeImageData];
        [imageFile saveInBackground];
        [PFUser currentUser][@"profilePicture"] = imageFile;
        [[PFUser currentUser] saveInBackground];
    }
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.profileImage = nil;
    self.facebookInfoInProcess = NO;
    self.imageData = nil;
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while getting information from Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];

}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == other) return 0.0;
    return 40.0;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != account) {
        return 44;
    }
    if (indexPath.row != 1) {
        return 44;
    }
    if (![PFFacebookUtils isLinkedWithUser:[PFUser currentUser]]) {
        return 44;
    }
    return 88;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}
- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case other:
            return @" ";
            break;
        case support:
            return @"support";
            break;
        case preferences:
            return @"preferences";
            break;
        case account:
            return @"   ";
            break;
        default:
            return @"";
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case other:
            return NUM_OTHER_CELLS;
            break;
        case support:
            return NUM_SUPPORT_CELLS;
            break;
        case preferences:
            return NUM_PREFERENCES_CELLS;
            break;
        case account:
            return NUM_ACCOUNT_CELLS;
            break;
        default:
            return 0;
            break;
    }
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"Find People to Follow"]) {
        CLOSSettingsFindFriendsViewController *findFriendsvc = [[CLOSSettingsFindFriendsViewController alloc] init];
        [self.navigationController pushViewController:findFriendsvc animated:YES];
        
    }
    else if ([cell.textLabel.text isEqualToString:@"Items I've Borrowed"]) {
        CLOSItemsYouveBorrowedViewController *itemsBorrowed = [[CLOSItemsYouveBorrowedViewController alloc] init];
        [self.navigationController pushViewController:itemsBorrowed animated:YES];
        
    }
    else if ([cell.textLabel.text isEqualToString:@"Account Settings"]) {
        CLOSPrivacySettingsViewController *privacyvc = [[CLOSPrivacySettingsViewController alloc] init];
        [self.navigationController pushViewController:privacyvc animated:YES];
        
    } else if ([cell.textLabel.text isEqualToString:@"Delete Account"]) {
        //Ask user to enter email to confirm deletion
        UIAlertView *deleteAccount = [[UIAlertView alloc] initWithTitle:@"Delete Account" message:@"Are you sure you want to delete your account? Enter your email to confirm deletion." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
        deleteAccount.alertViewStyle = UIAlertViewStylePlainTextInput;
        [deleteAccount textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
        [deleteAccount show];
    } else if ([cell.textLabel.text isEqualToString:@"Link With Facebook"]) {
        //Connect Facebook with Parse current user
        [PFFacebookUtils linkUser:[PFUser currentUser] permissions:@[@"public_profile", @"user_friends", @"user_photos"] block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    if (!error) {
                        // Store the current user's Facebook ID on the user
                        PFUser *user = [PFUser currentUser];
                        [user setObject:[result objectForKey:@"id"]
                                 forKey:@"fbId"];
                        [user saveInBackground];
                        UIActionSheet *useFbProfileImage = [[UIActionSheet alloc] initWithTitle:@"Change your profile picture to your Facebook profile picture?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Use my Facebook picture",nil];
                        [useFbProfileImage showFromTabBar:self.tabBarController.tabBar];
                    } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                        [PFUser logOut];
                        UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The facebook session was invalidated. Please login again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [invalidSession show];
                        [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while connecting to Facebook." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [errorAlert show];
                        [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
                            [self.tableView reloadData];
                        }];
                    }
                    [self.tableView reloadData];
                }];

            } else {
                UIAlertView *errorFacebook = [[UIAlertView alloc] initWithTitle:@"Linking to Facebook failed!" message:error.userInfo[@"error"] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorFacebook show];
            }
        }];
    } else if ([cell.textLabel.text hasPrefix:@"You are connected to Facebook"]) {
        //Disconnect from facebook
        [PFFacebookUtils unlinkUserInBackground:[PFUser currentUser] block:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                //reset the properties about FB
                self.profileImage = nil;
                self.facebookName = nil;
                self.imageData = nil;
                [PFUser currentUser][@"fbId"] = @"";
                [[PFUser currentUser] saveInBackground];
                [self.tableView reloadData];
            }
        }];
    }
    else if ([cell.textLabel.text isEqualToString:@"Report a Problem"]) {
        CLOSReportAProblemViewController *reportvc = [[CLOSReportAProblemViewController alloc] init];
        [self.navigationController pushViewController:reportvc animated:YES];
    } else if ([cell.textLabel.text isEqualToString:@"Logout"]) {
        [self logout];
    }
    else if ([cell.textLabel.text isEqualToString:@"Help"]) {
        // show the screenshot tutorial
        [self.navigationController pushViewController:[[CLOSScreenshotsViewController alloc] init] animated:YES];
    }
    else if ([cell.textLabel.text isEqualToString:@"FAQs"]) {
        [self makeAndPresentFAQsView];
    }
    else if ([cell.textLabel.text isEqualToString:@"Attributions"]) {
        CLOSGeneralViewController *aboutvc = [[CLOSGeneralViewController alloc] init];
        [self.navigationController pushViewController:aboutvc animated:YES];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)logout {
    // current user can logout of their account from settings. change the installation, log them out in parse, and go back to the login page
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setObject:@"" forKey:@"username"];
    [currentInstallation saveInBackground];
    [PFUser logOut];
    [self.tabBarController dismissViewControllerAnimated:YES completion:NULL];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        //Confirm clicked
        NSString *emailEntered = [alertView textFieldAtIndex:0].text;
        NSString *emailOfUser = [PFUser currentUser].email;
        if ([emailEntered isEqualToString:emailOfUser]) {
            //email confirmed
            [self deleteUser];
        } else {
            //email incorrect
            UIAlertView *reenterEmail = [[UIAlertView alloc] initWithTitle:@"Wrong Email" message:@"This email is incorrect. Enter your email to confirm deletion." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
            reenterEmail.alertViewStyle = UIAlertViewStylePlainTextInput;
            [reenterEmail textFieldAtIndex:0].keyboardType = UIKeyboardTypeEmailAddress;
            [reenterEmail show];
        }
    }
}

-(void)deleteUser
{
    PFUser *currentUser = [PFUser currentUser];
    //Query all closets the curren user owns
    PFQuery *closetQuery = [PFQuery queryWithClassName:@"Closet"];
    [closetQuery whereKey:@"owner" equalTo:currentUser];
    [closetQuery findObjectsInBackgroundWithBlock:^(NSArray *closets, NSError *error) {
        //Query all transactions that are related to current user
        PFQuery *borrowerTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
        [borrowerTransactionQuery whereKey:@"borrower" equalTo:currentUser];

        PFQuery *ownerTransactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
        [ownerTransactionQuery whereKey:@"owner" equalTo:currentUser];

        PFQuery *transactionQuery = [PFQuery orQueryWithSubqueries:@[borrowerTransactionQuery, ownerTransactionQuery]];

        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *transactions, NSError *error) {
            //Query all follow objects that are related to current user
            PFQuery *toFollowQuery = [PFQuery queryWithClassName:@"Follow"];
            [toFollowQuery whereKey:@"to" equalTo:currentUser];

            PFQuery *fromFollowQuery = [PFQuery queryWithClassName:@"Follow"];
            [fromFollowQuery whereKey:@"from" equalTo:currentUser];

            PFQuery *followQuery = [PFQuery orQueryWithSubqueries:@[toFollowQuery, fromFollowQuery]];

            [followQuery findObjectsInBackgroundWithBlock:^(NSArray *follows, NSError *error) {

                PFQuery *likedItemQuery = [PFQuery queryWithClassName:@"Item"];
                [likedItemQuery whereKey:@"likeUser" equalTo:[PFUser currentUser]];

                [likedItemQuery findObjectsInBackgroundWithBlock:^(NSArray *likedItems, NSError *error) {
                    //Delete all transactions related to current user
                    [PFObject deleteAllInBackground:follows];

                    //Delete all transactions related to current user
                    [PFObject deleteAllInBackground:transactions];

                    //Query all items in each closet
                    for (PFObject *closet in closets) {
                        PFQuery *itemQuery = [[closet relationForKey:@"items"] query];
                        [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
                            //Delete the items
                            [PFObject deleteAllInBackground:items block:^(BOOL succeeded, NSError *error) {
                                //Delete the closet
                                [closet deleteInBackground];
                            }];
                        }];
                    }
                    //Delete all likes
                    for (PFObject *item in likedItems) {
                        [item incrementKey:@"likes" byAmount:@-1];
                        [item removeObject:[PFUser currentUser] forKey:@"likeUser"];
                        [item saveInBackground];
                    }

                    //Delete the current user
                    [currentUser deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        //Reset stored name for login view
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:@"" forKey:CLOSUsernamePrefsKey];
                        //Dismiss the tab bar to show the login view
                        [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
                    }];

                }];

            }];

        }];

    }];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [FBRequestConnection startWithGraphPath:@"/me?fields=name" parameters:nil HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            if (!error) {
                // URL should point to https://graph.facebook.com/{facebookId}/picture?height=200&width=200&return_ssl_resources=1
                NSURL *pictureURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?height=200&width=200&return_ssl_resources=1", result[@"id"]]];

                self.largeImageData = [[NSMutableData alloc] init];
                NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:pictureURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:2.0f];
                // Run network request asynchronously
                NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
                self.largeFbPictureConnection = urlConnection;
            } else if ([error.userInfo[FBErrorParsedJSONResponseKey][@"body"][@"error"][@"type"] isEqualToString:@"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
                [PFUser logOut];
                UIAlertView *invalidSession = [[UIAlertView alloc] initWithTitle:@"Invalid Facebook Session" message:@"The facebook session was invalidated. Please login again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [invalidSession show];
                [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Something Went Wrong" message:@"Reached an error while getting your profile picture." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [errorAlert show];

            }
        }];
    }
}

- (void) makeAndPresentFAQsView
{
    // make view to show the faqs
    UITextView *FAQs = [[UITextView alloc] initWithFrame:self.view.bounds];
    FAQs.editable = NO;
    FAQs.userInteractionEnabled = YES;
    
    NSMutableArray *questions = [NSMutableArray arrayWithArray:@[@"1. Who can see my profile?", @"2. Who can see my closets?", @"3. How can I make my account private?", @"4. Why do you want my location?", @"5. How do I change the location of a closet?", @"6. How do I report a user?", @"7. What if the person never actually gives me the items?", @"8. How do I change my profile picture?", @"9. Where can I see people that requested to follow me?"]];
    NSMutableArray *answers = [NSMutableArray arrayWithArray:@[@"If you keep your profile public, anyone can see your profile, but you can set individual closets to be private, which  means that only you can view those closets. If you make your profile private, other users must request to follow you, and you must confirm that request in order for them to see your closets. If your profile is private, then only your followers can view your public closets.",
                         @"For a public account, with public closets anyone using the app can see your closets. \n\
For a public account with private closets, only you can see your closets.\n \
For a private account, with public closets, only the followers whose requests you have accepted can view your closet.\n \
For a private account with private closets, only you can see your closets.",
                         @"You can got to Profile > More > Account Settings. Change the account privacy switch and then click 'save settings' when you are done.",
                         @"We use location services to allow you to set the location of your closet to your current location. We also use location services to help you find closets and items nearby to borrow. We do not store exact locations, we only store cities and neighborhoods.",
                         @"If you go to Profile > More > Account Settings > Edit Locations of Closets. you can select any number of closets that you would like to change the location of. Once, you have selected the closets, click Change Location and you can type in the location you would like to set and then click Save, or you can click Use Current Location to set the closet location to your current location. We only use the neighborhood or city you are located in, we do not store your exact location.",
                         @"Go to the user's profile and click on the ... in the upper righthand corner, then select Report This User and select one of the reasons and press Send and we will look into the user's behavior.",
                         @"We are not responsible for the transaction itself, our application is a platform to facilitate borrowing and lending but we leave it to the users to be responsible for the items.",
                         @"Go to your Profile and tap on your profile picture, and you can select one of the options to set your profile picture.",
                         @"If you have a private account, you can view your follow requests by going to Profile > Followers > See Pending Follow Requests and then you can Accept or Reject those requests."]];
    
    int numFAQs = (int)[questions count];
    for (int i = 0; i < numFAQs; i++) {
        NSString *str = questions[i];
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:21.0], NSForegroundColorAttributeName : [UIColor whiteColor]}];
        questions[i] = attrStr;
    }
    for (int i = 0; i < numFAQs; i++) {
        NSString *str = answers[i];
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:15.0], NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
        answers[i] = attrStr;
    }
    NSAttributedString *newLine = [[NSAttributedString alloc] initWithString:@"\n" attributes:nil];
    NSMutableAttributedString *attrText= [[NSMutableAttributedString alloc] init];
    for (int i = 0; i < numFAQs; i++) {
        [attrText appendAttributedString:questions[i]];
        [attrText appendAttributedString:newLine];
        [attrText appendAttributedString:answers[i]];
        [attrText appendAttributedString:newLine];
        [attrText appendAttributedString:newLine];
    }
    [attrText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n\nMore Questions? Go to http://lendapp.weebly.com/faq.html or email lendfbu@gmail.com" attributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:19.0], NSForegroundColorAttributeName : [UIColor whiteColor]}]];
    FAQs.attributedText = attrText;
    
    
    FAQs.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
    
    UIViewController *FAQsvc = [[UIViewController alloc] init];
    FAQsvc.view = FAQs;
    [self.navigationController pushViewController:FAQsvc animated:YES];
    
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
