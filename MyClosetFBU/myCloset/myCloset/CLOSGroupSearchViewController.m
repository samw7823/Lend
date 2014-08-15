//
//  CLOSGroupSearchViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 8/6/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSGroupSearchViewController.h"

#import "CLOSItemViewController.h"
#import "CLOSSearchTableViewCell.h"

@interface CLOSGroupSearchViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *itemTabelView;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
typedef NS_ENUM(NSInteger, sortTableStates) {
    noSortTable = 1,
    sortByDate = 2,
    sortByLocation = 3
};
@property (nonatomic, assign) sortTableStates sortTableState;
@property (nonatomic, copy) NSArray *searchResultItems;
@property (nonatomic, strong) NSTimer *searchDelay;
@property (nonatomic, assign) BOOL isUpdatingData;
@end

@implementation CLOSGroupSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    //set the navigation bar title
    self.navigationItem.title = @"Search";
    //query for items in groups for testing before actually being passed anything
    if ([self.groupItems count] == 0) {
        //query for items
        //hide tableView until items are loaded
        self.itemTabelView.hidden = YES;
        self.loadingLabel.hidden = NO;
        PFRelation *itemInGroupRelation = [self.group relationForKey:@"items"];
        PFQuery *groupItemQuery = [itemInGroupRelation query];
        groupItemQuery.limit = 8;
        NSMutableArray *groupItemsArrayMut = [NSMutableArray array];
        [groupItemQuery orderByDescending:@"createdAt"];
        [groupItemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
            [groupItemsArrayMut addObjectsFromArray:items];
            self.groupItems = [NSArray arrayWithArray:groupItemsArrayMut];
            self.itemTabelView.hidden = NO;
            self.loadingLabel.hidden = YES;
            [self.itemTabelView reloadData];
        }];
    }
    else{
        self.itemTabelView.hidden = NO;
        self.loadingLabel.hidden = YES;
    }

    //add tap gesture recognizer
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(backgroundTouched)];
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    //register tableviewcell
    UINib *cellNib = [UINib nibWithNibName:@"CLOSSearchTableViewCell" bundle:nil];
    [self.itemTabelView registerNib:cellNib forCellReuseIdentifier:@"CLOSSearchTableViewCell"];

    self.searchBar.backgroundColor = [UIColor colorWithWhite:0.33 alpha:0.6];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    self.itemTabelView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    //add a refresh control to allow refreshing of data - no other time is the data refreshed
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    NSMutableAttributedString *refreshString = [[NSMutableAttributedString alloc] initWithString:@"Loading..."];
    [refreshString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0, [refreshString length])];

    [refreshString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"STHeitiTC-Medium" size:13.0] range:NSMakeRange(0, [refreshString length])];
    refreshControl.attributedTitle = refreshString;

    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.itemTabelView addSubview:refreshControl];
}
-(void)backgroundTouched
{
    [self.view endEditing:YES];
}
#pragma tableview methods
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CLOSSearchTableViewCell *cell = [self.itemTabelView dequeueReusableCellWithIdentifier:@"CLOSSearchTableViewCell" forIndexPath:indexPath];
    PFObject *item = self.groupItems[indexPath.row];
    cell.image.image = nil;
    cell.itemName.text = item[@"name"];
    cell.itemDescription.text = item[@"ownerUsername"];
    cell.optionsButton.hidden = YES;
    PFFile *imageFile = self.groupItems[indexPath.row][@"itemImage"];
    [imageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        UIImage *image = [UIImage imageWithData:data];
        cell.image.image = image;
    }];

    return cell;
}
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.groupItems count];
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.view endEditing:YES];
    //go to itemvc
    CLOSItemViewController *itemvc = [[CLOSItemViewController alloc] init];
    itemvc.item = ((PFObject *)(self.groupItems[indexPath.row]));
    [self.navigationController pushViewController:itemvc animated:YES];
    [self.itemTabelView deselectRowAtIndexPath:indexPath animated:YES];
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger pagingCellIndex = [self.groupItems count] - 3;
    if (indexPath.row == pagingCellIndex && self.isUpdatingData == NO) {
        self.isUpdatingData = YES;
        [self updateData];
    }

}
#pragma search methods
-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searchDelay invalidate];
    self.searchDelay = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(updateTable) userInfo:nil repeats:NO];
}

#pragma updating methods
-(IBAction)handleRefresh:(id)sender
{
    [self.view endEditing:YES];
    if ([self.searchBar.text isEqualToString:@""]) {
        //if the search bar is empty
        PFRelation *itemInGroupRelation = [self.group relationForKey:@"items"];
        PFQuery *groupItemQuery = [itemInGroupRelation query];
        groupItemQuery.limit = 8;
        [groupItemQuery orderByDescending:@"createdAt"];
        NSMutableArray *groupItemsArrayMut = [NSMutableArray array];
        [groupItemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
            [groupItemsArrayMut addObjectsFromArray:items];
            self.groupItems = [NSArray arrayWithArray:groupItemsArrayMut];
            self.itemTabelView.hidden = NO;
            self.loadingLabel.hidden = YES;
            [self.itemTabelView reloadData];
            [(UIRefreshControl *)sender endRefreshing];
        }];
    }
    else{
        //if there is text in the search part
        PFRelation *itemInGroupRelation = [self.group relationForKey:@"items"];
        PFQuery *groupItemQueryContains = [itemInGroupRelation query];
        //query the search string is contained in an item name
        [groupItemQueryContains whereKey:@"lowercaseName" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];
        //query for search requests
        PFQuery *groupItemQueryBeginning = [itemInGroupRelation query];
        //query for the search string to see if an items begin with the string
        [groupItemQueryBeginning whereKey:@"lowercaseName" hasPrefix:[self.searchBar.text lowercaseString]];
        //query for item descriptions that begin with the string
        PFQuery *groupItemDescriptionBeginning = [itemInGroupRelation query];
        [groupItemDescriptionBeginning whereKey:@"lowercaseDescription" hasPrefix:[self.searchBar.text lowercaseString]];
        //query for item descriptions that contain the string
        PFQuery *groupItemDescriptionContains = [itemInGroupRelation query];
        [groupItemDescriptionContains whereKey:@"lowercaseDescription" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];
        
        PFQuery *searchGroupItemQuery = [PFQuery orQueryWithSubqueries:@[groupItemQueryContains, groupItemQueryBeginning, groupItemDescriptionContains, groupItemDescriptionBeginning]];
        [searchGroupItemQuery orderByDescending:@"createdAt"];
        NSMutableArray *groupItemsArrayMut = [NSMutableArray array];
        [searchGroupItemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
            [groupItemsArrayMut addObjectsFromArray:items];
            self.groupItems = [NSArray arrayWithArray:groupItemsArrayMut];
            self.itemTabelView.hidden = NO;
            self.loadingLabel.hidden = YES;
            [self.itemTabelView reloadData];
            [(UIRefreshControl *)sender endRefreshing];
        }];
    }
}
-(void)updateTable
{
    if ([self.searchBar.text isEqualToString:@""]) {
        //has so search string
        self.loadingLabel.hidden = YES;
        self.itemTabelView.hidden = NO;
        //if there are no items being shown
        if (!self.groupItems) {
            self.itemTabelView.hidden = YES;
            self.loadingLabel.hidden = NO;
            PFRelation *itemsInGroupRelation = [self.group relationForKey:@"items"];
            PFQuery *itemQuery = [itemsInGroupRelation query];
            [itemQuery orderByDescending:@"createdAt"];
            [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if ([self.searchBar.text isEqualToString:@""]) {
                    self.groupItems = self.groupItems;
                    [self.itemTabelView reloadData];
                    self.itemTabelView.hidden = NO;
                    self.loadingLabel.hidden = YES;
                }
            }];
        } else{
            //has a search string
            self.groupItems = self.groupItems;
            [self.itemTabelView reloadData];
        }
    } else{
        //has a search string
        self.itemTabelView.hidden = YES;
        self.loadingLabel.hidden = NO;
        NSString *searchText = self.searchBar.text;
        PFRelation *itemInGroupRelation = [self.group relationForKey:@"items"];
        PFQuery *groupItemQueryContains = [itemInGroupRelation query];
        //query the search string is contained in an item name
        [groupItemQueryContains whereKey:@"lowercaseName" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];
        //query for search requests
        PFQuery *groupItemQueryBeginning = [itemInGroupRelation query];
        //query for teh search string to see if an items begin with the string
        [groupItemQueryBeginning whereKey:@"lowercaseName" hasPrefix:[self.searchBar.text lowercaseString]];
        //query for item descriptions that begin with the string
        PFQuery *groupItemDescriptionBeginning = [itemInGroupRelation query];
        [groupItemDescriptionBeginning whereKey:@"lowercaseDescription" hasPrefix:[self.searchBar.text lowercaseString]];
        //query for item descriptions that contain the string
        PFQuery *groupItemDescriptionContains = [itemInGroupRelation query];
        [groupItemDescriptionContains whereKey:@"lowercaseDescription" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];
        PFQuery *searchGroupItemQuery = [PFQuery orQueryWithSubqueries:@[groupItemQueryContains, groupItemQueryBeginning, groupItemDescriptionBeginning, groupItemDescriptionContains]];
        [searchGroupItemQuery orderByDescending:@"createdAt"];
        [searchGroupItemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
            if ([searchText isEqualToString:self.searchBar.text]) {
                self.groupItems = items;
                self.itemTabelView.hidden = NO;
                self.loadingLabel.hidden = YES;
                [self.itemTabelView reloadData];
            }
        }];
    }
}
-(void)updateData
{
    if ([self.searchBar.text isEqualToString:@""]) {
        //no saerch string, query 8 items to present in the table view
        PFRelation *itemInGroupRelation = [self.group relationForKey:@"items"];
        PFQuery *itemQuery = [itemInGroupRelation query];
        itemQuery.skip = [self.groupItems count];
        [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            NSInteger lastRow = [self.groupItems count];
            self.groupItems = [self.groupItems arrayByAddingObjectsFromArray:objects];
            self.groupItems = self.groupItems;

            //for each item in objects, prepare for insertion
            NSInteger counter = [objects count];
            NSMutableArray *indexPaths = [NSMutableArray array];
            for (NSInteger i = 0; i < counter; i++) {
                NSIndexPath *ip = [NSIndexPath indexPathForRow:i + lastRow inSection:0];
                [indexPaths addObject:ip];
            }
            //inserting new items
            [self.itemTabelView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
            self.isUpdatingData = NO;
        }];
    } else {
        PFRelation *itemInGroupRelation = [self.group relationForKey:@"items"];

        //query items that begin with the search string
        PFQuery *itemQueryBeginning = [itemInGroupRelation query];
        [itemQueryBeginning whereKey:@"lowercaseName" hasPrefix:[self.searchBar.text lowercaseString]];

        //check items that has search string in the word
        PFQuery *itemQueryContains = [itemInGroupRelation query];
        [itemQueryContains whereKey:@"lowercaseName" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];
        
        //query for item descriptions that begin with the string
        PFQuery *groupItemDescriptionBeginning = [itemInGroupRelation query];
        [groupItemDescriptionBeginning whereKey:@"lowercaseDescription" hasPrefix:[self.searchBar.text lowercaseString]];
        //query for item descriptions that contain the string
        PFQuery *groupItemDescriptionContains = [itemInGroupRelation query];
        [groupItemDescriptionContains whereKey:@"lowercaseDescription" containsString:[NSString stringWithFormat:@" %@", [self.searchBar.text lowercaseString]]];

        PFQuery *itemSearchQuery = [PFQuery orQueryWithSubqueries:@[itemQueryContains, itemQueryBeginning, groupItemDescriptionBeginning, groupItemDescriptionContains]];
        [itemSearchQuery orderByDescending:@"createdAt"];
        itemSearchQuery.limit = 20;
        itemSearchQuery.skip = [self.groupItems count];
        [itemSearchQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSInteger lastRow = [self.groupItems count];
                self.groupItems = [self.groupItems arrayByAddingObjectsFromArray:objects];

                //for each item in object prepare for insertion
                NSInteger counter = [objects count];
                NSMutableArray *indexPaths = [NSMutableArray array];
                for (NSInteger i = 0; i < counter; i++) {
                    NSIndexPath *ip = [NSIndexPath indexPathForRow:i + lastRow inSection:0];
                    [indexPaths addObject:ip];
                }
                //inserting new items based on search
                [self.itemTabelView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
                self.isUpdatingData = NO;
            }
        }];
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
