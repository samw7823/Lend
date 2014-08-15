//
//  CLOSCameraViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSCameraViewController.h"
#import "CLOSCreateItemViewController.h"
#import "CLOSAppDelegate.h"

@interface CLOSCameraViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic) UIImagePickerController *imagePicker;


@end

@implementation CLOSCameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.window.frame.size.width, self.view.window.frame.size.height)];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.image = [UIImage imageNamed:@"dark-brown-wood-bg.jpg"];
        self.view = imageView;

    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //set the navigation bar to black
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

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

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeOverlay) name:@"_UIImagePickerControllerUserDidCaptureItem" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addOverlay) name:@"_UIImagePickerControllerUserDidRejectItem" object:nil];
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.navigationBar.titleTextAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:20.0]};
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        //Open camera
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = YES;

        //Set overlay button to go to library
        NSAttributedString *buttonString = [[NSAttributedString alloc] initWithString:@"To Library" attributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(180, 0, 80, 40);
        [button setAttributedTitle:buttonString forState:UIControlStateNormal];
        imagePicker.cameraOverlayView = button;
        [button addTarget:self action:@selector(switchCamera:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        //Open photo library
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    imagePicker.allowsEditing = YES;
    imagePicker.delegate = self;

    self.imagePicker = imagePicker;
    //TODO: try to figure out why camera would throw error "Snapshotting a view that has not been rendered results in an empty snapshot" when phone is in landscape
    //Present the image picker
    [self presentViewController:imagePicker animated:YES completion:NULL];


}

-(void)switchCamera:(id)sender
{
    //Overlay button is pressed - go to the library
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //Get picked image from info dictionary and create a new item
    UIImage *image = info[UIImagePickerControllerEditedImage];
    CLOSCreateItemViewController *createItemvc = [[CLOSCreateItemViewController alloc] init];
    createItemvc.image = image;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [picker presentViewController:createItemvc animated:YES completion:NULL];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    NSInteger previousIndex = ((CLOSAppDelegate *)[[UIApplication sharedApplication] delegate]).previousIndex;
    [self.tabBarController setSelectedIndex:previousIndex];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.tabBarController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
