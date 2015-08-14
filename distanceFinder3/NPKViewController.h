//
//  NPKViewController.h
//  distanceFinder3
//
//  Created by Nathan Knable on 10/31/13.
//  Copyright (c) 2013 Nathan Knable. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface NPKViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, UITextFieldDelegate, UIPopoverControllerDelegate>

@end
