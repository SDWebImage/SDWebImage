//
//  SDViewController.h
//  DemoUniversal
//
//  Created by Eli Wang on 4/17/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface SDViewController : UIViewController
{
    id target;
}

@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (retain, nonatomic) IBOutlet UIButton *imageButton;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property (retain, nonatomic) IBOutlet UITextField *urlField;

- (IBAction)loadButtonTouched:(id)sender;
- (IBAction)segValueChanged:(id)sender;

@end
