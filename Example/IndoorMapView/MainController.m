//
//  MainController.m
//  IndoorMapView
//
//  Created by Lasitha Samarasinghe on 5/20/16.
//  Copyright © 2016 Lasitha Samarasinghe. All rights reserved.
//

#import "MainController.h"
#import "AztViewController.h"
@interface MainController ()

@end

@implementation MainController
{
    AztViewController* vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.stpLevel.value = 2;
    self.lblLevel.text = @"Level: 2";
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"map"])
    {
        vc = segue.destinationViewController;
    }
}

- (IBAction)levelChange:(id)sender {
    UIStepper* stepper = (UIStepper*)sender;
    if(stepper.value >= 2)
    {
        [vc setMap:stepper.value];
    }
    else
    {
        stepper.value = 2;
    }
    self.lblLevel.text = [NSString stringWithFormat:@"Level: %d",(int)stepper.value];
}

- (IBAction)enableMarker:(id)sender {
    UISegmentedControl* segment = (UISegmentedControl*)sender;
    if (segment.selectedSegmentIndex == 0) {
        [vc enableOnTapMarker:YES];
    }
    else
    {
        [vc enableOnTapMarker:NO];
    }
}

@end
