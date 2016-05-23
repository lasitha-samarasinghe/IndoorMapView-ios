//
//  TilingView.h
//  Pods
//
//  Created by Lasitha Samarasinghe on 5/12/16.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/CATiledLayer.h>

@interface TilingView : UIView

- (id)initWithImageName:(NSString *)name size:(CGSize)size withZoom:(CGFloat)zoom;
- (UIImage *)tileForScale:(CGFloat)scale row:(int)row col:(int)col;

+ (void) setMapURL:(NSString*)url;
+(void)setZoomLevel:(CGFloat)levels;
+(void)setTilesPerTile:(int)tiles;
@end
