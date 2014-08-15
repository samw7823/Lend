//
//  CLOSMapPopoverViewController.m
//  myCloset
//
//  Created by Samantha Wiener on 8/4/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSMapPopoverViewController.h"
#import "CLOSItemViewController.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>

#define offset 3000000

@interface CLOSMapPopoverViewController () <MKMapViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, copy) NSArray *publicNearbyItems;

@end

@implementation CLOSMapPopoverViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.stringAddressesToAdd = [[NSMutableArray alloc] init];
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    //set title
    NSString *title = [NSString stringWithFormat:@"%@", self.item[@"name"]];
    self.navigationItem.title = title;
    
    //use a geocoder to get a placemark for all of the pins to add to the map
    for (NSString *string in self.stringAddressesToAdd) {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:string completionHandler:^(NSArray *placemarks, NSError *error) {
            if (placemarks) {
                CLPlacemark *placemark = placemarks[0];
                MKPlacemark *mkplacemark = [[MKPlacemark alloc] initWithPlacemark:placemark];
                [self.mapView addAnnotation:mkplacemark];
            }
            [self zoomToAnnotations];
        }];
    }
    //mutable array to store the public nearby items
    NSMutableArray *publicNearbyItemsMut = [NSMutableArray array];
    //query for all public users
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"isPrivate" equalTo:@NO];

    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *publicUsers, NSError *error) {
        //combine public users with followings
        NSArray *viewableUsers = [self.following arrayByAddingObjectsFromArray:publicUsers];
        //query for all items they own that is at location passed in
        PFQuery *publicItemQuery = [PFQuery queryWithClassName:@"Item"];
        [publicItemQuery whereKey:@"isInPrivateCloset" equalTo:@NO];
        [publicItemQuery whereKey:@"ownerUsername" containedIn:[viewableUsers valueForKey:@"username"]];
        [publicItemQuery whereKey:@"locationArray" containsAllObjectsInArray:self.locationArray];
        [publicItemQuery orderByDescending:@"createdAt"];
        [publicItemQuery findObjectsInBackgroundWithBlock:^(NSArray *items, NSError *error) {
            for (PFObject *item in items) {
                //recheck that the locations are correct with count (Parse does not offer ability to check equality for array
                if (((NSArray *)item[@"locationArray"]).count == self.locationArray.count) {
                    [publicNearbyItemsMut addObject:item];
                }
            }
            self.publicNearbyItems = publicNearbyItemsMut.copy;
            [self.collectionView reloadData];
        }];
    }];
    
    //register collection view cell, reusing the closetcell to display items instead
    UINib *cellNib = [UINib nibWithNibName:@"CLOSClosetCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"ClosetCell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(150, 150)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    [self.collectionView setCollectionViewLayout:flowLayout];
}

-(void) zoomToAnnotations
{
    double minX = 0;
    double maxX = 0;
    double minY = 0;
    double maxY = 0;

    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        if (annotationPoint.x < minX || minX == 0) minX = annotationPoint.x;
        if (annotationPoint.x > maxX) maxX = annotationPoint.x;
        if (annotationPoint.y < minY || minY == 0) minY = annotationPoint.y;
        if (annotationPoint.y > maxY) maxY = annotationPoint.y;
    }
    [self.mapView setVisibleMapRect:MKMapRectMake(minX  - offset, minY, maxX - minX + 2*offset, maxY - minY)];
    [self.mapView mapRectThatFits:self.mapView.visibleMapRect edgePadding:UIEdgeInsetsMake(0, offset, 0, offset)];
}
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    //dequeue or create a pin fro a given placemark that ahs an accessory on the right
    MKPinAnnotationView *pin;
    pin = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
    if (pin == nil) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
    }
    pin.annotation = annotation;
    
    UIButton *seeItemPage = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    seeItemPage.frame = CGRectMake(0, 0, 50, 45);
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@">" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:25.0]}];
    [seeItemPage setAttributedTitle:str forState:UIControlStateNormal];
    [seeItemPage setBackgroundColor:[UIColor whiteColor]];
    
    pin.rightCalloutAccessoryView = seeItemPage;
    pin.pinColor = MKPinAnnotationColorRed;
    pin.animatesDrop = YES;
    [pin setEnabled:YES];
    [pin setCanShowCallout:YES];
    
    return pin;
}

-(UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //dequeue closet cell and use it to display items
    UICollectionViewCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"ClosetCell" forIndexPath:indexPath];
    
    PFObject *item = self.publicNearbyItems[indexPath.row];
    
    UILabel *itemTitleLabel = (UILabel *)[cell viewWithTag:100];
    NSString *itemName = item[@"name"];
    [itemTitleLabel setText:itemName];
    
    //get item image
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:50];
    PFFile *itemImageFile = item[@"itemImage"];
    [itemImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            [imageView setImage:image];
        }
        else{
            NSLog(@"Encountered error while fetching image: %@", error.userInfo[@"error"]);
        }
    }];
    
    return cell;
}
-(NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.publicNearbyItems count];
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    PFObject *selectedItem = self.publicNearbyItems[indexPath.row];
    CLOSItemViewController *itemvc = [[CLOSItemViewController alloc] init];
    itemvc.item = selectedItem;
    [self.navigationController pushViewController:itemvc animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
