//
//  CLOSCreateItemViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSCreateItemViewController.h"

#import "CLOSAddItemToClosetViewController.h"
#import "CLOSAppDelegate.h"
#import "CLOSCreateClosetViewController.h"
#import "CLOSIndividualClosetViewController.h"
@interface CLOSCreateItemViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *closetSelectedLabel;
@property (weak, nonatomic) IBOutlet UIButton *addToClosetButton;
@property (weak, nonatomic) IBOutlet UITextField *itemNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *takeAPhotoButton;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *retakeButton;
@property (nonatomic, assign) UIImagePickerController *imagePicker;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *closetSelectedStaticLabel;
@property (strong, nonatomic) UIAlertView *savingAlert;

typedef NS_ENUM(NSInteger, tutorialStates) {
    noClosets = 0,
    madeCloset = 1,
    viewedCloset = 2,
    madeItem = 3,
    sawMap = 4,
    sawClosetsNearby = 5,
    sawGroups = 6,
    done = 7
};

@end

@implementation CLOSCreateItemViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        // self.itemNameTextField.delegate
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // make compatible for 3.5 inch
    if ([UIScreen mainScreen].bounds.size.height != 568) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        sv.scrollEnabled = YES;
        sv.contentSize = CGSizeMake(320, 568);
        sv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
        [sv addSubview:self.view];
        self.view = sv;
    }

    
    self.itemNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"enter a name..." attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    
    //set up buttons
    self.doneButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.cancelButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.retakeButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.addToClosetButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.takeAPhotoButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    
    self.doneButton.titleLabel.textColor = [UIColor whiteColor];
    self.cancelButton.titleLabel.textColor = [UIColor whiteColor];
    self.retakeButton.titleLabel.textColor = [UIColor whiteColor];
    self.addToClosetButton.titleLabel.textColor = [UIColor whiteColor];
    
    // Do any additional setup after loading the view from its nib.
    if (self.image) self.imageView.image = self.image;
    self.descriptionTextView.layer.borderWidth = 0.5;
    self.descriptionTextView.layer.borderColor = [[UIColor grayColor] CGColor];
    
    [self.itemNameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void) viewWillAppear:(BOOL)animated
{
    // make sure interaction enabled
    self.view.userInteractionEnabled = YES;
    
    if (self.closet) {
        self.addToClosetButton.hidden = YES;
        self.closetSelectedLabel.text = self.closet[@"name"];
    }
    if (self.isGroupItem) {
        self.addToClosetButton.hidden = YES;
        self.closetSelectedLabel.text = self.group[@"name"];
        [self.closetSelectedStaticLabel setText:@"Group:"];
    }
    if (self.imageView.image == nil) {
        self.takeAPhotoButton.hidden = NO;
        self.retakeButton.hidden = YES;
    } else {
        self.takeAPhotoButton.hidden = YES;
        self.retakeButton.hidden = NO;
        self.retakeButton.titleLabel.textColor = [UIColor whiteColor];
    }
    if ([[self.itemNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]isEqualToString:@""] || (!self.closet && !self.isGroupItem)) // no name OR closet is nil and it's not a group item, then done can't be pressed
        self.doneButton.enabled = NO;
    else self.doneButton.enabled = YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (IBAction)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
}

-(void)textFieldDidChange:(UITextField *)textField
{
    if ([[self.itemNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        self.doneButton.enabled = NO;
    } else {
        if (self.closet || self.isGroupItem) {
            self.doneButton.enabled = YES;
        }
        else self.doneButton.enabled = NO;
    }
    
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)finishCreating:(id)sender {
    // don't allow double clicking
    self.view.userInteractionEnabled = NO;
    self.doneButton.enabled = NO;
    
    // set a timer to make sure save doesn't take too long
    NSTimeInterval t = 3.0;
    __block NSTimer *saveTimer = [NSTimer scheduledTimerWithTimeInterval:t
                                                                  target:self
                                                                selector:@selector(saveTakingTooLong:)
                                                                userInfo:nil
                                                                 repeats:NO];
    
    if (self.isGroupItem) { // save group item
        if (!self.imageView.image) { // if no image
            self.doneButton.enabled = YES;
            [self.doneButton setNeedsLayout];
            UIAlertView *takePhotoAlert = [[UIAlertView alloc] initWithTitle:@"Photo Missing" message:@"you must take a photo for your item!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Take A Photo", nil];
            [takePhotoAlert show];
            // re-enable interaction and stop timer
            self.view.userInteractionEnabled = YES;
            if ([saveTimer isValid]) {
                [saveTimer invalidate];
                saveTimer = nil;
            }
        }
        else {
            /* creating a new item */
            PFObject *sampleItem = [[PFObject alloc] initWithClassName:@"Item"];
            sampleItem[@"name"] = self.itemNameTextField.text;
            sampleItem[@"lowercaseName"] = [self.itemNameTextField.text lowercaseString];
            sampleItem[@"description"] = self.descriptionTextView.text;
            sampleItem[@"lowercaseDescription"] = [self.descriptionTextView.text lowercaseString];
            // always in a "private closet"
            sampleItem[@"isInPrivateCloset"] = @YES;
            
            /* start image */
            NSData *imageData = UIImageJPEGRepresentation(self.image, 0.85f);
            
            PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
            [imageFile saveInBackground];
            
            [sampleItem setObject:imageFile forKey:@"itemImage"];
            
            /* end image */
            
            PFRelation *itemToUser = [sampleItem relationForKey:@"owner"];
            [itemToUser addObject:[PFUser currentUser]];
            self.cancelButton.enabled = NO;
            sampleItem[@"ownerUsername"] = [PFUser currentUser].username;
            [sampleItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if ([saveTimer isValid]) {
                    [saveTimer invalidate];
                    saveTimer = nil;
                }
                if (error) {
                    [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
                    UIAlertView *tryAgainAlert = [[UIAlertView alloc] initWithTitle:@"Try again?"
                                                                            message:@"Save failed. Would you like to try again?"
                                                                           delegate:self cancelButtonTitle:@"Cancel"
                                                                  otherButtonTitles:@"Try Again", nil];
                    [tryAgainAlert show];
                    tryAgainAlert.tag = 404;
                    self.view.userInteractionEnabled = YES;
                }
                else {
                    [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
                    //PFUser *currentUser = [PFUser currentUser];
                    //[currentUser incrementKey:@"weightedActivity"]; // TODO: decide this
                    //[currentUser saveInBackground];
                    PFRelation *itemsRelation = [self.group relationForKey:@"items"];
                    [itemsRelation addObject:sampleItem];
                    [self.group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                    }];
                }
            }];
            
            /* end creating a new item */
            
        }
    }
    else if (self.presentingViewController.presentingViewController &&
             [self.presentingViewController class] == [UIImagePickerController class]) {
        //Came from image picker / camera tab
        PFObject *sampleItem = [self createItem];
        [sampleItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if ([saveTimer isValid]) {
                [saveTimer invalidate];
                saveTimer = nil;
            }
            if (error) {
                [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
                UIAlertView *tryAgainAlert = [[UIAlertView alloc] initWithTitle:@"Try again?"
                                                                        message:@"Save failed. Would you like to try again?"
                                                                       delegate:self cancelButtonTitle:@"Cancel"
                                                              otherButtonTitles:@"Try Again", nil];
                [tryAgainAlert show];
                tryAgainAlert.tag = 404;
                self.view.userInteractionEnabled = YES;
            }
            else {
                [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
                PFUser *currentUser = [PFUser currentUser];
                if ([currentUser[@"tutorialState"] isEqual:@(viewedCloset)]) { // need to update tutorial state
                    currentUser[@"tutorialState"] = @(madeItem);
                }
                [currentUser incrementKey:@"weightedActivity"];
                [currentUser saveInBackground];
                PFRelation *closetToItems = [self.closet relationForKey:@"items"];
                [closetToItems addObject:sampleItem];
                [self.closet saveInBackgroundWithBlock:^(BOOL success, NSError *errorCloset) {
                    CLOSIndividualClosetViewController *closetvc = [[CLOSIndividualClosetViewController alloc] init];
                    
                    UITabBarController *tabBar = (UITabBarController *)(self.presentingViewController.presentingViewController);
                    tabBar.selectedIndex = 4;

                    tabBar.selectedViewController.hidesBottomBarWhenPushed = NO;
                    closetvc.closet = self.closet;

                    [tabBar dismissViewControllerAnimated:YES completion:^{
                        [(UINavigationController *)tabBar.selectedViewController popToRootViewControllerAnimated:NO];
                        [(UINavigationController *)tabBar.selectedViewController pushViewController:closetvc animated:YES];
                    }];
                }];

                /* end creating a new item */
            }

        }];
    }

    else
    {
        if (!self.imageView.image) {
            self.doneButton.enabled = YES;
            [self.doneButton setNeedsLayout];
            UIAlertView *takePhotoAlert = [[UIAlertView alloc] initWithTitle:@"Photo Missing" message:@"you must take a photo for your item!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Take A Photo", nil];
            [takePhotoAlert show];
            // re-enable interaction and stop timer
            self.view.userInteractionEnabled = YES;
            if ([saveTimer isValid]) {
                [saveTimer invalidate];
                saveTimer = nil;
            }
        }
        else {
            PFObject *sampleItem = [self createItem];
            [sampleItem saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if ([saveTimer isValid]) {
                    [saveTimer invalidate];
                    saveTimer = nil;
                }
                if (error) {
                    [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
                    UIAlertView *tryAgainAlert = [[UIAlertView alloc] initWithTitle:@"Try again?"
                                                                            message:@"Save failed. Would you like to try again?"
                                                                           delegate:self cancelButtonTitle:@"Cancel"
                                                                  otherButtonTitles:@"Try Again", nil];
                    [tryAgainAlert show];
                    tryAgainAlert.tag = 404;
                    self.view.userInteractionEnabled = YES;
                }
                else {
                    [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
                    PFUser *currentUser = [PFUser currentUser];
                    if ([currentUser[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:viewedCloset]]) { // need to update tutorial state
                        currentUser[@"tutorialStage"] = [NSNumber numberWithInteger:madeItem];
                    }
                    [currentUser incrementKey:@"weightedActivity"];
                    [currentUser saveInBackground];
                    PFRelation *closetToItems = [self.closet relationForKey:@"items"];
                    [closetToItems addObject:sampleItem];
                    [self.closet saveInBackgroundWithBlock:^(BOOL success, NSError *errorCloset) {
                        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
                    }];
                }
            }];
        }
    }
}

-(PFObject *)createItem
{
    self.cancelButton.enabled = NO;
    /* creating a new item */
    PFObject *sampleItem = [[PFObject alloc] initWithClassName:@"Item"];
    sampleItem[@"name"] = self.itemNameTextField.text;
    sampleItem[@"lowercaseName"] = [self.itemNameTextField.text lowercaseString];
    sampleItem[@"description"] = self.descriptionTextView.text;
    sampleItem[@"lowercaseDescription"] = [self.descriptionTextView.text lowercaseString];
    //Check whether the closet is public or private and save the item field accordingly
    sampleItem[@"isInPrivateCloset"] = self.closet[@"isPrivate"];
    //check if the closet has a location and save the item location field accordingly
    if (self.closet[@"geopoint"] != nil) {
        sampleItem[@"geopoint"] = self.closet[@"geopoint"];
        sampleItem[@"locationArray"] = self.closet[@"FormattedAddressLines"];
    }
    sampleItem[@"likes"] = @0;

    NSData *imageData = UIImageJPEGRepresentation(self.image, 0.85f);
    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
    [imageFile saveInBackground];

    [sampleItem setObject:imageFile forKey:@"itemImage"];

    /* end image */

    PFRelation *itemToUser = [sampleItem relationForKey:@"owner"];
    [itemToUser addObject:[PFUser currentUser]];
    sampleItem[@"ownerUsername"] = [PFUser currentUser].username;

    return sampleItem;
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag != 404) {
        if (buttonIndex == 1) {
            [self takePicture:self.takeAPhotoButton];
        }
    }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 404) { // save failed, cancel or try again
        if (buttonIndex == alertView.cancelButtonIndex) { // cancel, so hide the alert and re-enable the view
            self.view.userInteractionEnabled = YES;
            self.doneButton.enabled = YES;
            self.cancelButton.enabled = YES;
        }
        else { // try save again
            [self finishCreating:NULL];
        }
    }
}

- (void) saveTakingTooLong:(id) sender
{
    self.savingAlert = [[UIAlertView alloc] initWithTitle:@"Saving..."
                                                  message:@"Your connection seems to be slow. Trying to save."
                                                 delegate:self
                                        cancelButtonTitle:nil
                                        otherButtonTitles:nil];
    [self.savingAlert show];
}

- (IBAction)cancelPressed:(id)sender
{
    // don't allow double clicking
    self.view.userInteractionEnabled = NO;
    
    if (self.presentingViewController.presentingViewController && [self.presentingViewController class] == [UIImagePickerController class]) {
        UITabBarController *tabBar = (UITabBarController *)(self.presentingViewController.presentingViewController);
        tabBar.selectedIndex = ((CLOSAppDelegate *)[UIApplication sharedApplication].delegate).previousIndex;
        
        [tabBar dismissViewControllerAnimated:YES completion:NULL];
    }
    else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
    }
}


- (IBAction)addToCloset:(id)sender {
    // don't allow double clicking
    self.view.userInteractionEnabled = NO;
    
    CLOSAddItemToClosetViewController *addItemvc = [[CLOSAddItemToClosetViewController alloc] init];
    [self presentViewController:addItemvc animated:YES completion:NULL];
}

- (IBAction)takePicture:(id)sender
{
    // don't allow double clicking
    self.view.userInteractionEnabled = NO;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = YES;
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(180, 0, 80, 40);
        [button setAttributedTitle:[[NSAttributedString alloc] initWithString:@"To Library" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                                         NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0]}]
                          forState:UIControlStateNormal];
        imagePicker.cameraOverlayView = button;
        [button addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    else {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;
    self.imagePicker = imagePicker;
    
    [self presentViewController:imagePicker animated:YES completion:^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOverlay) name:@"_UIImagePickerControllerUserDidCaptureItem" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addOverlay) name:@"_UIImagePickerControllerUserDidRejectItem" object:nil];
    }];
}

-(void)removeOverlay
{
    //camera is in editing mode; remove library button
    self.imagePicker.cameraOverlayView = nil;
}

-(void)addOverlay
{
    //camera is in picture taking mode after cancelling previous image; add library button
    NSAttributedString *buttonString = [[NSAttributedString alloc] initWithString:@"To Library" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    UIButton *button = [[UIButton alloc] init];
    button.frame = CGRectMake(180, 0, 80, 40);
    [button setAttributedTitle:buttonString forState:UIControlStateNormal];
    self.imagePicker.cameraOverlayView = button;
    [button addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    self.imageView.image = image;
    self.image = image;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:NULL];
}
-(void)switchCamera:(id)sender
{
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
