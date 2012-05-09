//
//  SDViewController.m
//  DemoUniversal
//
//  Created by Eli Wang on 4/17/12.
//  Copyright (c) 2012 ekohe.com. All rights reserved.
//

#import "SDViewController.h"
#import "UIImageView+WebCache.h"


@interface SDViewController ()

@end

@implementation SDViewController
@synthesize imageView;
@synthesize imageButton;
@synthesize mapView;
@synthesize urlField;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    target = imageView;
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setUrlField:nil];
    [self setMapView:nil];
    [self setImageButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (IBAction)loadButtonTouched:(id)sender
{
    if ([target isKindOfClass:[MKMapView class]]) {
    } else {
        [target setImageWithURL:[NSURL URLWithString:urlField.text]];
    }
}

- (IBAction)segValueChanged:(UISegmentedControl *)sender
{
    imageView.hidden = YES;
    mapView.hidden = YES;
    imageButton.hidden = YES;
    
    switch (sender.selectedSegmentIndex) {
        case 0:
            target = imageView;
            imageView.image = nil;
            break;
        case 1:
            target = imageButton;
            [imageButton setImage:nil forState:UIControlStateNormal];
            break;
        case 2:
            target = mapView;
            break;
        default:
            break;
    }
    
    [target setHidden:NO];
}


- (void)dealloc
{
    [imageView release];
    [urlField release];
    [mapView release];
    [imageButton release];
    [super dealloc];
}

@end
