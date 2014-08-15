//
//  CLOSCreateGroupViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSCreateGroupViewController.h"

#import <Parse/Parse.h>

#import "CLOSAddMemberToGroupViewController.h"

@interface CLOSCreateGroupViewController ()<UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *groupNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *addMembersButton;
@property (weak, nonatomic) IBOutlet UIButton *takePhotoButton;
@property (weak, nonatomic) IBOutlet UIButton *retakePhotoButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIImage *image;

@end

@implementation CLOSCreateGroupViewController

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

    self.groupNameTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"enter a name..." attributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    //set up buttons
    self.retakePhotoButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.addMembersButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.takePhotoButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.retakePhotoButton.titleLabel.textColor = [UIColor whiteColor];
    self.addMembersButton.titleLabel.textColor = [UIColor whiteColor];
    self.takePhotoButton.titleLabel.textColor = [UIColor whiteColor];
    [[self.takePhotoButton layer] setBorderWidth:2.0f];
    [[self.takePhotoButton layer] setBorderColor:[UIColor whiteColor].CGColor];

    [self.groupNameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    //Add an image view to the scroll view
    UIImageView *imageView = [[UIImageView alloc] init];
    self.imageView = imageView;
    [self.scrollView addSubview:imageView];
    self.scrollView.delegate = self;

    //add tap gesture recognizer to dismiss keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.imageView.image == nil) {
        self.takePhotoButton.hidden = NO;
        self.retakePhotoButton.hidden = YES;
    } else {
        self.takePhotoButton.hidden = YES;
        self.retakePhotoButton.hidden = NO;
        self.retakePhotoButton.titleLabel.textColor = [UIColor whiteColor];
    }
    if ([[self.groupNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]isEqualToString:@""]){
        self.doneButton.enabled = NO;
    }
    else {
        self.doneButton.enabled = YES;
    }

}
-(void)textFieldDidChange:(UITextField *)textField
{
    //check for group name
    if ([[self.groupNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""]) {
        self.doneButton.enabled = NO;
    } else {
        self.doneButton.enabled = YES;
    }

}
- (IBAction)finishCreatingGroup:(id)sender {
    self.doneButton.enabled = NO;
    self.view.userInteractionEnabled = NO;
    if (!self.imageView.image) {
        self.doneButton.enabled = YES;
        UIAlertView *takePhotoAlert = [[UIAlertView alloc] initWithTitle:@"Photo Missing" message:@"you must choose a photo for your group!" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Take A Photo", nil];
        [takePhotoAlert show];
        self.view.userInteractionEnabled = YES;
        self.doneButton.enabled = YES;
    }
    else {
        //create a new group
        PFObject *sampleGroup = [[PFObject alloc] initWithClassName:@"Group"];
        sampleGroup[@"name"] = self.groupNameTextField.text;
        //get image
        CGFloat zoomScale = 1.0f/self.scrollView.zoomScale;
        CGImageRef cr = CGImageCreateWithImageInRect([self.imageView.image CGImage], CGRectMake(self.scrollView.contentOffset.x * zoomScale, self.scrollView.contentOffset.y * zoomScale, self.scrollView.bounds.size.width * zoomScale, self.scrollView.bounds.size.height * zoomScale));
        UIImage *croppedImage = [[UIImage alloc] initWithCGImage:cr];
        NSData *imageData = UIImageJPEGRepresentation(croppedImage, 0.85f);
        PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
        [imageFile saveInBackground];
        [sampleGroup setObject:imageFile forKey:@"coverPhoto"];
        PFRelation *memberRelation = [sampleGroup relationForKey:@"members"];
        [memberRelation addObject:[PFUser currentUser]];
        //check if there are other members to add to the group
        if ([self.members count] >= 1) {
            for (PFUser *member in self.members) {
                [memberRelation addObject:member];
                //TODO: think about where to display added members
            }
        }
        sampleGroup[@"numberOfMembers"] = @([self.members count]);
        [sampleGroup saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if ([self.members count] >= 1) {
                /* send push notification to the people added */
                PFQuery *pushQuery = [PFInstallation query];
                [pushQuery whereKey:@"username" containedIn:[self.members valueForKey:@"username"]];

                // Send push notification to query
                PFPush *push = [[PFPush alloc] init];
                [push setQuery:pushQuery]; // Set our Installation query

                NSString *message = [NSString stringWithFormat:@"%@ added you to the group %@", [PFUser currentUser].username, sampleGroup[@"name"]];
                [push setMessage:message];
                [push sendPushInBackground];
            }

            [self dismissViewControllerAnimated:YES completion:NULL];

        }];
    }

}
- (IBAction)backgroundTapped:(id)sender
{
    [self.view endEditing:YES];
}
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self takePhoto:self.takePhotoButton];
    }
}
- (IBAction)cancelPressed:(id)sender {

    [self dismissViewControllerAnimated:YES completion:NULL];
}
- (IBAction)addMembers:(id)sender {
    //go to add members to group vc
    [self.view endEditing:YES];

    CLOSAddMemberToGroupViewController *addMembervc = [[CLOSAddMemberToGroupViewController alloc] init];
    //pass the group
    addMembervc.alreadyMembers = self.members;
    [self presentViewController:addMembervc animated:YES completion:NULL];
}
- (IBAction)takePhoto:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    //if its a camera source
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = YES;
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(180, 0, 80, 40);
        [button setAttributedTitle:[[NSAttributedString alloc] initWithString:@"To Library" attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0]}]forState:UIControlStateNormal];
        imagePicker.cameraOverlayView = button;
        [button addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    }
    else{
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    imagePicker.delegate = self;
    self.imagePicker = imagePicker;

    [self presentViewController:imagePicker animated:YES completion:^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOverlay) name:@"_UIImagePickerControllerUserDidCaptureItem" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addOverlay) name:@"_UIImagePickerControllerUserDidRejectItem" object:nil];
    }];
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //resize the image to fit the size of the screen
    CGFloat height = image.size.height;
    CGFloat width = image.size.width;
    CGFloat imgFactor = height / width;
    UIGraphicsBeginImageContext(CGSizeMake([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * imgFactor));
    [image drawInRect:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width * imgFactor)];
    UIImage *smallImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.scrollView.contentSize = smallImage.size;
    self.imageView.frame = CGRectMake(0, 0, smallImage.size.width, smallImage.size.height);
    self.imageView.image = smallImage;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:NULL];
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

-(void)switchCamera:(id)sender
{
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
