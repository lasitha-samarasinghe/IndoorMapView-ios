//
//  MainController.h
//  IndoorMapView
//
//  Created by Lasitha Samarasinghe on 5/20/16.
//  Copyright © 2016 Lasitha Samarasinghe. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *lblLevel;
@property (weak, nonatomic) IBOutlet UIStepper *stpLevel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segMarker;

@end
