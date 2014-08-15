//
//  CLOSIndividualClosetViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSIndividualClosetViewController.h"
#import "CLOSItemViewController.h"
#import <Parse/Parse.h>
#import "CLOSCreateItemViewController.h"
#import "CLOSClosetsAtPlacemarkViewController.h"
#import "CLOSMapViewController.h"
#import "CLOSProfileViewController.h"

@interface CLOSIndividualClosetViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *items;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UILabel *privacyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *privacySwitch;
@property (weak, nonatomic) IBOutlet UILabel *privacyStatementLabel;
@property (nonatomic) BOOL oldPrivacyBool;
@property (weak, nonatomic) IBOutlet UIButton *makeANewItemTutorialButton;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (strong, nonatomic) NSTimer *flashTimer;
@property (nonatomic, assign) BOOL endOfQuerying;
@property (nonatomic, assign) NSInteger numberOfItems;
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

@implementation CLOSIndividualClosetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.user = [PFUser currentUser];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // set fonts and text color of buttons
    self.editButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.saveButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0];
    self.editButton.titleLabel.textColor = [UIColor lightGrayColor];
    self.saveButton.titleLabel.textColor = [UIColor whiteColor];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    // Do any additional setup after loading the view from its nib.
    NSString *title = self.closet[@"name"];
    self.navigationItem.title = title;
    
    UINib *cellNib = [UINib nibWithNibName:@"CLOSClosetCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ClosetCell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(150, 150)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    self.numberOfItems = -1;
}

- (void) viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:animated];
    // stop timer if it was going
    if (self.flashTimer) {
        [self.flashTimer invalidate];
        self.flashTimer = nil;
    }
    self.endOfQuerying = NO;
    self.makeANewItemTutorialButton.hidden = YES;
    [self.makeANewItemTutorialButton setTitle:@"Make a new item!" forState:UIControlStateNormal];

    PFRelation *relation = [self.closet relationForKey:@"items"]; //change to specific closet
    PFQuery *query = [relation query];
    if (self.numberOfItems < 20) {
        query.limit = 20;
    } else {
        query.limit = self.numberOfItems + 1;
    }
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.items = objects;
        self.numberOfItems = self.items.count;
        [self.collectionView reloadData];
    }];

    // hide editing options no matter who the user is
    self.saveButton.hidden = YES;
    self.privacyLabel.hidden = YES;
    self.privacySwitch.hidden = YES;

    
    if ([self.user.username isEqualToString:[PFUser currentUser].username]) {
        //provide editing options if user owns this closet
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd  target:self action:@selector(addItem)];
        addButton.tintColor = [UIColor whiteColor];
        UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteCloset:)];
        self.navigationItem.rightBarButtonItems = @[addButton, deleteButton];
        self.editButton.hidden = NO;
        if ([self.closet[@"isPrivate"]  isEqual: @TRUE]) {
            [self.privacyStatementLabel setText:@"this closet is private"];
            self.oldPrivacyBool = YES;
        }
        else {
            [self.privacyStatementLabel setText:@"this closet is public"];
            self.oldPrivacyBool = NO;
        }
        // check tutorial stage
        if ([self.user[@"tutorialStage"] isEqual:[NSNumber numberWithInteger:viewedCloset]]) { // need to make an item
            self.makeANewItemTutorialButton.hidden = NO;
            if (!self.flashTimer) {
                self.flashTimer = [NSTimer scheduledTimerWithTimeInterval:.8
                                                      target:self
                                                    selector:@selector(flashAddItemButton)
                                                    userInfo:nil
                                                     repeats:YES];
            }
        }
    }
    else {
        // hide the edit button and privacy statement if user doesn't own this closet
        self.editButton.hidden = YES;
        self.privacyStatementLabel.hidden = YES;
    }
    //set location label
    NSArray *locationStrings = self.closet[@"FormattedAddressLines"];
    NSMutableString *locationString = [NSMutableString string];
    for (NSString *string in locationStrings) {
        [locationString appendString:string];
        [locationString appendString:@" "];
    }
    self.locationLabel.text = locationString;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) flashAddItemButton
{
    // flash the settings button
    UIBarButtonItem *addItem = [self.navigationItem.rightBarButtonItems firstObject];
    if ([addItem.tintColor isEqual:[UIColor whiteColor]])
        addItem.tintColor = [UIColor lightGrayColor];
    else
        addItem.tintColor = [UIColor whiteColor];
}
-(void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == self.items.count - 10 && self.endOfQuerying == NO) {
        PFRelation *relation = [self.closet relationForKey:@"items"]; //change to specific closet
        PFQuery *query = [relation query];
        query.limit = 20;
        query.skip = self.items.count;
        [query orderByDescending:@"createdAt"];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if ([objects count] > 0) {
                //something is queried
                NSInteger lastRow = [self.items count];
                self.items = [self.items arrayByAddingObjectsFromArray:objects];
                self.numberOfItems = self.items.count;
                //for each item in object, prepare for insertion
                NSInteger counter = [objects count];
                NSMutableArray *indexPaths = [NSMutableArray array];
                for (NSInteger i = 0; i < counter; i++) {
                    NSIndexPath *ip = [NSIndexPath indexPathForRow: i + lastRow inSection:0];
                    [indexPaths addObject:ip];
                }
                [self.collectionView insertItemsAtIndexPaths:indexPaths];
            } else {
                self.numberOfItems = self.items.count;
                self.endOfQuerying = YES;
            }
        }];

    }
}
- (void) addItem
{
    CLOSCreateItemViewController *createvc = [[CLOSCreateItemViewController alloc] init];
    createvc.closet = self.closet;
    [self presentViewController:createvc animated:YES completion:NULL];
    
}
- (void)deleteCloset:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Delete %@", self.closet[@"name"] ] message:[NSString stringWithFormat:@"Are you sure you want to delete %@?", self.closet[@"name"]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //If cancel, do nothing
    if (buttonIndex == 1) {
        //Pressed Yes
        [self.closet deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                NSInteger length = [self.navigationController.viewControllers count];
                if ([self.navigationController.viewControllers[length - 2] isKindOfClass:[CLOSClosetsAtPlacemarkViewController class]]) // if launched from the map view
                {
                    UINavigationController *navPointer = self.navigationController; // get a pointer to the navigation controller
                    // go back to profile view
                    [self.navigationController popViewControllerAnimated:NO];
                    [navPointer popViewControllerAnimated:NO];
                    [navPointer popViewControllerAnimated:NO];
                    CLOSProfileViewController *profvc = (CLOSProfileViewController *)[navPointer.viewControllers lastObject];
                    // delete the closet just deleted from the user's profile, then launch the map view
                    [profvc.myClosets removeObject:self.closet];
                    [profvc seeMap:NULL];
                }
                else {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                PFQuery *transactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
                [transactionQuery whereKey:@"item" containedIn:self.items];
                //Find all transactions related to items here
                [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                    //delete these transactions
                    [PFObject deleteAllInBackground:objects];
                }];
                //delete all the items as well
                [PFObject deleteAllInBackground:self.items];
            } else {
                NSLog(@"Deleting closet encountered an error: %@", error.userInfo[@"error"]);
            }
        }];
    }
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ClosetCell" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    // [titleLabel setText:@"ITEM"];
    PFObject *item = self.items[indexPath.row];
    
    NSString *itemName = item[@"name"];
    [titleLabel setText:itemName];
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:50];
    imageView.image = nil;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    PFFile *imageFile = item[@"itemImage"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            [imageView setImage:image];
        }
        else {
            NSLog(@"Encountered error while fetching image: %@", error.userInfo[@"error"]);
        }
    }];

    return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *closetItem = self.items[indexPath.row];

    CLOSItemViewController *itemvc = [[CLOSItemViewController alloc] init];
    itemvc.item = closetItem;
    [self.navigationController pushViewController:itemvc animated:YES];
    
}


- (IBAction)edit:(id)sender
{
    // enter editing mode: hide edit button and privacy statement
    self.editButton.hidden = YES;
    self.privacyStatementLabel.hidden = YES;
    
    // show all editing options
    self.saveButton.hidden = NO;
    self.saveButton.titleLabel.textColor = [UIColor whiteColor];
    self.privacyLabel.hidden = NO;
    self.privacySwitch.hidden = NO;
    
    // set switch according to current setting
    if (self.oldPrivacyBool)
        self.privacySwitch.on = YES;
    else
        self.privacySwitch.on = NO;
}

- (IBAction)save:(id)sender
{
    if (self.privacySwitch.on && !self.oldPrivacyBool) //closet was public and now isPrivate switch is on --> make private
    {
        self.closet[@"isPrivate"] = @YES;
        [self.closet saveInBackground];
        for (PFObject *item in self.items) {
            item[@"isInPrivateCloset"] = @YES;
            [item saveInBackground];
        }
        [self.privacyStatementLabel setText:@"this closet is private"];
        self.oldPrivacyBool = YES;
        [[PFUser currentUser] incrementKey:@"weightedActivity" byAmount:@-1];
        [[PFUser currentUser] saveInBackground];
        
    }
    else if (!self.privacySwitch.on && self.oldPrivacyBool) //closet was private and now isPrivate switch is off --> make public
    {
        self.closet[@"isPrivate"] = @NO;
        [self.closet saveInBackground];
        for (PFObject *item in self.items) {
            item[@"isInPrivateCloset"] = @NO;
            [item saveInBackground];
        }
        [self.privacyStatementLabel setText:@"this closet is public"];
        self.oldPrivacyBool = NO;
        [[PFUser currentUser] incrementKey:@"weightedActivity"];
        [[PFUser currentUser] saveInBackground];
    }
    
    //end editing mode: show edit button and privacy statement
    self.editButton.hidden = NO;
    self.editButton.titleLabel.textColor = [UIColor lightGrayColor];
    self.privacyStatementLabel.hidden = NO;
    
    // hide all editing options
    self.saveButton.hidden = YES;
    self.privacyLabel.hidden = YES;
    self.privacySwitch.hidden = YES;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.items count];
}

@end
