//
//  MapView.m
//  Pods
//
//  Created by Lasitha Samarasinghe on 5/12/16.
//
//

#import "MapView.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKGeometry.h>

#define TILE_IMAGES 1

static NSURL* _mapURL;
static float _levels;
static CGSize _tileSize;
static int _tilesPerTile;
static CGFloat _currentLevel;

#if !TILE_IMAGES
    static UIImage *_ImageAtIndex(NSUInteger index);
#endif

#if TILE_IMAGES
    TilingView *_tilingView;
    static UIImage *_PlaceholderImageNamed(NSString *name);
    static CGSize _ImageSizeAtIndex(NSUInteger index);
#endif

@implementation MapView
{
    NSNumber* _northAngle;
    CGPoint _pointToCenterAfterResize;
    CGFloat _scaleToRestoreAfterResize;
    UIImageView *_zoomView;
    CGSize _imageSize;
    CGFloat _maxZoom;
    NSMutableArray* markers;
    BOOL isMarker;
    BOOL shouldShowAnnotation;
    UIView* annotationView;
    MapMarker* selectedMarker;
}

#pragma mark - init
-(void)setupWithURL:(NSURL*)url forView:(UIView*)view withLevels:(float)levels withTileSize:(CGSize)size
{
    if (self)
    {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
    }
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _mapURL = url;
    _levels = levels;
    _tileSize = size;
    _currentLevel = 0;
    _maxZoom = 0;
    isMarker = NO;
    shouldShowAnnotation = YES;
    self.layer.shouldRasterize = NO;
    [self setIndex:0];
    self.userInteractionEnabled = YES;
    self.backgroundColor = [UIColor grayColor];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapClicked:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.cancelsTouchesInView = NO;
    [self addGestureRecognizer:singleTap];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;
        self.bouncesZoom = YES;
        self.decelerationRate = UIScrollViewDecelerationRateFast;
        self.delegate = self;
    }
    return self;
}

#pragma mark - public functions

-(void)setCurrentZoom:(CGFloat)zoom
{
    _currentLevel = zoom;
    [UIView animateWithDuration:1.0
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ [self setZoomScale:_currentLevel animated:NO]; }
                     completion:nil];
}

-(void)setMaximumZoom:(CGFloat)zoom
{
    _maxZoom = zoom;
}


-(void)setMarkerWithId:(int)mid forLongitude:(float)longitude withLatitude:(float)latitude
{
    UIImage* image = [self bundledImageNamed:@"pin"];
    [self setMarkerWithId:mid forLongitude:longitude withLatitude:latitude withImage:image];
}

-(void)setMarkerWithId:(int)mid forLongitude:(float)longitude withLatitude:(float)latitude withImage:(UIImage*)image
{
    [self setMarkerWithId:mid forLongitude:longitude withLatitude:latitude withImage:image withTitle:nil withDescription:nil];
}

-(void)setMarkerWithId:(int)mid forLongitude:(float)longitude withLatitude:(float)latitude withImage:(UIImage*)image withTitle:(NSString*)title withDescription:(NSString*)description
{
    if(markers == nil)
    {
        markers = [[NSMutableArray alloc]init];
    }
    MapMarker* newMarker = [self createMarker:nil forLongitude:longitude withLatitude:latitude withImage:image];
    newMarker.id = mid;
    newMarker.title = title;
    newMarker.descriptionText = description;
    [_tilingView addSubview:newMarker.button];
    [markers addObject:newMarker];
}

#pragma mark - private functions
-(MapMarker*)createMarker:(UIButton*)button forLongitude:(float)longitude withLatitude:(float)latitude withImage:(UIImage*)image
{
    int pinSize = 40/self.zoomScale;
    MapMarker* mark = [[MapMarker alloc]init];
    mark.longitude = longitude;
    mark.latitude = latitude;
    mark.image = image;
    CLLocationCoordinate2D  ctrpoint = CLLocationCoordinate2DMake(mark.latitude, mark.longitude);
    MKMapPoint ptr = MKMapPointForCoordinate(ctrpoint);
    mark.x = (ptr.x*pow(2, _levels-1)*pow(2, _levels-1))/(_tilingView.frame.size.width*4096);
    mark.y = (ptr.y*pow(2, _levels-1)*pow(2, _levels-1))/(_tilingView.frame.size.height*4096);
    mark.button = [[UIButton alloc]initWithFrame:CGRectMake(mark.x -pinSize/2, mark.y -pinSize, pinSize, pinSize)];
    UIImage* scaledImage = image;
    if(mark.button.frame.size.width>image.size.width && mark.button.frame.size.height>image.size.height)
    {
        scaledImage = [self scaleImage:image forRect:mark.button.frame];
    }
    [mark.button setImage:scaledImage forState:normal];
    mark.button.userInteractionEnabled = YES;
    [mark.button addTarget:self action:@selector(markerClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    UIPanGestureRecognizer *panRecognizer;
    panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(wasDragged:)];
    [mark.button addGestureRecognizer:panRecognizer];
    mark.button.tag = markers.count;
    return mark;
}

/*
-(void)createAnnotationForMarker:(MapMarker*)marker
{
    selectedMarker = marker;
    [annotationView removeFromSuperview];
    marker.title = @"Sorry about the  confusion. That's a shortcut I added with a UIView catagory. Why are you using self.bounds instead of self.frame?";
    marker.descriptionText = @"Sorry about the  confusion. That's a shortcut I added with a UIView catagory. Why are you using self.bounds instead of self.frame?";
    UIFont *systemFont = [UIFont systemFontOfSize:14];
    NSDictionary *attributes = @{NSFontAttributeName: systemFont};
    CGSize descTextSize = [marker.descriptionText sizeWithAttributes:attributes];
    
    UIFont *systemFontBold = [UIFont systemFontOfSize:16 weight:3];
    NSDictionary *attributesBold = @{NSFontAttributeName: systemFontBold};
    CGSize titleTextSize = [marker.title sizeWithAttributes:attributesBold];
    
    UILabel* lblTitle;
    UILabel* lblDescription;
    
    float pad20 = 20;
    float pad10 = 10;
    float pad5 = 5;

    //overflows bounds of mapview
    if (titleTextSize.width > self.frame.size.width-pad20) {
        int lines = ceil(titleTextSize.width / (self.frame.size.width-pad20-2*pad5));
        if (marker.title.length==0) {
            lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(pad5, pad5, 0, 0)];
        }
        else
        {
            lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(pad5, pad5, self.frame.size.width-pad20, lines*(titleTextSize.height)+pad5)];
        }
        lblTitle.numberOfLines = lines;
    }
    else
    {
        if (marker.title.length==0) {
            lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(pad5, pad5, 0, 0)];
        }
        else
        {
            lblTitle = [[UILabel alloc]initWithFrame:CGRectMake(pad5, pad5, titleTextSize.width, titleTextSize.height+pad5)];
        }
    }
    [lblTitle setFont:systemFontBold];
    lblTitle.text = marker.title;
    
    //overflows bounds of mapview
    if (descTextSize.width > self.frame.size.width-pad20) {
        int lines = ceil(descTextSize.width / (self.frame.size.width-pad20-2*pad5));
        if (marker.description.length==0) {
            lblDescription = [[UILabel alloc]initWithFrame:CGRectMake(pad5, pad5, 0, 0)];
        }
        else
        {
            lblDescription = [[UILabel alloc]initWithFrame:CGRectMake(pad5, lblTitle.frame.origin.y+lblTitle.frame.size.height, self.frame.size.width-pad20, lines*(descTextSize.height )+pad5)];
        }

        lblDescription.numberOfLines = lines;
    }
    else
    {
        if (marker.descriptionText.length==0) {
            lblDescription = [[UILabel alloc]initWithFrame:CGRectMake(pad5, pad5, 0, 0)];
        }
        else
        {
            lblDescription = [[UILabel alloc]initWithFrame:CGRectMake(pad5, lblTitle.frame.origin.y+lblTitle.frame.size.height, descTextSize.width, descTextSize.height + pad5)];
        }
    }
    [lblDescription setFont:systemFont];
    lblDescription.text = marker.descriptionText;
    
    float width = ((titleTextSize.width>descTextSize.width)?lblTitle.frame.size.width:lblDescription.frame.size.width)+pad10;
    float height = lblTitle.frame.size.height+lblDescription.frame.size.height+pad10;
    CGPoint newPoint = [_tilingView convertPoint:CGPointMake(marker.x, marker.y) toView:self];
//    CGRect frame = CGRectMake(marker.x-width/2, marker.y-height-marker.button.frame.size.height, width, height);
    CGRect frame = CGRectMake(newPoint.x-width/2, newPoint.y-height-40, width, height);
    annotationView = [[UIView alloc]initWithFrame:frame];
    [annotationView.layer setBorderWidth:1];
    [annotationView.layer setBorderColor:[[UIColor blackColor] CGColor]];
    [annotationView.layer setCornerRadius:pad5];
    [annotationView addSubview:lblTitle];
    [annotationView addSubview:lblDescription];
    [annotationView setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:annotationView];

}
 */

-(void)showAnnotationForMarker:(MapMarker*)marker
{
    
}

-(UIImage*)scaleImage:(UIImage*)image forRect:(CGRect)rect
{
    UIGraphicsBeginImageContext( rect.size );
    [image drawInRect:CGRectMake(0,0,rect.size.width,rect.size.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)bundledImageNamed:(NSString*)name{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *imagePath = [bundle pathForResource:name ofType:@"png"];
    return [[UIImage alloc] initWithContentsOfFile:imagePath];
}

- (void)setIndex:(NSUInteger)index
{
    _index = index;
#if TILE_IMAGES
    [self displayTiledImageNamed:_ImageNameAtIndex(index) size:_ImageSizeAtIndex(index)];
#else
    [self displayImage:_ImageAtIndex(index)];
#endif
}

#pragma mark - selectors and delegate callbacks
-(void)markerClicked:(id)sender
{
    [annotationView removeFromSuperview];
    selectedMarker = nil;
    isMarker = NO;
    UIButton* btn = (UIButton*)sender;
    MapMarker* marker = [markers objectAtIndex:btn.tag];
    [self.mapDelegate onMarkerClicked:marker];
    [self showAnnotationForMarker:marker];
    
    CGPoint newPoint = [_tilingView convertPoint:CGPointMake(marker.x, marker.y) toView:self];
    [self setContentOffset:CGPointMake(newPoint.x-self.frame.size.width/2, newPoint.y-self.frame.size.height/2) animated:YES];
}

-(void)mapClicked:(id)sender
{
    [annotationView removeFromSuperview];
    selectedMarker = nil;
    UITapGestureRecognizer* recognizer = (UITapGestureRecognizer*)sender;
    CGPoint touchPoint = [recognizer locationInView: _tilingView];
    CGSize mapBounds = _tilingView.frame.size;
    if((touchPoint.x>=0)&&(touchPoint.x<=mapBounds.width)&&(touchPoint.y>=0)&&(touchPoint.y<=mapBounds.height)&&(!isMarker))
    {
        float y = touchPoint.y*(_tilingView.frame.size.height*4096)/(pow(2, _levels-1)*pow(2, _levels-1));
        float x = touchPoint.x*(_tilingView.frame.size.height*4096)/(pow(2, _levels-1)*pow(2, _levels-1));
        MKMapPoint point = MKMapPointMake(x, y);
        CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(point);
        MapPoint* mPoint = [[MapPoint alloc]init];
        mPoint.x = touchPoint.x;
        mPoint.y = touchPoint.x;
        mPoint.longitude = coordinate.longitude;
        mPoint.latitude = coordinate.latitude;
        
        if(self.mapDelegate != nil)
        {
            [self.mapDelegate onMapClicked:mPoint];
        }
    }
}

-(void)wasDragged:(UIPanGestureRecognizer *)recognizer
{
    UIButton *button = (UIButton *)recognizer.view;
    CGPoint translation = [recognizer translationInView:button];
    button.center = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:button];
    MapMarker* marker = [markers objectAtIndex:button.tag];
    CGPoint touchPoint = [recognizer locationInView: _tilingView];
    CGSize mapBounds = _tilingView.frame.size;
    if((touchPoint.x>=0)&&(touchPoint.x<=mapBounds.width)&&(touchPoint.y>=0)&&(touchPoint.y<=mapBounds.height)&&(!isMarker))
    {
        float y = touchPoint.y*(_tilingView.frame.size.height*4096)/(pow(2, _levels-1)*pow(2, _levels-1));
        float x = touchPoint.x*(_tilingView.frame.size.height*4096)/(pow(2, _levels-1)*pow(2, _levels-1));
        MKMapPoint point = MKMapPointMake(x, y);
        CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(point);
        MapPoint* mPoint = [[MapPoint alloc]init];
        mPoint.x = touchPoint.x;
        mPoint.y = touchPoint.x;
        mPoint.longitude = coordinate.longitude;
        mPoint.latitude = coordinate.latitude;
        if(self.mapDelegate != nil)
        {
            [self.mapDelegate onMapClicked:mPoint];
        }
    }
    else if(isMarker)
    {
        CGPoint btnLoc = [recognizer locationInView:button];
        float y = (touchPoint.y-btnLoc.y+button.frame.size.height)*(_tilingView.frame.size.height*4096)/(pow(2, _levels-1)*pow(2, _levels-1));
        float x = (touchPoint.x-btnLoc.x+button.frame.size.width/2)*(_tilingView.frame.size.height*4096)/(pow(2, _levels-1)*pow(2, _levels-1));
        MKMapPoint point = MKMapPointMake(x, y);
        CLLocationCoordinate2D coordinate = MKCoordinateForMapPoint(point);
        marker.x = touchPoint.x;
        marker.y = touchPoint.x;
        marker.longitude = coordinate.longitude;
        marker.latitude = coordinate.latitude;
    }
}

#pragma mark - layout behavours
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // center the zoom view as it becomes smaller than the size of the screen
    CGSize boundsSize = self.frame.size;
    CGRect frameToCenter = _zoomView.frame;
    
    // center horizontally
    if (frameToCenter.size.width < boundsSize.width)
        frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
    else
        frameToCenter.origin.x = 0;
    
    // center vertically
    if (frameToCenter.size.height < boundsSize.height)
        frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
    else
        frameToCenter.origin.y = 0;
    
    if(frameToCenter.size.width == 0)
    {
        frameToCenter.size.width = _tileSize.height;
    }
    if(frameToCenter.size.height == 0)
    {
        frameToCenter.size.height = _tileSize.width;
    }
    
    _zoomView.frame = frameToCenter;
    self.bounces = NO;
    [self setBouncesZoom:NO];
    
}

- (void)setFrame:(CGRect)frame
{
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
    }
}


- (void)prepareToResize
{
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:_zoomView];
    
    _scaleToRestoreAfterResize = self.zoomScale;
    
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON)
        _scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing
{
    [self setMaxMinZoomScalesForCurrentBounds];
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:_zoomView];
    
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}

- (CGPoint)maximumContentOffset
{
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.frame.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset
{
    return CGPointZero;
}

- (void)setMaxMinZoomScalesForCurrentBounds
{
    CGSize boundsSize = self.frame.size;
    
    // calculate min/max zoomscale
    CGFloat xScale = boundsSize.width  / _imageSize.width;
    CGFloat yScale = boundsSize.height / _imageSize.height;
    BOOL imagePortrait = _imageSize.height > _imageSize.width;
    BOOL phonePortrait = boundsSize.height > boundsSize.width;
    CGFloat minScale = imagePortrait == phonePortrait ? xScale : MIN(xScale, yScale);
    
    CGFloat maxScale = 1.0 / [[UIScreen mainScreen] scale];
    
    if (minScale > maxScale) {
        minScale = maxScale;
    }
    
    CGRect screenRect = [self frame];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    if(_maxZoom != 0)
    {
        maxScale = _maxZoom;
    }
    else
    {
        maxScale = _levels-1;
    }
    
    if(screenHeight > screenWidth)
    {
        minScale = screenWidth/_imageSize.width;
    }
    else
    {
        minScale = screenHeight/_imageSize.height;
    }

    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
}

-(UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGPoint newPoint = [self convertPoint:point toView:_tilingView];
    for (UIView *subview in _tilingView.subviews) {
        CGPoint subPoint = [subview convertPoint:newPoint fromView:_tilingView];
        UIView *result = [subview hitTest:subPoint withEvent:event];
        if (result != nil && [result isKindOfClass:[UIButton class]]) {
            isMarker = YES;
            return result;
        }
    }
    
    return [super hitTest:point withEvent:event];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _zoomView;
}

-(void)scrollViewDidZoom:(UIScrollView *)scrollView
{
//    [self setMarker:nil forLongitude:0 withLatitude:0];
    NSMutableArray* tempArray = markers.mutableCopy;
    [markers removeAllObjects];
    for(MapMarker* marker in tempArray)
    {
        [marker.button removeFromSuperview];
        MapMarker* res = [self createMarker:marker.button forLongitude:marker.longitude withLatitude:marker.latitude withImage:marker.image];
        [_tilingView addSubview:res.button];
        [self bringSubviewToFront:res.button];
        [markers addObject:res];
        
        if(selectedMarker!= nil && marker.button.tag == selectedMarker.button.tag)
        {
            selectedMarker = marker;
        }
    }
//    if(selectedMarker!=nil)
//    {
//        [self createAnnotationForMarker:selectedMarker];
//    }
}

#pragma mark - Configure scrollView to display new image (tiled or not)

#if TILE_IMAGES

- (void)displayTiledImageNamed:(NSString *)imageName size:(CGSize)imageSize
{
    // clear views for the previous image
    [_zoomView removeFromSuperview];
    _zoomView = nil;
    _tilingView = nil;
    
    // reset our zoomScale to 1.0 before doing any further calculations
    self.zoomScale = 1.0;
    
    // make views to display the new image
    _zoomView = [[UIImageView alloc] initWithFrame:(CGRect){ CGPointZero, imageSize }];
    [_zoomView setImage:_PlaceholderImageNamed(imageName)];
    [self addSubview:_zoomView];
    
    //mod
    [TilingView setMapURL:[NSString stringWithFormat:@"%@",_mapURL]];
    [TilingView setZoomLevel:_levels];
    [TilingView setTilesPerTile:_tilesPerTile];
    //mod end
    
    _tilingView = [[TilingView alloc] initWithImageName:imageName size:imageSize withZoom:_levels];
    _tilingView.frame = _zoomView.bounds;
    [_zoomView addSubview:_tilingView];
    
    [self configureForImageSize:imageSize];
}

#endif // TILE_IMAGES

- (void)configureForImageSize:(CGSize)imageSize
{
    _imageSize = imageSize;
    self.contentSize = imageSize;
    [self setMaxMinZoomScalesForCurrentBounds];
    [self setCurrentZoom:self.minimumZoomScale];
}

#pragma mark - static functions
static NSString *_ImageNameAtIndex(NSUInteger index)
{
    return @"Map";
}

static CGSize _ImageSizeAtIndex(NSUInteger index)
{
    CGSize size =  CGSizeMake(_tileSize.width*pow(2, _levels-1), _tileSize.height*pow(2,_levels-1));
    return size;
}

static UIImage *_PlaceholderImageNamed(NSString *name)
{
    NSString* surl = [NSString stringWithFormat:@"%@",_mapURL];
    NSString* url = [NSString stringWithFormat:@"%@/9/0/0",surl];
    UIImage* img = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    return img;
}
@end
