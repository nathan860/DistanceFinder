//
//  NPKPin.m
//  distanceFinder3
//
//  Created by Nathan Knable on 11/10/13.
//  Copyright (c) 2013 Nathan Knable. All rights reserved.
//

#import "NPKPin.h"

@implementation NPKPin


- (id)initWithCoordinates:(CLLocationCoordinate2D)location {
    self = [super init];
    if (self != nil) {
        _coordinate = location;
        _title = @"Delete";
    }
    return self;
}

-(void)setCoordinate:(CLLocationCoordinate2D)newCoordinate{
    _coordinate = newCoordinate;
}
/**
- (id)initWithCoordinates:(CLLocationCoordinate2D)location placeName:placeName description:description {
    self = [super init];
    if (self != nil) {
        _coordinate = location;
        _title = placeName;
        _subtitle = description;
    }
    return self;
}**/

@end
