//
//  MapView.h
//  Pods
//
//  Created by Lasitha Samarasinghe on 5/12/16.
//
//

#import <UIKit/UIKit.h>
#import "MapPoint.h"
#import "MapMarker.h"
#import "TilingView.h"

@protocol IndoorMapDelegate <NSObject>
@optional
- (void) onMarkerClicked:(MapMarker*)marker;
- (void) onMapClicked:(MapPoint*)point;
@end

@interface MapView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic) NSUInteger index;
@property (nonatomic, weak) id <IndoorMapDelegate> mapDelegate;

-(void)setupWithURL:(NSURL*)url forView:(UIView*)view withLevels:(float)levels withTileSize:(CGSize)size;
-(void)setCurrentZoom:(CGFloat)zoom;
-(void)setMaximumZoom:(CGFloat)zoom;
-(void)setMarkerWithId:(int)mid forLongitude:(float)longitude withLatitude:(float)latitude withImage:(UIImage*)image;

@end
