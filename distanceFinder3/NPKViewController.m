//
//  NPKViewController.m
//  distanceFinder3
//
//  Created by Nathan Knable on 10/31/13.
//  Copyright (c) 2013 Nathan Knable. All rights reserved.
//

#import "NPKViewController.h"
#import "NPKPin.h"
#import "NPKLocationStore.h"
#import "NPKOverlayAreaView.h"

@interface NPKViewController ()

@property (nonatomic, strong) UIPopoverController *buttonPopoverController;

@property (strong, nonatomic) IBOutlet MKMapView *mainMap;
@property (weak, nonatomic) NSString *identifier;
@property (nonatomic)       Boolean isPinSelected;


@property (strong, nonatomic) CLLocationManager   *locationManager;
@property (strong, nonatomic) CLLocation          *lastLocation;
@property (nonatomic)         CLLocationDirection *heading;
@property (nonatomic)         BOOL                isUpdatingLocation;


@property (strong, nonatomic) NSMutableArray *pins;
@property (strong, nonatomic) NSString *lengthType;

@property (weak, nonatomic) IBOutlet UIButton *locateButton;
@property (weak, nonatomic) IBOutlet UIButton *areaButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteAreaButton;
@property (weak, nonatomic) IBOutlet UIButton *deletePinButton;

@property (nonatomic) BOOL isFindingArea;
@property (nonatomic) CGPoint startingPoint;
@property (nonatomic) CGPoint endingPoint;
@property (nonatomic) int count;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *convertButton;
@property(nonatomic) BOOL firstTimeUpdatingMap;


@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;


@property (strong, nonatomic) MKPolyline *routeLine;
@property (strong, nonatomic) MKPolylineRenderer *routeLineView;
@property (strong, nonatomic) NSMutableArray *routeLines;

@property (strong, nonatomic) UIView *areaOverlay;
@property (strong, nonatomic) NPKOverlayAreaView *areaView;
@property (strong, nonatomic) MKPolygonRenderer *polygonRenderer;
@property (strong, nonatomic) NSMutableArray *areaPoints;
@property (strong, nonatomic) NSMutableArray *areaViews;



@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (strong, nonatomic) NSMutableArray *matchingItems;

@property (strong, nonatomic) NSMutableArray *lineDistances;

 
- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer;


@end

@implementation NPKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.identifier           = @"myAnnotation";
    self.count                = 0;
    self.isUpdatingLocation   = nil;
    self.firstTimeUpdatingMap = YES;
    self.searchField.delegate = self;
    self.locationManager      = [[CLLocationManager alloc] init];
    self.mainMap              = [[MKMapView alloc] initWithFrame:self.view.frame];
    self.mainMap.mapType      = MKMapTypeSatellite;
    self.mainMap.delegate     = self;
    self.pins                 = [[NSMutableArray alloc] init];
    self.areaView             = [[NPKOverlayAreaView alloc]  init];
    self.areaPoints           = [[NSMutableArray alloc] init];
    self.areaViews            = [[NSMutableArray alloc]  init];
    self.routeLines           = [[NSMutableArray alloc] init];
    self.lengthType           = @"meter";
    
    self.navigationController.toolbarHidden = NO;
    
    [self.locationManager setDelegate:self];
    [self.locationManager requestAlwaysAuthorization];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];


    UIToolbar *toolBar = [[UIToolbar alloc]initWithFrame:CGRectMake(00,
                                                                    self.view.frame.size.height,
                                                                    self.view.frame.size.width,
                                                                    44)];
    
    UILongPressGestureRecognizer * longPressGesturePins  = [[UILongPressGestureRecognizer alloc]
                                                                initWithTarget:self
                                                                action:@selector(longPressDeletePins)];
    UILongPressGestureRecognizer * longPressGestureAreas = [[UILongPressGestureRecognizer alloc]
                                                                initWithTarget:self
                                                                action:@selector(longPressDeleteAreas)];

    [longPressGesturePins setMinimumPressDuration:1];
    [longPressGesturePins setMinimumPressDuration:1];

    
    [self.deletePinButton  addGestureRecognizer:longPressGesturePins];
    [self.deleteAreaButton addGestureRecognizer:longPressGestureAreas];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tap];
    
    [self.view addSubview:self.mainMap];
    [self.view addSubview:toolBar];

    
    UIDevice* device = [UIDevice currentDevice];
    BOOL backgroundSupported = NO;
    if ([device respondsToSelector:@selector(isMultitaskingSupported)])
        backgroundSupported = device.multitaskingSupported;

    if (backgroundSupported) {
        NSLog(@"can be background");
    }
    
    
    
}




-(void)performSearch
{
    self.matchingItems = [[NSMutableArray alloc] init];
    MKLocalSearchRequest *request =
    [[MKLocalSearchRequest alloc] init];
    request.naturalLanguageQuery = self.searchField.text;
    request.region = self.mainMap.region;
    
    
    MKLocalSearch *search =
    [[MKLocalSearch alloc]initWithRequest:request];
    
    [search startWithCompletionHandler:^(MKLocalSearchResponse
                                         *response, NSError *error) {
        if (response.mapItems.count == 0)
            NSLog(@"No Matches");
        else
            for (MKMapItem *item in response.mapItems)
            {
                [self.matchingItems addObject:item];
                MKPointAnnotation *annotation =
                [[MKPointAnnotation alloc]init];
                annotation.coordinate = item.placemark.coordinate;
                annotation.title = item.name;
                [self.mainMap addAnnotation:annotation];
                [self.pins addObject:annotation];
            }
    }];
    
}



- (IBAction)searchDoneEdit:(id)sender
{
    
    [sender resignFirstResponder];
    [self.mainMap removeAnnotations:[self.mainMap annotations]];
    [self performSearch];
    
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    //NSLog(@"dragging");

    NPKPin *pin = (NPKPin *)view.annotation;
    
    if (newState == MKAnnotationViewDragStateStarting) {
        NSLog(@"starting drag");
        [self.pins removeObject:pin];
        [self.mainMap removeOverlays:self.routeLines];

        //NSLog(@"array position %lu", pin.arrayPosition);
        
        if ([self.pins count] > 1) {
            //[self drawLines];
        }
    }
    
    if (newState == MKAnnotationViewDragStateDragging) {
        NSLog(@"hi");
    }
    
    if (newState == MKAnnotationViewDragStateEnding)
    {
        NPKPin *pin = (NPKPin *)view.annotation;
        
        
        NSLog(@"ending drag");
        [self.pins insertObject:pin atIndex:(pin.arrayPosition - 1)];
        //[self.mainMap removeOverlays:self.routeLines];

        if ([self.pins count] > 1) {
            [self drawLines];
        }
        [self.mainMap deselectAnnotation:pin animated:NO];
    }
}



-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{

    if([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    
    MKAnnotationView *annotationView = (MKAnnotationView*)
                            [self.mainMap dequeueReusableAnnotationViewWithIdentifier:self.identifier];
    if (!annotationView)
    {
        NSLog(@"new annotation");
 
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:self.identifier];
        
        annotationView.draggable = YES;
        annotationView.canShowCallout = YES;
        annotationView.image = [UIImage imageNamed:@"marker.png"];
    
        
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
        annotationView.rightCalloutAccessoryView = rightButton;
        
        // Add a custom image to the left side of the callout.
        UIImageView *myCustomImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MyCustomImage.png"]];
        annotationView.leftCalloutAccessoryView = myCustomImage;
        
        UIView *pinView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, 20, 40)];
        UITapGestureRecognizer *tapped =[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleTapOnPin:)];
        [pinView addGestureRecognizer:tapped];
        //pinView.backgroundColor = [UIColor redColor];
        
        [annotationView addSubview:pinView];

    }else {

        annotationView.annotation = annotation;
    }
    return annotationView;
}

- (IBAction)handleTapOnPin:(UITapGestureRecognizer *)recognizer
{
    UIView *pin = recognizer.view;
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[pin superview];
    [self.mainMap selectAnnotation:[pinView annotation] animated:YES];
    
}

-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    self.isPinSelected = NO;
    view.selected = NO;
    
}

-(void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    self.isPinSelected = YES;
    view.selected = YES;
}



-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // this will make the gps work
    
    
    [self setLastLocation:[locations lastObject]];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([[locations lastObject] coordinate], 100, 100);
    
    if (self.firstTimeUpdatingMap) {
        [self.mainMap setRegion:region animated:YES];
        [self setFirstTimeUpdatingMap:NULL];
    }
    
    
}


- (IBAction)addAreaView:(id)sender
{
    [self.areaButton setImage:[UIImage imageNamed:@"redRect.png"] forState:UIControlStateNormal];
    UIView *areaView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [areaView addGestureRecognizer:gestureRecognizer];
    self.areaOverlay= areaView;
    
    [self.view addSubview:areaView];
    
}




-(IBAction)handlePan:(UIPanGestureRecognizer *)recognizer
{
    
    self.count++;

    
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        self.startingPoint = [recognizer locationInView:self.mainMap];
    }
    
    self.endingPoint = [recognizer locationInView:self.mainMap];

 
    
    CGRect area = CGRectMake(self.startingPoint.x, self.startingPoint.y
                             , self.endingPoint.x - self.startingPoint.x,
                             self.endingPoint.y - self.startingPoint.y);
    
    
    
    
    if (self.count > 1) {
        UIView *areaView = [[UIView alloc] initWithFrame:area];
        [areaView setBackgroundColor:[[UIColor cyanColor] colorWithAlphaComponent:0.5]];
        [areaView setOpaque:YES];
        [self.areaOverlay addSubview:areaView];
        [self.areaOverlay setNeedsDisplay];
    }
    
    
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [[self.areaOverlay subviews]
         makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        CLLocationCoordinate2D firstPoint2d = [self.mainMap convertPoint:self.startingPoint toCoordinateFromView:self.mainMap];
        
        CLLocationCoordinate2D thirdPoint2d = [self.mainMap convertPoint:self.endingPoint toCoordinateFromView:self.mainMap];
        
        
        CLLocationCoordinate2D coords[4]={
            [self.mainMap convertPoint:self.startingPoint toCoordinateFromView:self.mainMap],
            CLLocationCoordinate2DMake(thirdPoint2d.latitude, firstPoint2d.longitude),
            [self.mainMap convertPoint:self.endingPoint toCoordinateFromView:self.mainMap],
            CLLocationCoordinate2DMake(firstPoint2d.latitude, thirdPoint2d.longitude)
        };


        MKPolygon *square = [MKPolygon polygonWithCoordinates:coords count:4];
        
        [self.mainMap addOverlay:square];
        [self.areaViews  addObject:square];
        
        [self.areaOverlay removeFromSuperview];
        [self.areaButton setImage:[UIImage imageNamed:@"area.png"] forState:UIControlStateNormal];


        [self calculateArea];

    }
    
    
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.areaView];
    
}





- (MKMapRect)mapRectForRect:(CGRect)rect
{
    CLLocationCoordinate2D topleft = [self.mainMap convertPoint:CGPointMake(rect.origin.x, rect.origin.y) toCoordinateFromView:self.areaView];
    CLLocationCoordinate2D bottomeright = [self.mainMap convertPoint:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)) toCoordinateFromView:self.areaView];
    MKMapPoint topleftpoint = MKMapPointForCoordinate(topleft);
    MKMapPoint bottomrightpoint = MKMapPointForCoordinate(bottomeright);
    
    return MKMapRectMake(topleftpoint.x, topleftpoint.y, bottomrightpoint.x - topleftpoint.x, bottomrightpoint.y - topleftpoint.y);
}

-(void)calculateArea
{
    

    
    CLLocationCoordinate2D firstPoint2d = [self.mainMap convertPoint:self.startingPoint toCoordinateFromView:self.mainMap];
    CLLocation *firstPoint = [[CLLocation alloc] initWithLatitude:firstPoint2d.latitude longitude:firstPoint2d.longitude];
    CLLocationCoordinate2D secondPoint2d = [self.mainMap convertPoint:self.endingPoint toCoordinateFromView:self.mainMap];
    CLLocation *secondPoint = [[CLLocation alloc] initWithLatitude:firstPoint2d.latitude
                                                         longitude:secondPoint2d.longitude];
    
    CLLocationDistance widthLineDistance = [firstPoint distanceFromLocation:secondPoint];
    
    CLLocation *thirdPoint = [[CLLocation alloc] initWithLatitude:secondPoint2d.latitude longitude:firstPoint2d.longitude];
    
    CLLocationDistance hightLineDistance = [firstPoint distanceFromLocation:thirdPoint];
    
    CLLocationDistance area = widthLineDistance * hightLineDistance;
    
    if ([self.lengthType  isEqual: @"meter"]) {
        self.navigationItem.title = [NSString stringWithFormat:@"%f Sq Meters", area];
        
    } else if ([self.lengthType isEqual:@"mile"]) {
        self.navigationItem.title = [NSString stringWithFormat:@"%f Sq Miles", area * 0.000621371];
        
    }

    
    
}



- (IBAction)locateButtonTapped:(id)sender
{
    
    // this will start updating the location
    
    if (self.isUpdatingLocation) {
        [self.locateButton setImage:[UIImage imageNamed:@"locate.png"] forState:UIControlStateNormal];

        [self.locationManager stopUpdatingLocation];
        [self.mainMap setShowsUserLocation:NO];
        

        [self setIsUpdatingLocation:NO];
    } else {
        [self.locateButton setImage:[UIImage imageNamed:@"locatePurple.png"] forState:UIControlStateNormal];
        [self.locationManager startUpdatingLocation];
        [self.mainMap setShowsUserLocation:YES];
        [self setFirstTimeUpdatingMap:YES];
        
        [self setIsUpdatingLocation:YES];
    }
    
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
        [self.routeLines addObject:self.routeLine];
        
        [self.mainMap addOverlay:self.routeLine];
        
        
        free(pointArr);
        
    } else {
        NSLog(@"no pins");
    }
    
    // this calculates the distance
    
    NPKPin *currentPin;
    NPKPin *lastPin;
    CLLocationDistance lineDistance = 0.0;
    
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
                
                if ([self.lengthType  isEqual: @"meter"]) {
                    self.navigationItem.title = [NSString stringWithFormat:@"%f meters", lineDistance];

                } else if ([self.lengthType isEqual:@"mile"]) {
                    self.navigationItem.title = [NSString stringWithFormat:@"%f miles", lineDistance * 0.000621371];

                }
                
                
            }
        }
    }
    
}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    
    
    if(overlay == self.routeLine)
    {
        self.routeLineView = [[MKPolylineRenderer alloc] initWithPolyline:self.routeLine];
        self.routeLineView.fillColor = [UIColor colorWithRed:0.945 green:0.027 blue:0.957  alpha:1];
        self.routeLineView.strokeColor = [UIColor colorWithRed:0.945 green:0.027 blue:0.957 alpha:1];
        self.routeLineView.lineWidth = 5;
        
        overlay = self.routeLineView;
    }
    

    if ([overlay isKindOfClass:[MKPolygon class]])
    {
        self.polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        self.polygonRenderer.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        self.polygonRenderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        self.polygonRenderer.lineWidth = 3;
        overlay = self.polygonRenderer;
    }
    
    return overlay;
    

}

- (IBAction)handleTap:(UITapGestureRecognizer *)recognizer
{
    
    
    NSLog(@"handle tap");

    if (!self.isPinSelected) {
        
    
        CGPoint touchPoint = [recognizer locationInView:self.mainMap];
        CLLocationCoordinate2D location = [self.mainMap convertPoint:touchPoint toCoordinateFromView:self.mainMap];
        
        NPKPin *newPin = [[NPKPin alloc] initWithCoordinates:location];

        [self.mainMap addAnnotation:newPin];

        [self.pins addObject:newPin];
        
        
        newPin.arrayPosition = [self.pins count];
        
        if (self.pins.count > 1) {
            [self drawLines];
        }
    }
    
}


- (IBAction)convertButton:(id)sender
{
    NSLog(@"convert");
    if ([self.lengthType isEqual:@"meter"]) {
        self.lengthType = @"mile";
        [self.convertButton setTitle:@"mile"];
    } else if ([self.lengthType isEqual:@"mile"]) {
        self.lengthType = @"meter";
        [self.convertButton setTitle:@"meter"];

    }
    
    
}


-(void)longPressDeletePins
{
    [self.mainMap removeOverlays:self.routeLines];
    [self.mainMap removeAnnotations:[self.mainMap annotations]];
    
    
    if (self.pins.count > 0) {
        [self.pins removeAllObjects];
    }
    
    if (self.routeLines > 0) {
        [self.routeLines removeAllObjects];
        
    }
    
    
}

- (IBAction)deletePin:(id)sender
{
    // this will delete a pin and remove it from hthe array
    
    [self.mainMap removeAnnotation:[self.pins lastObject]];
    [self.mainMap removeOverlays:self.routeLines];
    
    if (self.pins.count > 0) {
        [self.pins removeLastObject];
    }
    
    if (self.routeLines > 0) {
        [self.routeLines removeAllObjects];
    }
    
    [self drawLines];
    
    //self.areaOverlay= [[UIView alloc] init];
    
    
}
- (IBAction)deleteArea:(id)sender
{
    [self.mainMap removeOverlay:[self.areaViews lastObject]];
    
    if (self.areaViews.count > 0) {
        [self.areaViews removeLastObject];
    }
    
    [self.mainMap setNeedsDisplay];
}

-(void)longPressOnPin
{
    NSLog(@"long pressed pin");
}

-(void)longPressDeleteAreas
{
    [self.mainMap removeOverlays:self.areaViews];
    
    if (self.areaViews.count > 0) {
        [self.areaViews removeAllObjects];
    }
    [self.mainMap setNeedsDisplay];
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
