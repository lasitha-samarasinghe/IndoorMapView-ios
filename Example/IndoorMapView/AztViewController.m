//
//  AztViewController.m
//  IndoorMapView
//
//  Created by Lasitha Samarasinghe on 05/12/2016.
//  Copyright (c) 2016 Lasitha Samarasinghe. All rights reserved.
//

#import "AztViewController.h"
#import "MapView.h"
#import "MapPoint.h"
#import "MapMarker.h"

@interface AztViewController ()<IndoorMapDelegate>
{
    MapView* mapView;
    BOOL isTapMarkerEnabled;
}

@end

@implementation AztViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    isTapMarkerEnabled = NO;
//    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapClicked:)];
//    singleTap.numberOfTapsRequired = 1;
//    [self.view setUserInteractionEnabled:YES];
//    [self.view addGestureRecognizer:singleTap];
//    [[UIApplication sharedApplication].keyWindow bringSubviewToFront:self.view];
}

-(void)viewDidAppear:(BOOL)animated
{
    NSURL* url = [[NSURL alloc]initWithString:@"http://fmdev.ivivacloud.com/LayoutUtil/tile/30/77bd552f-e477-4ddc-919b-ba0285b70afb"];
    NSURL* url2 = [[NSURL alloc]initWithString:@"http://fmdev.ivivacloud.com/LayoutUtil/tile/31/b7fa30b1-79f1-4173-bc30-084cd64c3fdc"];
    CGSize size = CGSizeMake(256, 256);
//    CGSize size = CGSizeMake(2048, 2048);
    mapView = [[MapView alloc]init];
    [mapView setupWithURL:url forView:self.view withLevels:2.0 withTileSize:size];
    self.view = mapView;
    mapView.mapDelegate = self;
    [mapView setMarkerWithId:120 forLongitude:0 withLatitude:0 withImage:[UIImage imageNamed:@"sample"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)enableOnTapMarker:(BOOL)state
{
    isTapMarkerEnabled = state;
}

-(void)setMap:(int)level
{
    NSURL* url = [[NSURL alloc]initWithString:@"http://fmdev.ivivacloud.com/LayoutUtil/tile/30/77bd552f-e477-4ddc-919b-ba0285b70afb"];
    CGSize size = CGSizeMake(256, 256);
    mapView = [[MapView alloc]init];
    [mapView setupWithURL:url forView:self.view withLevels:level withTileSize:size];
    self.view = mapView;
    mapView.mapDelegate = self;
    [mapView setMarkerWithId:120 forLongitude:0 withLatitude:0 withImage:[UIImage imageNamed:@"sample"]];
}

- (void) onMapClicked:(MapPoint*)point
{
//    NSLog(@"map clicked at %f %f",point.longitude,point.latitude);
    if(isTapMarkerEnabled)
    {
        [mapView setMarkerWithId:120 forLongitude:point.longitude withLatitude:point.latitude withImage:[UIImage imageNamed:@"sample"]];
    }
}

-(void)onMarkerClicked:(MapMarker*)marker
{
//    NSLog(@"marker clicked %d",marker.id);
}
@end
