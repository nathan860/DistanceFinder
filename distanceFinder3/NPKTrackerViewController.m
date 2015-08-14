//
//  NPKTrackerViewController.m
//  distanceFinder3
//
//  Created by Nathan Knable on 7/2/14.
//  Copyright (c) 2014 Nathan Knable. All rights reserved.
//

#import "NPKTrackerViewController.h"
#import "NPKPin.h"
#import "NPKLocationStore.h"


@interface NPKTrackerViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *mainMap;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *lastLocation;
@property (nonatomic) CLLocationDirection *heading;
@property (nonatomic) BOOL isUpdatingLocation;

@property (strong, nonatomic) NSMutableArray *pins;
//@property (nonatomic, strong) NSMutableDictionary *pathInfo;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *convertButton;
@property (strong, nonatomic) NSString *lengthType;
@property (nonatomic) int count;

@property(nonatomic) BOOL firstTimeUpdatingMap;

@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;


@property (strong, nonatomic) MKPolyline *routeLine;
@property (strong, nonatomic) MKPolylineRenderer *routeLineView;

@property (strong, nonatomic) MKOverlayPathRenderer *overlayPathRenderer;
@property (strong, nonatomic) NSMutableArray *lineDistances;



@end

@implementation NPKTrackerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isUpdatingLocation = nil;
    self.firstTimeUpdatingMap = YES;
    self.lengthType = @"meter";
    self.count = 0;    self.navigationController.toolbarHidden = NO;
    //self.pathInfo = [[NSMutableDictionary alloc] init];
    
    
    self.locationManager = [[CLLocationManager alloc] init];
    //[self.locationManager requestAlwaysAuthorization];
    
    
    [self.locationManager setDelegate:self];
    
    
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    self.mainMap.mapType = MKMapTypeSatellite;
    self.mainMap.delegate = self;
    self.pins = [[NSMutableArray alloc] init];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // this will make the gps work
    
    [self setLastLocation:[locations lastObject]];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([[locations lastObject] coordinate], 100, 100);
    
    if (self.firstTimeUpdatingMap) {
        [self.mainMap setRegion:region animated:YES];
        [self setFirstTimeUpdatingMap:nil];
    }
    
    [self dropPin];
    
    
}

- (IBAction)locateButtonTapped:(id)sender
{
        // this will start updating the location
        
        if (self.isUpdatingLocation) {
            [self.locationManager stopUpdatingLocation];
            [self.mainMap setShowsUserLocation:NO];
            
            [self setIsUpdatingLocation:NO];
        } else {
            [self.locationManager startUpdatingLocation];
            [self.mainMap setShowsUserLocation:YES];
            [self setFirstTimeUpdatingMap:YES];
            
            [self setIsUpdatingLocation:YES];
        }
    
}


-(void)dropPin
{
    self.count++;
    NSLog(@"");
    // this will make sure the location is accurate before starting tracking
    if (self.count > 5) {
        CLLocationCoordinate2D lastLocation = self.lastLocation.coordinate;
        
        //NPKPin *newPin = [[NPKPin alloc] initWithCoordinates:lastLocation placeName:@"Pin" description:@"pin"];
        //[newPin ];
        //[self.pins addObject:newPin];
        
        
        //[self.mainMap addAnnotation:newPin];
        //[[self.mainMap viewForAnnotation:newPin] setHidden:YES];

        
        // this will make sure there are more then two pins to drop
        if (self.pins.count > 1) {
            [self drawLines];
        }

    }
}

- (IBAction)deleteAllTapped:(id)sender
{
    // this will delete a pin and remove it from hthe array
    
    [self.mainMap removeAnnotations:self.pins];
    [[self pins] removeAllObjects];
    [self.mainMap removeOverlays:[self.mainMap overlays]];
    [self drawLines];
    
}




-(void)drawLines
{
    
    // this draws the lines
    
    NSInteger count = 0;
    
    if ([self.pins count] != 0) {
        
        MKMapPoint* pointArr = malloc(sizeof(CLLocationCoordinate2D) * [self.pins count]);
        
        for (NPKPin *pin in self.pins) {
            
            
            CLLocationCoordinate2D currentCoordinate;
            currentCoordinate.latitude = [pin coordinate].latitude;
            currentCoordinate.longitude = [pin coordinate].longitude;
            MKMapPoint point = MKMapPointForCoordinate(currentCoordinate);
            
            pointArr[count] = point;
            count++;
        }
        
        
        
        self.routeLine = [MKPolyline polylineWithPoints:pointArr count:[self.pins count]];
        
        [self.mainMap addOverlay:self.routeLine];
        
        
        free(pointArr);
        
    } else {
        NSLog(@"no pins");
    }
    
    // this calculates the distance
    
    NPKPin *currentPin;
    NPKPin *lastPin;
    CLLocationDistance lineDistance = 0.0;
    //float converted;
    
    if([self.pins count] != 0 ){
        for (NSInteger index = 0; index < [self.pins count]; index++) {
            [self.pins objectAtIndex:index];
            if (index == 0) {
                
            } else {
                currentPin = [self.pins objectAtIndex:index];
                lastPin = [self.pins objectAtIndex:index - 1];
                CLLocation *firstPoint = [[CLLocation alloc] initWithLatitude:currentPin.coordinate.latitude
                                                                    longitude:currentPin.coordinate.longitude];
                CLLocation *secondPoint = [[CLLocation alloc] initWithLatitude:lastPin.coordinate.latitude
                                                                     longitude:lastPin.coordinate.longitude];
                lineDistance += [firstPoint distanceFromLocation:secondPoint];
                //[self.pathInfo setObject:forKey:@"distance"];
                
                if ([self.lengthType  isEqual: @"meter"]) {
                    self.navigationItem.title = [NSString stringWithFormat:@"%f meters", lineDistance];
                } else if ([self.lengthType isEqual:@"mile"]) {
                    
                    self.navigationItem.title = [NSString stringWithFormat:@"%f miles", lineDistance * 0.000621371];
                    
                }
                
                
            }
        }
    }
    
}

- (IBAction)deletePin:(id)sender
{
    
    // this will delete a pin and remove it from hthe array
    
    //NSLog(@"before %d", self.pins.count);
    [self.mainMap removeAnnotation:[self.pins lastObject]];
    if (self.pins.count > 0) {
        [self.pins removeLastObject];
    }
    //NSLog(@"after %d", self.pins.count);
    
    [self.mainMap removeOverlays:[self.mainMap overlays]];
    [self drawLines];
    
    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    MKOverlayRenderer* overlayView = nil;
    
    
    if(overlay == self.routeLine)
    {
        self.routeLineView = [[MKPolylineRenderer alloc] initWithPolyline:self.routeLine];
        self.routeLineView.fillColor = [UIColor colorWithRed:0.945 green:0.027 blue:0.957  alpha:1];
        self.routeLineView.strokeColor = [UIColor colorWithRed:0.945 green:0.027 blue:0.957 alpha:1];
        self.routeLineView.lineWidth = 5;
        
        overlayView = self.routeLineView;
    }
    return overlayView;
    
}



- (IBAction)convertButtonTapped:(id)sender
{
    if ([self.lengthType isEqual:@"meter"]) {
        self.lengthType = @"mile";
        [self.convertButton setTitle:@"mile"];
    } else if ([self.lengthType isEqual:@"mile"]) {
        self.lengthType = @"meter";
        [self.convertButton setTitle:@"meter"];
        
    }
    [self drawLines];
}

- (IBAction)saveButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"toTable" sender:nil];
    
}



@end
