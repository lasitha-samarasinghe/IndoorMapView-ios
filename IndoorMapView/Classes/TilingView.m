//
//  TilingView.m
//  Pods
//
//  Created by Lasitha Samarasinghe on 5/12/16.
//
//

#import "TilingView.h"

static NSString* mapURL;
static float zoomLevel;
static int tileCount;
static  TilingView* tileView;

@implementation TilingView
{
    NSString *_imageName;
}

#pragma static functions
+ (void) setMapURL:(NSString*)url {
    mapURL = url;
}

+ (Class)layerClass
{
    return [CATiledLayer class];
}

+(void)setZoomLevel:(CGFloat)levels
{
    zoomLevel = levels;
}

+(void)setTilesPerTile:(int)tiles;
{
    tileCount = tiles;
}

#pragma mark - init
- (id)initWithImageName:(NSString *)name size:(CGSize)size withZoom:(CGFloat)zoom
{
    self = [super initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    if (self) {
        zoomLevel = zoom;
        _imageName = name;
        CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        tiledLayer.levelsOfDetail = zoom;
    }
    return self;
}

- (void)setContentScaleFactor:(CGFloat)contentScaleFactor
{
    [super setContentScaleFactor:1];
}

-(void)addSubview:(UIView *)view
{
    [super addSubview:view];
    [self bringSubviewToFront:view];
}


#pragma mark - private functions
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat scale = CGContextGetCTM(context).a;
    CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
    CGSize tileSize = tiledLayer.tileSize;
    
    tileSize.width /= scale;
    tileSize.height /= scale;
    
    int firstCol = floorf(CGRectGetMinX(rect) / tileSize.width);
    int lastCol = floorf((CGRectGetMaxX(rect)-1) / tileSize.width);
    int firstRow = floorf(CGRectGetMinY(rect) / tileSize.height);
    int lastRow = floorf((CGRectGetMaxY(rect)-1) / tileSize.height);
    
    for (int row = firstRow; row <= lastRow; row++) {
        for (int col = firstCol; col <= lastCol; col++) {
            UIImage *tile = [self tileForScale:scale row:row col:col];
            CGRect tileRect = CGRectMake(tileSize.width * col, tileSize.height * row,
                                         tileSize.width, tileSize.height);
            
            tileRect = CGRectIntersection(self.bounds, tileRect);
            
            [tile drawInRect:tileRect];
        }
    }
}


- (UIImage *)tileForScale:(CGFloat)scale row:(int)row col:(int)col
{
    UIImage* image;
    int power = 0;
    int count = 0;
    if(scale != 1)
    {
        int magnification = 1/scale;
        while(power == 0)
        {
            int pw = pow(2, count);
            if(pw==magnification)
            {
                power = count;
                break;
            }
            count++;
        }
    }
    NSString* url =[NSString stringWithFormat:@"%@/%d/%d/%d",mapURL, (int)(zoomLevel-1-power),col,row];
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    
    return image;
}
@end
