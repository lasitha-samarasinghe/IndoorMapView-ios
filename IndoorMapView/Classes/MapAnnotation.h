//
//  MapAnnotation.h
//  Pods
//
//  Created by Lasitha Samarasinghe on 5/23/16.
//
//

#import <Foundation/Foundation.h>
#import "MapMarker.h"

@interface MapAnnotation : NSObject

@property int id;
@property MapMarker* marker;
@property NSString* title;
@property NSString* descriptionText;
@property UIView* view;

@end
