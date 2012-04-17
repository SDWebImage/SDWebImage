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
@synthesize urlField;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setUrlField:nil];
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
    [imageView setImageWithURL:[NSURL URLWithString:urlField.text]];
}


- (void)dealloc
{
    [imageView release];
    [urlField release];
    [super dealloc];
}

@end
