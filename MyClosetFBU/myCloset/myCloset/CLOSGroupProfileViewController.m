//
//  CLOSGroupProfileViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSGroupProfileViewController.h"

#import "CLOSAddMemberToGroupViewController.h"
#import "CLOSCreateItemViewController.h"
#import "CLOSGroupSearchViewController.h"
#import "CLOSItemViewController.h"
#import "CLOSLikesViewController.h"

@interface CLOSGroupProfileViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UIActionSheetDelegate, UIAlertViewDelegate>

// group properties
@property (weak, nonatomic) IBOutlet UIImageView *coverPhotoImageView;
@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;

// buttons
@property (weak, nonatomic) IBOutlet UIButton *createItemButton;
@property (weak, nonatomic) IBOutlet UIButton *seeMembersButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

// collection view
@property (strong, nonatomic) NSArray *items;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;


@end

@implementation CLOSGroupProfileViewController

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
    
    // set display options -- group name and cover photo
    self.groupNameLabel.text = self.group[@"name"];
    
    PFFile *coverPhotoImageFile = self.group[@"coverPhoto"];
    [coverPhotoImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        self.coverPhotoImageView.image = [UIImage imageWithData:data];
    }];
    
    self.navigationItem.title = self.group[@"name"];

    // set up collection view cells and collection view
    UINib *cellNib = [UINib nibWithNibName:@"CLOSClosetCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ClosetCell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(150, 150)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    

    // set up options button
    UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStyleBordered target:self action:@selector(options:)];
    [optionsButton setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor],
                                            NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:21.0]}
                                 forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = optionsButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // get items in the group
    PFRelation *itemsRelation = self.group[@"items"];
    PFQuery *itemsQuery = [itemsRelation query];
    [itemsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.items = objects;
            [self.collectionView reloadData];
        }
    }];
}


// collection view
- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue cell and get pointers to its label and imageview
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ClosetCell" forIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:50];
    
    // set displays on cell
    PFObject *item = self.items[indexPath.row];
    titleLabel.text = item[@"name"];
    PFFile *itemPhoto = item[@"itemImage"];
    [itemPhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        imageView.image = [UIImage imageWithData:data];
    }];
    
    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // number of items in the group
    return [self.items count];
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSItemViewController *itemvc = [[CLOSItemViewController alloc] init];
    itemvc.item = self.items[indexPath.row];
    [self.navigationController pushViewController:itemvc animated:YES];
}

- (IBAction)search:(id)sender
{
    // launch search page
    CLOSGroupSearchViewController *groupSearchvc = [[CLOSGroupSearchViewController alloc] init];
    groupSearchvc.group = self.group;
    groupSearchvc.groupItems = self.items;
    [self.navigationController pushViewController:groupSearchvc animated:YES];
}

- (IBAction)seeMembers:(id)sender
{
    // get members
    PFRelation *membersRelation = self.group[@"members"];
    PFQuery *membersQuery = [membersRelation query];
    [membersQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        // launch the likes view controller to display the members
        CLOSLikesViewController *likesvc = [[CLOSLikesViewController alloc] init];
        likesvc.likeUsers = objects;
        // make sure vc sets it's title appropriately
        likesvc.isGroupMembers = YES;
        [self.navigationController pushViewController:likesvc animated:YES];
    }];
}

- (IBAction)createItem:(id)sender
{
    CLOSCreateItemViewController *createItemvc = [[CLOSCreateItemViewController alloc] init];
    createItemvc.isGroupItem = YES;
    createItemvc.group = self.group;
    [self presentViewController:createItemvc animated:YES completion:NULL];
    
}

- (IBAction)options:(id)sender
{
    UIActionSheet *optionsSheet = [[UIActionSheet alloc] initWithTitle:@"Options"
                                                              delegate:self
                                                     cancelButtonTitle:@"Go Back"
                                                destructiveButtonTitle:@"Leave this Group"
                                                     otherButtonTitles:@"Add Members", nil];
    optionsSheet.tag = 23;
    [optionsSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 23) { // options action sheet
        if (buttonIndex == actionSheet.destructiveButtonIndex) { // pressed leave group. send an alert to confirm
            UIAlertView *confirmLeaveGroupAlert = [[UIAlertView alloc] initWithTitle:@"Leave This Group?" message:@"You will no longer have access to this group and this action cannot be undone."
                                                                            delegate:self
                                                                   cancelButtonTitle:@"Cancel"
                                                                   otherButtonTitles:@"Leave Group", nil];
            confirmLeaveGroupAlert.tag = 43;
            [confirmLeaveGroupAlert show];
        }
        else if (buttonIndex == 1){ // want to add members
            CLOSAddMemberToGroupViewController *addMembersvc = [CLOSAddMemberToGroupViewController new];
            addMembersvc.group = self.group;
            [self presentViewController:addMembersvc animated:YES completion:nil];
        }
    }
}

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 43) { // confirm leaving group alert
        if (buttonIndex == 1) { // actually leave group
            PFRelation *members = self.group[@"members"];
            [members removeObject:[PFUser currentUser]];
            NSNumber *numMembers = self.group[@"numberOfMembers"];
            self.group[@"numberOfMembers"] = @([numMembers intValue] - 1);
            if ([self.group[@"numberOfMembers"] isEqual:@0]) { // group should be deleted because no members left
                [self deleteGroup:NULL];
            }
            else { // otherwise save the group to remove the member and delete all of that member's items
                // delete the items made by that member
                PFRelation *items = [self.group relationForKey:@"items"];
                PFQuery *itemsByThisUserQuery = [items query];
                [itemsByThisUserQuery whereKey:@"owner" equalTo:[PFUser currentUser]];
                // find the items by that member
                [itemsByThisUserQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    for (PFObject *object in objects){
                        PFRelation *items = [self.group relationForKey:@"items"];
                        [items removeObject:object]; // remove the object from the group
                        [object deleteInBackground]; // delete the object
                    }
                    // save the group with member removed and items removed
                    [self.group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
                }];
            }
        }
    }
}

- (void) deleteGroup: (id) sender
{
    // delete the group and all of its items
    // TODO: how to delete cover photo?
    // delete all items
    for (PFObject *item in self.items) {
        [item deleteInBackground];
    }
    // delete group itself
    [self.group deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self.navigationController popViewControllerAnimated:YES];
    }];

}

@end
