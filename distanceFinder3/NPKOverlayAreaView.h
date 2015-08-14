//
//  NPKOverlayAreaView.h
//  distanceFinder3
//
//  Created by Nathan Knable on 8/13/14.
//  Copyright (c) 2014 Nathan Knable. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface NPKOverlayAreaView : MKOverlayView <MKOverlay>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) MKMapRect boundingMapRect;



@end
