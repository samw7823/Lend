//
//  CLOSEditClosetLocationViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/28/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSEditClosetLocationViewController.h"
#import <Parse/Parse.h>

@interface CLOSEditClosetLocationViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIAlertViewDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic) NSArray *myClosets;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *closetsSelected;
@property (nonatomic) BOOL selectAll;

@property (nonatomic, strong) CLPlacemark *placemarkGeneral;
@property (nonatomic, strong) PFGeoPoint *geopoint;

@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;
@property (weak, nonatomic) IBOutlet UIButton *deselectAllButton;
@property (weak, nonatomic) IBOutlet UIButton *changeLocationButton;

@property (weak, nonatomic) UISearchBar *searchBar;
@property (weak, nonatomic) UITableView *tableView;

@property (strong, nonatomic) NSArray *searchResults;
@property (nonatomic) NSInteger selectedIndex;
@property (strong, nonatomic) NSTimer *searchTimer;

#define API_KEY @"AIzaSyDsBApm3VyaN6WbD4BVLLVzbQ3jgKNxdik"

@end

@implementation CLOSEditClosetLocationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // make sure interaction enabled
    self.view.userInteractionEnabled = YES;

    
    // get user's owned closets
    PFRelation *relation = [[PFUser currentUser] relationForKey:@"ownedClosets"];
    PFQuery *query = [relation query];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        self.myClosets = objects;
        [self.collectionView reloadData];
    }];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set up buttons
    self.selectAllButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    self.selectAllButton.layer.cornerRadius = 8.0f;
    self.deselectAllButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    self.deselectAllButton.layer.cornerRadius = 8.0f;
    self.changeLocationButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    self.changeLocationButton.layer.cornerRadius = 8.0f;
    
    // fix spacing on collection view
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // initalize closetsSelected
    self.closetsSelected = [[NSMutableArray alloc] init];
    
    // disable buttons that shouldn't be used when nothing is selected
    self.changeLocationButton.enabled = NO;
    self.deselectAllButton.enabled = NO;
    
    //Register nib
    UINib *cellNib = [UINib nibWithNibName:@"CLOSClosetCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ClosetCell"];
    
    //Set flow layout
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(150, 150)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    //Enforce single selection
    self.collectionView.allowsSelection = YES;
    self.collectionView.allowsMultipleSelection = YES;
    
    // clear out selected index of search table view
    self.selectedIndex = -1;
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

    // gray out selected cells
    if (cell.selected)
        cell.alpha = .5;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // gray out the selected cell. add the closet to the closetsSelected array and enable the change location and deselect all buttons
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = .5;
    [self.closetsSelected addObject:self.myClosets[indexPath.row]];
    if (self.changeLocationButton.enabled == NO)
        self.changeLocationButton.enabled = YES;
    if (self.deselectAllButton.enabled == NO)
        self.deselectAllButton.enabled = YES;
    if ([self.closetsSelected count] == [self.myClosets count] && self.selectAllButton.enabled == YES)
        self.selectAllButton.enabled = NO;

}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // if a cell is being deselected, select all should be enabled
    if (self.selectAllButton.enabled == NO)
        self.selectAllButton.enabled = YES;
    // make the cell unselected. remove the closet from the closetsSelected array
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    cell.alpha = 1.0;
    [self.closetsSelected removeObject:self.myClosets[indexPath.row]];
    // if no closets/cells are selected, change location and deselect all should not be enabled
    if ([self.closetsSelected count] == 0) {
        if (self.changeLocationButton.enabled == YES)
            self.changeLocationButton.enabled = NO;
        if (self.deselectAllButton.enabled == YES)
            self.deselectAllButton.enabled = NO;
    }
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    // the number of closets the user has
    return [self.myClosets count];
}

- (IBAction)changeLocation:(id)sender
{
    // create a view to overlay with a search bar and table view
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"CLOSLocationSearchView" owner:self options:nil] objectAtIndex:0];
    UIControl *control = (UIControl *) view;
    [control addTarget:self action:@selector(getOutOfChangeLocation:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:control];
    
    // get pointers to the search bar, table view, save, and use current location
    for (UIView *v in [control subviews]) {
        if ([v isKindOfClass:[UISearchBar class]]) { // search bar
            self.searchBar = (UISearchBar *)v;
        }
        else if ([v isKindOfClass:[UITableView class]]) { // table view
            self.tableView = (UITableView *)v;
            // make a tap gesture recognizer to resign the search bar as first responder when user touches table view below it
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignSearchBar:)];
            tapRecognizer.cancelsTouchesInView = NO; // make sure table view still internally registers touch
            [self.tableView addGestureRecognizer:tapRecognizer];
        }
        else if (v.tag == 2) { // save button
            UIButton *save = (UIButton *)v;
            [save addTarget:self action:@selector(save:) forControlEvents:UIControlEventTouchUpInside];
            save.layer.cornerRadius = 8.0f;
            save.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:18.0];
        }
        else if (v.tag == 3) { // use current location button
            UIButton *useCurrentLocation = (UIButton *)v;
            [useCurrentLocation addTarget:self action:@selector(useCurrentLocation:) forControlEvents:UIControlEventTouchUpInside];
            useCurrentLocation.layer.cornerRadius = 8.0f;
            useCurrentLocation.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:16.0];
        }
    }
    
    // set the delegates of the search bar and table view.
    self.searchBar.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // register the class for table view cells
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

- (void) resignSearchBar: (UITapGestureRecognizer *) recognizer
{
    // if user taps table view, resign the search bar as first responder to lower keyboard. 
    [self.searchBar resignFirstResponder];
}

- (void) getOutOfChangeLocation: (id) sender
{
    // if the background is tapped dismiss the view
    UIControl *control = (UIControl *)sender;
    [control removeFromSuperview];
    // clear out selected index of search table view
    self.selectedIndex = -1;
    self.searchResults = nil;
    self.searchTimer = nil;
}

/* search view search bar set up */
- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // search pressed. if search hasn't been made within a certain amount of time and search string isn't empty, make the search request
    if (![self.searchTimer isValid]) { // timer ran out, can search again
        if (![self.searchBar.text isEqualToString:@""]) { // not an empty search string
            [self makeSearchRequest];
        }
    }
    
    // lower the keyboard
    [searchBar resignFirstResponder];
    
}

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //if search hasn't been made within a certain amount of time and search string isn't empty, make the search request
    if (![self.searchTimer isValid]) { // timer ran out, can search again
        if (![searchText isEqualToString:@""]) { // not an empty search string
            [self makeSearchRequest];
        }
    }
}

// the selector for the search timer. meant to do nothing. timer only makes sure search requests don't happen too often.
- (void) doNothing
{
}
- (void) makeSearchRequest
{
    //make places request
    NSString *searchText = self.searchBar.text;
    if (![searchText isEqualToString:@""]) { // don't search if string is empty
        NSString *searchTextNoSpaces = [searchText stringByReplacingOccurrencesOfString:@" " withString:@"_"]; // replace spaces with underscores
        NSString *string = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&key=%@",searchTextNoSpaces,API_KEY];
        NSURL *placesURL = [NSURL URLWithString:string];
        
        NSURLRequest *placesURLRequest = [NSURLRequest requestWithURL:placesURL];
        
        // create connection and get JSON response
        NSURLResponse *response;
        NSError *error;
        NSData *JSONplaces = [NSURLConnection sendSynchronousRequest:placesURLRequest
                                                   returningResponse:&response
                                                               error:&error];
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:JSONplaces options:0 error:&error];
        NSArray *predictions = json[@"predictions"];
        
        // parse through predictions returned
        NSMutableArray *cities = [[NSMutableArray alloc] init];
        for (NSDictionary *dict in predictions) {
            // add the object if it is a neighborhood, political, locality, sublocality, or postal code type.
            if ([dict[@"types"] containsObject:@"neighborhood"] || [dict[@"types"] containsObject:@"political"] || [dict[@"types"] containsObject:@"locality"] || [dict[@"types"] containsObject:@"sublocality"] || [dict[@"types"] containsObject:@"postal_code"]) {
                [cities addObject:dict];
            }
        }
        // don't allow more requests for a certain amount of time
        self.searchTimer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                            target:self
                                                          selector:@selector(doNothing)
                                                          userInfo:nil
                                                           repeats:NO];
        // set the searchResults array, show results in the table view, and reset the selectedIndex
        self.searchResults = [cities copy];
        [self.tableView reloadData];
        self.selectedIndex = -1;
    }

}


/* search view table view set up */

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // return number of predictions found
    return [self.searchResults count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // dequeue a cell
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    
    // text is the place's description from the google api request
    cell.textLabel.text = self.searchResults[indexPath.row][@"description"];
    
    // set display options of cell
    cell.backgroundColor = [UIColor clearColor];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:15.0];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // if cell is the one selected, give it a checkmark
    if (indexPath.row == self.selectedIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    // if it is the only cell in the table view, select it (give it a checkmark and set selected index)
    else if ([self.searchResults count] == 1) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.selectedIndex = indexPath.row;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // set the cell to have a checkmark as it has been selected
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.selectedIndex = indexPath.row;
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // remove the checkmark from the cell as it has been deselected
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    self.selectedIndex = -1;
}

- (void) save: (id) sender
{
    // don't allow double click
    self.view.userInteractionEnabled = NO;
    // save the new location
    if (self.selectedIndex != -1) { // a location has been selected
        NSString *location = self.searchResults[self.selectedIndex][@"description"];
        //get the placemarks associated with the address entered
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if ([placemarks count] != 1) { // none found or more than one found (ambiguous location)
                // TODO: figure out how to deal with this. Means user entered in a place, google api request was made, user selected a cell in the table view, and then
                // CLGeocoder couldn't find the place (or found multiple results).
            }
            else {
                CLPlacemark *placemark = placemarks[0]; // get the single placemark found
                // if formatted address lines is empty, there has been a problem.
                if (placemark.addressDictionary[@"FormattedAddressLines"] == nil) {
                    // TODO: like the above todo, figure out how to deal with this.
                }
                // otherwise, the city was found and the address line of the address will be saved
                else {
                    // save address line
                    NSArray *addressLines = placemark.addressDictionary[@"FormattedAddressLines"];
                    
                    // save geopoint
                    CLLocationCoordinate2D coordinate = [placemark.location coordinate];
                    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                                  longitude:coordinate.longitude];
                    for (PFObject *closet in self.closetsSelected) {
                        //wuery for items in the closet
                        closet[@"geopoint"] = geoPoint;
                        closet[@"FormattedAddressLines"] = addressLines;
                        [closet saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            //query for items relation in the closet
                            PFRelation *closetItemRelation = [closet relationForKey:@"items"];
                            PFQuery *itemQuery = [closetItemRelation query];
                            [itemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
                                for (PFObject *item in items) {
                                    //set the item location field to match the closet location field
                                    item[@"geopoint"] = closet[@"geopoint"];
                                    item[@"locationArray"] = closet[@"FormattedAddressLines"];
                                    [item saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                        if (error){
                                            NSLog(@"Here is the error formatting addresses %@", error);
                                        }
                                    }];
                                }
                            }];
                        }];
                    }
                    self.closetsSelected = nil;
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
        }];
    }

}
- (void) useCurrentLocation: (id) sender
{
    // when the user selects using their current location
    if ([CLLocationManager locationServicesEnabled]) {
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [locationManager requestWhenInUseAuthorization];
        }
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse){
            [locationManager startMonitoringSignificantLocationChanges];
        }
        else {
            locationManager = nil;
        }
        CLLocation *location = locationManager.location;
        //save address lines
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            // location services turned off for this app, so send an alert telling the user that
            if (error) {
                UIAlertView *locationServicesOffAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Off" message:@"You must turn on location services to use your current location." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                locationServicesOffAlert.alertViewStyle = UIAlertViewStyleDefault;
                [locationServicesOffAlert show];
            } else { // location services on for this app
                CLPlacemark *placemark = [placemarks lastObject];
                // only save the city of the current location.
                NSMutableString *cityString = [[NSMutableString alloc] init];
                if (placemark.addressDictionary[@"SubLocality"]) {
                    [cityString appendString:placemark.addressDictionary[@"SubLocality"]];
                    [cityString appendString:@" "];
                }
                [cityString appendString:placemark.addressDictionary[@"City"]];
                [cityString appendString:@" "];
                [cityString appendString:placemark.addressDictionary[@"State"]];
                [cityString appendString:@" "];
                [cityString appendString:placemark.addressDictionary[@"Country"]];
                [geocoder geocodeAddressString:cityString completionHandler:^(NSArray *placemarks, NSError *error) {
                    if (error) {
                        NSLog(@"can't find current city");
                    }
                    else {
                        // get placemark
                        self.placemarkGeneral = [placemarks lastObject];
                        
                        // get geopoint
                        CLLocationCoordinate2D coordinate = [self.placemarkGeneral.location coordinate];
                        self.geopoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                                      longitude:coordinate.longitude];
                        // for each closet selected, set location info and then save
                        for (PFObject *closet in self.closetsSelected) {
                            closet[@"geopoint"] = self.geopoint;
                            closet[@"FormattedAddressLines"] = self.placemarkGeneral.addressDictionary[@"FormattedAddressLines"];
                            [closet saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                if (succeeded)
                                    NSLog(@"good");
                                else
                                    NSLog(@"bad");
                            }];
                        }
                        self.closetsSelected = nil;
                        [self.navigationController popViewControllerAnimated:YES];
                        

                    }
                }];
            }
        }];
    }
    else { // location services off completely, so send an alert telling the user that
        UIAlertView *locationServicesOffAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Off" message:@"You must turn on location services to use your current location." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        locationServicesOffAlert.alertViewStyle = UIAlertViewStyleDefault;
        [locationServicesOffAlert show];
    }
}


- (IBAction)selectAllAction:(id)sender
{
    // disable the select all button (until a closet is deselected)
    self.selectAllButton.enabled = NO;
    // loop through all of the cells and mark them as selected
    NSInteger count = [self.myClosets count];
    for (NSInteger i = 0; i < count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    }
    // gray out the cells on screen to show them as selected
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        cell.alpha = .5;
    }
    // closetsSelected is all of the user's closets
    self.closetsSelected = [NSMutableArray arrayWithArray:self.myClosets];
    // the change location and deselect all buttons should be enabled
    if (self.changeLocationButton.enabled == NO)
        self.changeLocationButton.enabled = YES;
    if (self.deselectAllButton.enabled == NO)
        self.deselectAllButton.enabled = YES;
    
}

- (IBAction)deselectAll:(id)sender
{
    // loop through all selected items and make them unselected
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
        cell.alpha = 1.0;
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    // show cells on screen as not selected
    for (UICollectionViewCell *cell in [self.collectionView visibleCells]) {
        cell.alpha = 1.0;
    }
    // empty out closetsSelected
    [self.closetsSelected removeAllObjects];
    // change location should be disabled, select all button should be enabled, and deselect all button should be disabled
    if (self.changeLocationButton.enabled == YES)
        self.changeLocationButton.enabled = NO;
    if (self.selectAllButton.enabled == NO)
        self.selectAllButton.enabled = YES;
    self.deselectAllButton.enabled = NO;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
