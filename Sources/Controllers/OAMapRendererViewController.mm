//
//  OAMapRendererController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapRendererViewController.h"

#import "OsmAndApp.h"
#import "OAMapRendererView.h"

#include <QtMath>
#include <QStandardPaths>
#include <OsmAndCore/Map/OnlineMapRasterTileProvider.h>
#include <OsmAndCore/Map/OfflineMapDataProvider.h>
#include <OsmAndCore/Map/OfflineMapRasterTileProvider.h>

@interface OAMapRendererViewController ()

@end

@implementation OAMapRendererViewController
{
    CGFloat _initialZoomLevelDuringGesture;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
}

- (void)dtor
{
    // Allow view to tear down OpenGLES context
    if([self isViewLoaded])
    {
        OAMapRendererView* mapView = (OAMapRendererView*)self.view;
        [mapView releaseContext];
    }
}

- (void)loadView
{
    NSLog(@"Creating Map Renderer view...");
    
    // Inflate map renderer view
    OAMapRendererView* view = [[OAMapRendererView alloc] init];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    view.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Tell view to create context
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    mapView.userInteractionEnabled = YES;
    mapView.multipleTouchEnabled = YES;
    [mapView createContext];
    
    // Attach gesture recognizers:
    
    // - Zoom gesture
    UIPinchGestureRecognizer* grZoom = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(zoomGestureDetected:)];
    grZoom.delegate = self;
    [mapView addGestureRecognizer:grZoom];

    // - Move gesture
    UIPanGestureRecognizer* grMove = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGestureDetected:)];
    grMove.delegate = self;
    grMove.minimumNumberOfTouches = 1;
    grMove.maximumNumberOfTouches = 2;
    [mapView addGestureRecognizer:grMove];
    
    // - Rotation gesture
    UIRotationGestureRecognizer* grRotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateGestureDetected:)];
    grRotate.delegate = self;
    [mapView addGestureRecognizer:grRotate];
}

- (void)viewWillAppear:(BOOL)animated
{
    // Resume rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView resumeRendering];
}

- (void)viewDidDisappear:(BOOL)animated
{
    if(![self isViewLoaded])
        return;

    // Suspend rendering
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    [mapView suspendRendering];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)zoomGestureDetected:(UIPinchGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _initialZoomLevelDuringGesture = mapView.zoom;
            break;
        case UIGestureRecognizerStateChanged:
            mapView.zoom = _initialZoomLevelDuringGesture - (1.0f - recognizer.scale);
            break;
        case UIGestureRecognizerStateEnded:
            mapView.zoom = _initialZoomLevelDuringGesture - (1.0f - recognizer.scale);
            NSLog(@"zoom end velocity = %f", recognizer.velocity);
            break;
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled:
            mapView.zoom = _initialZoomLevelDuringGesture;
            
        default:
            break;
    }
}

- (void)moveGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
    CGPoint translation = [recognizer translationInView:recognizer.view];
    translation.x *= mapView.contentScaleFactor;
    translation.y *= mapView.contentScaleFactor;

    // Take into account current azimuth and reproject to map space (points)
    const float angle = qDegreesToRadians(mapView.azimuth);
    const float cosAngle = cosf(angle);
    const float sinAngle = sinf(angle);
    CGPoint translationInMapSpace;
    translationInMapSpace.x = translation.x * cosAngle - translation.y * sinAngle;
    translationInMapSpace.y = translation.x * sinAngle + translation.y * cosAngle;

    // Taking into account current zoom, get how many 31-coordinates there are in 1 point
    int32_t tileSize31 = 1;
    if(mapView.zoomLevel != OsmAnd::ZoomLevel31)
        tileSize31 = (1u << (31 - mapView.zoomLevel)) - 1;
    const double scale31 = static_cast<double>(tileSize31) / mapView.scaledTileSizeOnScreen;

    // Rescale movement to 31 coordinates
    OsmAnd::PointI target31 = mapView.target31;
    target31.x -= static_cast<int32_t>(round(translationInMapSpace.x * scale31));
    target31.y -= static_cast<int32_t>(round(translationInMapSpace.y * scale31));
    mapView.target31 = target31;
    
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint velocity = [recognizer velocityInView:self.view];
        NSLog(@"move velocity %f %f", velocity.x, velocity.y);
    }
    [recognizer setTranslation:CGPointZero inView:mapView];
}

- (void)rotateGestureDetected:(UIRotationGestureRecognizer*)recognizer
{
    // Ignore gesture if we have no view
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    // Get center of all touches as centroid
    CGPoint centerPoint = [recognizer locationOfTouch:0 inView:self.view];
    for(NSInteger touchIdx = 1; touchIdx < recognizer.numberOfTouches; touchIdx++)
    {
        CGPoint touchPoint = [recognizer locationOfTouch:touchIdx inView:self.view];
        
        centerPoint.x += touchPoint.x;
        centerPoint.y += touchPoint.y;
    }
    centerPoint.x /= recognizer.numberOfTouches;
    centerPoint.y /= recognizer.numberOfTouches;
    centerPoint.x *= mapView.contentScaleFactor;
    centerPoint.y *= mapView.contentScaleFactor;
    
    // Convert point from screen to location
    OsmAnd::PointI centerLocation;
    [mapView convert:centerPoint toLocation:&centerLocation];
    
    // Rotate current target around center location
    OsmAnd::PointI target = mapView.target31;
    target -= centerLocation;
    OsmAnd::PointI newTarget;
    const float cosAngle = cosf(-recognizer.rotation);
    const float sinAngle = sinf(-recognizer.rotation);
    newTarget.x = target.x * cosAngle - target.y * sinAngle;
    newTarget.y = target.x * sinAngle + target.y * cosAngle;
    newTarget += centerLocation;
    mapView.target31 = newTarget;
    
    // Set rotation
    mapView.azimuth -= qRadiansToDegrees(recognizer.rotation);
    
    if(recognizer.state == UIGestureRecognizerStateEnded)
    {
        NSLog(@"rotate velocity %f", recognizer.velocity);
    }
    [recognizer setRotation:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    NSLog(@"MEMWARNING");
}

- (void)activateMapnik
{
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    std::shared_ptr<OsmAnd::IMapBitmapTileProvider> tileProvider = OsmAnd::OnlineMapRasterTileProvider::createMapnikProvider();
    OsmAnd::OnlineMapRasterTileProvider* onlineTileProvider = dynamic_cast<OsmAnd::OnlineMapRasterTileProvider*>(tileProvider.get());
    onlineTileProvider->setLocalCachePath(QDir(QDir(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)).filePath("Mapnik cache")));
    [mapView setProvider:tileProvider ofLayer:OsmAnd::RasterMapLayerId::BaseLayer];
    mapView.azimuth = 0.0f;
    mapView.elevationAngle = 90.0f;
    mapView.target31 = OsmAnd::PointI(1102430866, 704978668);
    mapView.zoom = 10.0f;
}

- (void)activateCyclemap
{
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    std::shared_ptr<OsmAnd::IMapBitmapTileProvider> tileProvider = OsmAnd::OnlineMapRasterTileProvider::createCycleMapProvider();
    OsmAnd::OnlineMapRasterTileProvider* onlineTileProvider = dynamic_cast<OsmAnd::OnlineMapRasterTileProvider*>(tileProvider.get());
    onlineTileProvider->setLocalCachePath(QDir(QDir(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)).filePath("CycleMap cache")));
    [mapView setProvider:tileProvider ofLayer:OsmAnd::RasterMapLayerId::BaseLayer];
    mapView.azimuth = 0.0f;
    mapView.elevationAngle = 90.0f;
    mapView.target31 = OsmAnd::PointI(1102430866, 704978668);
    mapView.zoom = 10.0f;
}

- (void)activateOffline
{
    if(![self isViewLoaded])
        return;
    
    OAMapRendererView* mapView = (OAMapRendererView*)self.view;
    
    std::shared_ptr<OsmAnd::MapStyle> mapStyle;
    [OsmAndApp instance].mapStyles->obtainStyle("default", mapStyle);
    std::shared_ptr<OsmAnd::OfflineMapDataProvider> offlineMapDP(new OsmAnd::OfflineMapDataProvider([OsmAndApp instance].obfsCollection, mapStyle));
    
    std::shared_ptr<OsmAnd::IMapBitmapTileProvider> tileProvider = std::shared_ptr<OsmAnd::IMapBitmapTileProvider>(new OsmAnd::OfflineMapRasterTileProvider(offlineMapDP, 2.0f));
    [mapView setProvider:tileProvider ofLayer:OsmAnd::RasterMapLayerId::BaseLayer];
    mapView.azimuth = 0.0f;
    mapView.elevationAngle = 90.0f;
    mapView.target31 = OsmAnd::PointI(1102430866, 704978668);
    mapView.zoom = 10.0f;
}

@end