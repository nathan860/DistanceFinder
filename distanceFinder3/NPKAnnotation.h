//
//  NPKAnnotation.h
//  distanceFinder3
//
//  Created by Nathan Knable on 11/10/13.
//  Copyright (c) 2013 Nathan Knable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface NPKAnnotation : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *subtitle;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;


@end
