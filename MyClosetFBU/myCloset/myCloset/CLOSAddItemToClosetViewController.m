//
//  CLOSAddItemToClosetViewController.m
//  myCloset
//
//  Created by Samantha Wiener on 7/11/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSAddItemToClosetViewController.h"
#import "CLOSProfileViewController.h"
#import <Parse/Parse.h>
#import "CLOSClosetCell.h"
#import "CLOSCreateClosetViewController.h"
#import "CLOSCreateItemViewController.h"

@interface CLOSAddItemToClosetViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) PFUser *user;
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) NSArray *myClosets;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic) PFObject *selectedCloset;

@end

@implementation CLOSAddItemToClosetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)addItemCloset:(id)sender {
    //Switch to create closet view control
    CLOSCreateClosetViewController *createClosetvc = [[CLOSCreateClosetViewController alloc] init];
    [self presentViewController:createClosetvc animated:YES completion:NULL];

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    PFRelation *relation = [self.user relationForKey:@"ownedClosets"];
    PFQuery *query = [relation query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.myClosets = objects;
        [self.collectionView reloadData];
    }];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view from its nib.
    
    //Register nib
    UINib *cellNib = [UINib nibWithNibName:@"CLOSClosetCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ClosetCell"];

    //Set flow layout
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(150, 150)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];

    //Set screen title
    self.user = [PFUser currentUser];
    NSString *username = [NSString stringWithFormat:@"%@'s closets",self.user.username];
    self.navBar.topItem.title = username;
    
    //Enforce single selection
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = NO;
    
    //Disable done button
    self.doneButton.enabled = NO;
    

    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ClosetCell" forIndexPath:indexPath];

    //Set the title
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    PFObject *closet = (PFObject *)self.myClosets[indexPath.row];
    titleLabel.text = closet[@"name"];

    //Get the image of the closet
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:50];
    NSNumber *closetDoorPhotoNumber = closet[@"photoNumber"];
    int number = [closetDoorPhotoNumber intValue];
    switch (number) {
        case 1:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[1].jpg"]];
            break;
        case 2:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[2].jpg"]];
            break;
        case 3:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[3].jpg"]];
            break;
        case 4:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[4].jpg"]];
            break;
        case 5:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[5].jpg"]];
            break;
        default:
            [imageView setImage:[UIImage imageNamed:@"closetDoor[0].jpg"]];
            break;
    }

    //if selected, highlight it
    if ([closet isEqual:self.selectedCloset]) {
        cell.alpha = 0.4;
    } else {
        cell.alpha = 1.0;
    }
    
    return cell;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

-(BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (!collectionView.indexPathsForSelectedItems || [collectionView.indexPathsForSelectedItems count] == 0) {
        //there are no selected items - select the item
        return YES;
    }
    if (((NSIndexPath *)((collectionView.indexPathsForSelectedItems)[0])).row == indexPath.row) {
        //the already selected item is the same as the item touched - deselect the item instead
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        [self.collectionView cellForItemAtIndexPath:indexPath].alpha = 1.0;
        //since no selected item, disable done button
        self.doneButton.enabled = NO;
        return NO;
    }
    //already selected item is not the same as currently selected item - select the touched item and deselect the already selected item (single selection enforced)
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCloset = self.myClosets[indexPath.row];
    self.doneButton.enabled = YES;
    [self.collectionView cellForItemAtIndexPath:indexPath].alpha = 0.4;
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self.collectionView cellForItemAtIndexPath:indexPath].alpha = 1.0;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.myClosets count];
}

- (IBAction)donePressed:(id)sender
{
    //Pass information to create item view controller
    PFObject *selectedCloset = self.myClosets[((NSIndexPath *)(self.collectionView.indexPathsForSelectedItems[0])).row];
    ((CLOSCreateItemViewController *)(self.presentingViewController)).closet = selectedCloset;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)canelPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
