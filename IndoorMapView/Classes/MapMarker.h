//
//  MapMarker.h
//  Pods
//
//  Created by Lasitha Samarasinghe on 5/12/16.
//
//

#import <UIKit/UIKit.h>

@interface MapMarker : NSObject

@property int id;
@property float longitude;
@property float latitude;
@property int x;
@property int y;
@property UIView* view;
@property UIButton* button;

@end
