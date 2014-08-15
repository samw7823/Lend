//
//  CLOSItemsYouveBorrowedViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/21/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSItemsYouveBorrowedViewController.h"

#import <Parse/Parse.h>

#import "CLOSItemViewController.h"
#import "CLOSSearchTableViewCell.h"

@interface CLOSItemsYouveBorrowedViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) NSArray *itemIds;

typedef NS_ENUM(NSInteger, transactionStates)  {
    requested = 1,
    accepted = 2,
    rejected = 3,
    borrowed = 4,
    returned = 5
};

@end

@implementation CLOSItemsYouveBorrowedViewController

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
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.items = [[NSMutableArray alloc] init];
    self.itemIds = [[NSArray alloc] init];
    NSMutableSet *itemsIdSet = [[NSMutableSet alloc] init];
    
    // register a table view cell
    UINib *nib = [UINib nibWithNibName:@"CLOSSearchTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];
    
    //Query for transactions
    PFQuery *transactionQuery = [PFQuery queryWithClassName:@"ItemTransaction"];
    
    //borrower is current user. also retrieve the item in the transaction
    [transactionQuery whereKey:@"borrower" equalTo:[PFUser currentUser]];
    [transactionQuery whereKey:@"transactionState" greaterThan:[NSNumber numberWithInteger:rejected]];
    [transactionQuery includeKey:@"item"];
    [transactionQuery orderByDescending:@"createdAt"];
    [transactionQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        // get rid of dublicates by adding object ids to a set
        for (PFObject *t in objects) {
            PFObject *item = t[@"item"];
            [itemsIdSet addObject:item.objectId];
        }
        self.itemIds = (NSArray *)itemsIdSet;
        // loop through the object ids and add the object to self.items. this avoids querying and retrieving the object again.
        for (NSString *itemId in self.itemIds) {
            for (int i = 0; i < [objects count]; i++) {
                PFObject *t = objects[i];
                PFObject *item = t[@"item"];
                if ([item.objectId isEqualToString:itemId]) {
                    [self.items addObject:item];
                    break;
                }
            }
        }
        [self.tableView reloadData];
    }];
    //Add invisible footer to remove separators at the end
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // number of total items user has borrowed without duplicates
    return [self.itemIds count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // display the name of the item involved in the transaction
    CLOSSearchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell" forIndexPath:indexPath];
    PFObject *item = self.items[indexPath.row];
    cell.itemName.text = item[@"name"];
    cell.itemDescription.text = item[@"ownerUsername"];
    PFFile *imageFile = item[@"itemImage"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        cell.image.image = [UIImage imageWithData:data];
    }];
    
    cell.optionsButton.hidden = YES;

    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // launch item view controller, first setting its itemId property to the selected item's objectId
    PFObject *item = self.items[indexPath.row];
    
    CLOSItemViewController *itemvc = [[CLOSItemViewController alloc] init];
    itemvc.item = item;
    
    [self.navigationController pushViewController:itemvc animated:YES];
}


-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
