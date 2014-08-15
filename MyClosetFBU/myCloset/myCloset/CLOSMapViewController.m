//
//  CLOSMapViewController.m
//  myCloset
//
//  Created by Rachel Pinsker on 7/25/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import "CLOSMapViewController.h"
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>
#import "CLOSClosetsAtPlacemarkViewController.h"

#define offset 3000000


@interface CLOSMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation CLOSMapViewController

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
    
    // use a geocoder to get a placemark for all of the pins to add to the map
    for (NSString *string in self.stringAddressesToAdd) {
        if (![string isEqualToString:@""]) {
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
    }
}

- (void) zoomToAnnotations
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
    // TODO: figure out if no points will be shown (ie two pins so far apart full rectangle isn't displayed so no pins are shown when map opens)
    [self.mapView setVisibleMapRect:MKMapRectMake(minX  - offset, minY, maxX - minX + 2*offset, maxY - minY)];
    [self.mapView mapRectThatFits:self.mapView.visibleMapRect edgePadding:UIEdgeInsetsMake(0, offset, 0, offset)];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    // dequeue or create a pin for a given placemark that has an accessory on the right
    MKPinAnnotationView *pin;
    pin = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"pin"];
    if (pin == nil)
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pin"];
    pin.annotation = annotation;
    
    
    UIButton *seeClosets = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    seeClosets.frame = CGRectMake(0,0,50,45);
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:@">" attributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [UIFont fontWithName:@"STHeitiTC-Medium" size:25.0]}];
    [seeClosets setAttributedTitle:str forState:UIControlStateNormal];
    [seeClosets setBackgroundColor:[UIColor whiteColor]];
    pin.rightCalloutAccessoryView = seeClosets;
    pin.pinColor = MKPinAnnotationColorRed;
    pin.animatesDrop = YES;
    [pin setEnabled:YES];
    [pin setCanShowCallout:YES];
    
    return pin;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    // get the placemark tapped and its formattedAddressLines
    MKPlacemark *placemark = (MKPlacemark *) view.annotation;
    NSArray *placemarkStrings = placemark.addressDictionary[@"FormattedAddressLines"];
    NSMutableArray *closetsAtPlacemark = [[NSMutableArray alloc] init];
    // loop through the user's closets and find closets that are in the same area
    for (PFObject *closet in self.usersClosets) {
        if ([closet[@"FormattedAddressLines"] isEqual:placemarkStrings]) {
            [closetsAtPlacemark addObject:closet];
        }
    }
    
    // launch closetsAtPlacemarkViewController to display a list of the closets at the selected location
    CLOSClosetsAtPlacemarkViewController *closetsAtvc = [[CLOSClosetsAtPlacemarkViewController alloc] init];
    closetsAtvc.navigationItem.title = [NSString stringWithFormat:@"closets"];
    closetsAtvc.closetsToShow = closetsAtPlacemark;
    closetsAtvc.placemarkTitle = placemark.title;
    [self.navigationController pushViewController:closetsAtvc animated:YES];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
