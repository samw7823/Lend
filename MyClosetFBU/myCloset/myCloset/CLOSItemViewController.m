//
//  CLOSItemViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSItemViewController.h"
#import "CLOSCreateItemViewController.h"
#import "CLOSIndividualClosetViewController.h"
#import "CLOSBorrowViewController.h"
#import <Parse/Parse.h>
#import "CLOSProfileViewController.h"

@interface CLOSItemViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>


@property (weak, nonatomic) IBOutlet UIImageView *itemImage;
@property (weak, nonatomic) IBOutlet UIButton *itemOwnerButton;

@property (strong, nonatomic) UIImage *originalImage;

@property (strong, nonatomic) PFUser *ownerOfItem;
@property (weak, nonatomic) IBOutlet UITextView *itemDescription;
@property (weak, nonatomic) IBOutlet UIButton *requestToBorrowButton;
@property (weak, nonatomic) IBOutlet UILabel *itemOwnerLabel;
@property (weak, nonatomic) IBOutlet UILabel *editNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *editNameTextField;
@property (weak, nonatomic) IBOutlet UIButton *retakePhotoButton;
@property (weak, nonatomic) IBOutlet UILabel *isCurrentlyBorrowedLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationString;
@property (nonatomic) UIImagePickerController *imagePicker;


@end

@implementation CLOSItemViewController

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
    
    // make compatible for 3.5 inch
    if ([UIScreen mainScreen].bounds.size.height != 568) {
        UIScrollView *sv = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        sv.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-brown-wood-bg.jpg"]];
        sv.scrollEnabled = YES;
        sv.contentSize = CGSizeMake(320, 568);
        [sv addSubview:self.view];
        self.view = sv;
    }
    
    // Do any additional setup after loading the view from its nib.
    //make buttons round
    self.itemOwnerButton.layer.cornerRadius = 8.0f;

    //Set appearance for text field with boder
    self.itemDescription.layer.borderWidth = 0.5;
    self.itemDescription.layer.borderColor = [[UIColor grayColor] CGColor];
    //Hide all buttons initially
    self.requestToBorrowButton.hidden = YES;
    self.editNameLabel.hidden = YES;
    self.editNameTextField.hidden = YES;
    self.retakePhotoButton.hidden = YES;
    self.isCurrentlyBorrowedLabel.hidden = YES;
    //Fetch the item needed to display
    [self.item fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        //Get owner name
        PFRelation *ownerRelation = [self.item relationForKey:@"owner"];
        PFQuery *query = [ownerRelation query];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *owner, NSError *error) {
            PFUser *ownerOb = (PFUser *)owner;
            
            self.ownerOfItem = ownerOb;
            if ([ownerOb.username isEqualToString:[PFUser currentUser].username]) { // current user owns this item
                //make an edit button
                UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStylePlain target:self action:@selector(edit:)];
                self.navigationItem.rightBarButtonItem = editButton;
                self.requestToBorrowButton.hidden = YES;
                self.navigationItem.rightBarButtonItem.enabled = YES;
                self.navigationItem.rightBarButtonItem.style = UIBarButtonItemStyleBordered;
                
            } else { // someone else's item
                self.requestToBorrowButton.hidden = NO;
            }
            //Set owner's name in item owner button and adjust its size
            [self.itemOwnerButton setTitle:ownerOb.username forState:UIControlStateNormal];
            [self.itemOwnerButton sizeToFit];
            CGRect frame = self.itemOwnerButton.layer.frame;
            frame.size.width += 10;
            self.itemOwnerButton.layer.frame = frame;
        }];

        //Set location string
        NSArray *locationStrings = self.item[@"locationArray"];
        if (locationStrings == nil) {
            self.locationString.text = @"Unknown";
        } else {
            NSMutableString *locationString = [NSMutableString string];
            for (NSString *string in locationStrings) {
                [locationString appendString:string];
                [locationString appendString:@" "];
            }
            self.locationString.text = locationString;
        }
        if ([self.item[@"isBorrowed"] isEqual:@TRUE]) {
            //Hide borrow label
            self.isCurrentlyBorrowedLabel.hidden = NO;
        }
        //Set entire screen's name
        self.navigationItem.title = self.item[@"name"];
        //Set item description
        self.itemDescription.attributedText = [[NSAttributedString alloc] initWithString:self.item[@"description"] attributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
        //Fetch the image of the item and display it
        PFFile *imageFile = self.item[@"itemImage"];
        [imageFile getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error) {
            UIImage *image = [UIImage imageWithData:imageData];
            self.itemImage.image = image;
            self.originalImage = image;
        }];

    }];

    //Add tap recognizer to dismiss keyboard
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(backgroundTouched)];
    [self.view addGestureRecognizer:tap];

    UITapGestureRecognizer *tapImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewImageFullScreen:)];
    [self.itemImage addGestureRecognizer:tapImage];

}

-(void)viewWillAppear:(BOOL)animated
{
    // prepare for editing when a text field is editable
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveUp:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moveDown:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)backgroundTouched
{
    [self.view endEditing:YES];
}
- (IBAction)requestToBorrow:(id)sender
{
    
    //go to BorrowViewController and pass item information
    CLOSBorrowViewController *borrowvc = [[CLOSBorrowViewController alloc] init];
    borrowvc.itemName = self.item[@"name"];
    borrowvc.item = self.item;
    borrowvc.itemOwner = self.ownerOfItem;
    [self.navigationController presentViewController:borrowvc animated:YES completion:NULL];
    
    
}
- (IBAction)delete:(id)sender {
    ((UIButton *)sender).enabled = NO;
    [self.item deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        PFQuery *transactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
        [transactionQuery whereKey:@"item" equalTo:self.item];
        //Find all transactions related to this item here
        [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            //delete these transactions
            [PFObject deleteAllInBackground:objects];
        }];

        [self.navigationController popViewControllerAnimated:YES];
    }];
    
}


- (void)viewImageFullScreen:(id)sender
{
    // create a view controller to modally present that is a full screen image view
    UIViewController *viewController = [[UIViewController alloc] init];
    
    // make the view a control so that when the user taps the photo it goes away (this view controller is dismissed)
    CGSize sizeOfScreen = [[UIScreen mainScreen] bounds].size;
    int width = sizeOfScreen.width;
    int height = sizeOfScreen.height;
    
    UIControl *control = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    [control addTarget:self action:@selector(removeFullScreenImage:) forControlEvents:UIControlEventTouchUpInside];
    control.backgroundColor = [UIColor blackColor];
    viewController.view = control;
    
    //set up image view and add it to the control
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.itemImage.image];

    imageView.frame = CGRectMake(0, (height - width) / 2, width, width);
    
    [control addSubview:imageView];
    
    [self.navigationController presentViewController:viewController animated:YES completion:NULL];
}

- (IBAction)removeFullScreenImage:(id)sender
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)edit:(id)sender
{
    //start editing
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Edit"]) {
        [self.navigationItem.rightBarButtonItem setTitle:@"Done"];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(delete:)];
        self.itemDescription.userInteractionEnabled = YES;
        self.itemDescription.editable = YES;
        self.itemOwnerButton.hidden = YES;
        self.itemOwnerLabel.hidden = YES;
        self.itemImage.userInteractionEnabled = NO;
        self.editNameLabel.hidden = NO;
        self.editNameTextField.hidden = NO;
        self.retakePhotoButton.hidden = NO;
        
        self.editNameTextField.text = self.navigationItem.title;
        [self.navigationItem setTitle:@"Edit Item"];
        
    }
    else { //end editing
        [self.navigationItem.rightBarButtonItem setTitle:@"Edit"];
        self.navigationItem.leftBarButtonItem = nil;
        self.itemDescription.editable = NO;
        self.itemOwnerButton.hidden = NO;
        self.itemOwnerLabel.hidden = NO;
        self.itemImage.userInteractionEnabled = YES;
        self.editNameLabel.hidden = YES;
        self.editNameTextField.hidden = YES;
        self.retakePhotoButton.hidden = YES;
        
        self.item[@"description"] = self.itemDescription.text;
        self.item[@"name"] = self.editNameTextField.text;
        
        if (![self.originalImage isEqual:self.itemImage.image]) {
            NSData *imageData = UIImageJPEGRepresentation(self.itemImage.image, 0.85f);
            
            PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
            [imageFile saveInBackground];
        
            [self.item setObject:imageFile forKey:@"itemImage"];
        }
        
        [self.navigationItem setTitle:self.editNameTextField.text];
        [self.item saveInBackground];
        
        if ([self.editNameTextField isFirstResponder])
            [self.editNameTextField resignFirstResponder];
        [self.view endEditing:YES];
    }
    
}

- (IBAction)takePicture:(id)sender
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.navigationBar.titleTextAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0]};

    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = YES;

        //Set overlay button to go to library
        NSAttributedString *buttonString = [[NSAttributedString alloc] initWithString:@"To Library" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(180, 0, 80, 40);
        [button setAttributedTitle:buttonString forState:UIControlStateNormal];
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

-(void)switchCamera:(id)sender
{
    //Overlay button is pressed - go to the library
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    self.itemImage.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}



- (IBAction)goToOwnersProfile:(id)sender
{
    CLOSProfileViewController *profilevc = [[CLOSProfileViewController alloc] init];
    profilevc.user = self.ownerOfItem;
    
    [self.navigationController pushViewController:profilevc animated:YES];

}

- (IBAction)backgroundTapped:(id)sender
{
    // end editing of a text box or text field if in edit mode
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"done"]) {
        if ([self.editNameTextField isFirstResponder])
            [self.editNameTextField resignFirstResponder];
        [self.view endEditing:YES];
    }
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
    
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y - keyboardFrame.size.height + self.tabBarController.tabBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
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
    
    [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + keyboardFrame.size.height - self.tabBarController.tabBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)];
    [UIView commitAnimations];
}

@end
