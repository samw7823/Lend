//
//  CLOSCreateClosetViewController.m
//  myCloset
//
//  Created by Ruoxi Tan on 7/10/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSCreateClosetViewController.h"
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface CLOSCreateClosetViewController () <UITextFieldDelegate,UICollectionViewDataSource,UICollectionViewDelegate, CLLocationManagerDelegate, UIAlertViewDelegate,UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UISwitch *isPublicSwitch;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) NSArray *closetDoorImages;
@property (weak, nonatomic) UICollectionViewCell *selectedCell;
@property (nonatomic) NSNumber *indexSelected;
@property (weak, nonatomic) IBOutlet UILabel *enterANameLabel;
@property (weak, nonatomic) IBOutlet UILabel *publicTextlabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) PFObject *closet;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSArray *searchResults;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSTimer *searchTimer;
@property (nonatomic) NSInteger selectedIndex;
@property (weak, nonatomic) IBOutlet UIButton *useCurrentCityButton;
@property (weak, nonatomic) IBOutlet UILabel *currenLocationLabel;
@property (nonatomic) BOOL shouldUseCurrentCity;
@property (weak, nonatomic) IBOutlet UIImageView *poweredByGoogleImage;
@property (strong, nonatomic) UIAlertView *savingAlert;

#define API_KEY @"AIzaSyDsBApm3VyaN6WbD4BVLLVzbQ3jgKNxdik"

@end

@implementation CLOSCreateClosetViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    } 
    return self;
}

- (IBAction)backgroundTapped:(id)sender
{
    // low keyboards
    [self.view endEditing:YES];
    
    // if background is tapped, show scroll view direction
    [self.collectionView flashScrollIndicators];
}

- (BOOL) textFieldShouldBeginEditing:(UITextField *)textField
{
    self.enterANameLabel.hidden = YES;
    
    return YES;
}

-(BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidChange:(UITextField *)textField
{
    if ([[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]isEqualToString:@""]) {
        self.doneButton.enabled = NO;
    } else {
        self.doneButton.enabled = YES;
    }
}

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

// resigns search bar or name text field as first responder when the table view is tapped
- (void) resignSearchBarOrNameTextField:(UITapGestureRecognizer *) recognizer
{
    if ([self.searchBar isFirstResponder])
        [self.searchBar resignFirstResponder];
    
    if ([self.nameTextField isFirstResponder])
        [self.nameTextField resignFirstResponder];
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

- (IBAction)useCurrentCity:(id)sender
{
     // if pressed, don't use current city. provide options for entering a location and hide current location related items
    self.searchBar.hidden = NO;
    self.tableView.hidden = NO;
    self.poweredByGoogleImage.hidden = NO;
    self.currenLocationLabel.hidden = YES;
    self.useCurrentCityButton.hidden = YES;
    
    
    self.shouldUseCurrentCity = NO;
}

// table view for search set up


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

- (IBAction)switchToggled:(id)sender
{
    if (self.isPublicSwitch.on == YES) {
        [self.publicTextlabel setText:@"this closet can be seen by anyone"];
    }
    else {
        [self.publicTextlabel setText:@"only you can see this closet"];
    }
}

- (IBAction)donePressed:(id)sender
{
    // if location services on and user hasn't requested to change their location, already have location and closet should be saved
    if (self.closet && self.shouldUseCurrentCity) {
        [self saveCloset];
    }
    // otherwise, see if the user entered another location
    else {
        self.closet = nil; // reset closet just in case location services are on but user wants to use a different location
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
                        // need to initialize a closet object
                        self.closet = [PFObject objectWithClassName:@"Closet"];
                        
                        // save address line
                        self.closet[@"FormattedAddressLines"] = placemark.addressDictionary[@"FormattedAddressLines"];
                        
                        // save geopoint
                        CLLocationCoordinate2D coordinate = [placemark.location coordinate];
                        PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                                      longitude:coordinate.longitude];
                        self.closet[@"geopoint"] = geoPoint;
                        
                        // save the closet
                        [self saveCloset];
                    }
                }
            }];

        }
        else { // didn't want to use current location, and didn't enter in a location
            self.closet = [PFObject objectWithClassName:@"Closet"];
            [self saveCloset];
        }
    }
}

- (void) saveCloset
{
    // disable user interaction until it saves
    self.view.userInteractionEnabled = NO;
    NSTimeInterval t = 3.0;
    __block NSTimer *saveTimer = [NSTimer scheduledTimerWithTimeInterval:t
                                                target:self
                                              selector:@selector(saveTakingTooLong:)
                                              userInfo:nil
                                               repeats:NO];
    
 // closet will have already been initalized for location stuff. set correct fields and then save it.
    self.doneButton.enabled = NO;
    self.cancelButton.enabled = NO;
    PFUser *u = [PFUser currentUser];
    
    self.closet[@"name"] = self.nameTextField.text;
    
    //set picture
    self.closet[@"photoNumber"] = self.indexSelected ? self.indexSelected : [NSNumber numberWithInt:0];
    
    //set privacy
    if (self.isPublicSwitch.isOn)
        self.closet[@"isPrivate"] = @NO;
    else
        self.closet[@"isPrivate"] = @YES;
    
    // set owner relation
    PFRelation *closetToOwner = [self.closet relationForKey:@"owner"];
    [closetToOwner addObject:u];
    
    [self.closet saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if ([saveTimer isValid]) {
            [saveTimer invalidate];
            saveTimer = nil;
        }
        if (!error) {
            [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
            PFRelation *relation = [u relationForKey:@"ownedClosets"];
            [relation addObject:self.closet];
            
            [u saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    if ([self.closet[@"isPrivate"] isEqual: @YES]) {
                        [[PFUser currentUser] incrementKey:@"weightedActivity"];
                    } else {
                        [[PFUser currentUser] incrementKey:@"weightedActivity" byAmount:@2];
                    }
                    [[PFUser currentUser] saveInBackground];
                    [self dismissViewControllerAnimated:YES completion:NULL];
                } else {
                    //Error saving - allow redo?
                    self.doneButton.enabled = YES;
                    self.cancelButton.enabled = YES;
                }
            }];
        }
        else {
            [self.savingAlert dismissWithClickedButtonIndex:0 animated:YES];
            UIAlertView *tryAgainAlert = [[UIAlertView alloc] initWithTitle:@"Try again?"
                                                                    message:@"Save failed. Would you like to try again?"
                                                                   delegate:self cancelButtonTitle:@"Cancel"
                                                          otherButtonTitles:@"Try Again", nil];
            [tryAgainAlert show];
            tryAgainAlert.tag = 404;
        }
    }];
}

- (IBAction)cancelPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
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

- (void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 404) { // save failed, cancel or try again
        if (buttonIndex == alertView.cancelButtonIndex) { // cancel, so hide the alert and re-enable the view
            self.view.userInteractionEnabled = YES;
            self.doneButton.enabled = YES;
            self.cancelButton.enabled = YES;
        }
        else { // try save again
            [self saveCloset];
        }
    }
}

//collectionView setup--currently hardcoding in photos

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ClosetCell" forIndexPath:indexPath];
    
    UILabel *titleLabel = (UILabel *)[cell viewWithTag:100];
    titleLabel.hidden = YES;
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:50];

    imageView.image = self.closetDoorImages[indexPath.row];
    NSNumber *row = [NSNumber numberWithInteger:indexPath.row];
    if (row == self.indexSelected) {
        titleLabel.text = @"SELECTED";
        titleLabel.hidden = NO;
    }
    

    return cell;
}

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.closetDoorImages count];
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // if one is tapped, show scroll view direction
    [self.collectionView flashScrollIndicators];
    
    UICollectionViewCell *cellSelected = [self.collectionView cellForItemAtIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cellSelected viewWithTag:100];
    titleLabel.text = @"SELECTED";
    titleLabel.hidden = NO;
    self.indexSelected = [NSNumber numberWithInteger:indexPath.row];
    self.selectedCell = cellSelected;

}

- (void) collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // if one is tapped, show scroll view direction
    [self.collectionView flashScrollIndicators];
    
    UICollectionViewCell *cellSelected = [self.collectionView cellForItemAtIndexPath:indexPath];
    UILabel *titleLabel = (UILabel *)[cellSelected viewWithTag:100];

    titleLabel.hidden = YES;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.enterANameLabel.hidden = YES;
    
    UINib *cellNib = [UINib nibWithNibName:@"CLOSClosetCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ClosetCell"];

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(150, 150)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
    
    self.closetDoorImages = [[NSArray alloc] initWithObjects:[UIImage imageNamed:@"closetDoor[0].jpg"],[UIImage imageNamed:@"closetDoor[1].jpg"],[UIImage imageNamed:@"closetDoor[2].jpg"], [UIImage imageNamed:@"closetDoor[3].jpg"], [UIImage imageNamed:@"closetDoor[4].jpg"],[UIImage imageNamed:@"closetDoor[5].jpg"],nil];
    
    // make sure interaction enabled
    self.view.userInteractionEnabled = YES;

}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // show the direction of scrolling for the collection view
    [self.collectionView flashScrollIndicators];
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
    
    // set up search bar
    self.searchBar.delegate = self;
    [UITextField appearanceWhenContainedIn:[UISearchBar class], nil].font = [UIFont fontWithName:@"STHeitiTC-Medium" size:14.0];
    [UITextField appearanceWhenContainedIn:[UISearchBar class], nil].textColor = [UIColor whiteColor];
    
    // set up table view for search results
    //self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    // make a tap gesture recognizer to resign the search bar as first responder when user touches table view below it
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignSearchBarOrNameTextField:)];
    tapRecognizer.cancelsTouchesInView = NO; // make sure table view still internally registers touch
    [self.tableView addGestureRecognizer:tapRecognizer];
    self.selectedIndex = -1;
    
    // set up use current city button
    self.useCurrentCityButton.layer.cornerRadius = 8.0f;
    self.useCurrentCityButton.titleLabel.font = [UIFont fontWithName:@"STHeitiTC-Medium" size:15.0];
    
    // user can't click done until a name has been entered
    self.doneButton.enabled = NO;
    
    // assume location services not enabled, so hide and set the items related to the current location
    self.useCurrentCityButton.hidden = YES;
    self.currenLocationLabel.hidden = YES;
    self.shouldUseCurrentCity = NO;
    
    if ([CLLocationManager locationServicesEnabled]) { // location services enabled
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startMonitoringSignificantLocationChanges];
        CLLocation *location = locationManager.location;
        //save address lines
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            // location services turned off for this app
            if (error) {

            } else { // location services on for this app. make a closet object and set its FormattedAddressLinesField. enable using current city
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
                        // TODO: figure out what to do in this case.
                    }
                    else {
                        CLPlacemark *placemarkGeneral = [placemarks lastObject];
                        self.closet = [PFObject objectWithClassName:@"Closet"];
                        self.closet[@"FormattedAddressLines"] = placemarkGeneral.addressDictionary[@"FormattedAddressLines"];
                       
                        // save geopoint
                        CLLocationCoordinate2D coordinate = [placemarkGeneral.location coordinate];
                        PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:coordinate.latitude
                                                                      longitude:coordinate.longitude];
                        self.closet[@"geopoint"] = geoPoint;
                    
                        // set up options for user to change this
                        NSMutableString *s = [[NSMutableString alloc] initWithString:@"Current Location:\n"];
                        for (NSString *str in self.closet[@"FormattedAddressLines"]) {
                            [s appendString:str];
                            [s appendString:@"\n"];
                        }
                        self.currenLocationLabel.text = s;
                        self.currenLocationLabel.hidden = NO;
                        self.useCurrentCityButton.hidden = NO;
                        
                        // user can't search for a location yet. use current location, unless they later choose otherwise
                        self.searchBar.hidden = YES;
                        self.tableView.hidden = YES;
                        self.shouldUseCurrentCity = YES;
                        self.poweredByGoogleImage.hidden = YES;
                        
                        [locationManager stopMonitoringSignificantLocationChanges];
                    }
                }];
            }
        }];
    }
    
    self.navBar.hidden = NO;
    self.navBar.alpha = 1.0;
    self.navBar.tintColor = [UIColor whiteColor];
    UINavigationItem *item = self.navBar.items[0];
    [item.leftBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0]} forState:UIControlStateNormal];
     [item.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:17.0]} forState:UIControlStateNormal];

    [self.nameTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
