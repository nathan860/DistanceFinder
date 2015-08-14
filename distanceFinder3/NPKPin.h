//
//  NPKPin.h
//  distanceFinder3
//
//  Created by Nathan Knable on 11/10/13.
//  Copyright (c) 2013 Nathan Knable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface NPKPin : NSObject <MKAnnotation>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic) NSInteger arrayPosition;
//@property (nonatomic, readonly, copy) NSString *subtitle;


//- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:(NSString *)placeName description:(NSString *)description;
- (id)initWithCoordinates:(CLLocationCoordinate2D)location;
-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate;


@end
