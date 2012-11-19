//
//  DetailViewController.m
//  SDWebImage Demo
//
//  Created by Olivier Poitrey on 09/05/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "DetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize imageURL = _imageURL;
@synthesize imageView = _imageView;

#pragma mark - Managing the detail item

- (void)setImageURL:(NSURL *)imageURL
{
    if (_imageURL != imageURL)
    {
        _imageURL = imageURL;
        [self configureView];
    }
}

- (void)configureView
{
    if (self.imageURL)
    {
        __block UIActivityIndicatorView *activityIndicator;
        [self.imageView setImageWithURL:self.imageURL placeholderImage:nil options:SDWebImageProgressiveDownload progress:^(NSUInteger receivedSize, long long expectedSize)
        {
            if (!activityIndicator)
            {
                [self.imageView addSubview:activityIndicator = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
                activityIndicator.center = self.imageView.center;
                [activityIndicator startAnimating];
            }
        }
        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType)
        {
            [activityIndicator removeFromSuperview];
            activityIndicator = nil;
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.imageView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
