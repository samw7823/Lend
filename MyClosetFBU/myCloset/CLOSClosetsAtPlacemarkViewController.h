//
//  CLOSClosetsAtPlacemarkViewController.h
//  myCloset
//
//  Created by Rachel Pinsker on 7/25/14.
//  Copyright (c) 2014 ___rpinsker___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface CLOSClosetsAtPlacemarkViewController : UIViewController

@property (nonatomic, strong) NSString *placemarkTitle;
@property (nonatomic, strong) NSMutableArray *closetsToShow;
@property (nonatomic, strong) CLPlacemark *placemark; // only used for closets nearby

@end
