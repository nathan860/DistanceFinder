//
//  NPKLocationStore.m
//  distanceFinder3
//
//  Created by Nathan Knable on 11/19/13.
//  Copyright (c) 2013 Nathan Knable. All rights reserved.
//

#import "NPKLocationStore.h"

@implementation NPKLocationStore



+ (NPKLocationStore *)sharedStore
{
    static dispatch_once_t pred;
    static NPKLocationStore *store = nil;
    
    dispatch_once(&pred, ^{ store = [[self alloc] init]; });
    return store;
}

@end
