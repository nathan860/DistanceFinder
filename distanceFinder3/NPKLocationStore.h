//
//  NPKLocationStore.h
//  distanceFinder3
//
//  Created by Nathan Knable on 11/19/13.
//  Copyright (c) 2013 Nathan Knable. All rights reserved.
//

#import <Foundation/Foundation.h>


@class NPKLocationStore;

@interface NPKLocationStore : NSObject

@property (strong, nonatomic) NSMutableArray *pins;



+ (NPKLocationStore *)sharedStore;


@end
