/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "DetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/FLAnimatedImageView+WebCache.h>

@interface DetailViewController ()

@property (strong, nonatomic) IBOutlet FLAnimatedImageView *imageView;

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
    if (self.imageURL) {
        __block UIActivityIndicatorView *activityIndicator;
        __weak UIImageView *weakImageView = self.imageView;
        [self.imageView sd_setImageWithURL:self.imageURL
                          placeholderImage:nil
                                   options:SDWebImageProgressiveDownload
                                  progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *targetURL) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          if (!activityIndicator) {
                                              [weakImageView addSubview:activityIndicator = [UIActivityIndicatorView.alloc initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray]];
                                              activityIndicator.center = weakImageView.center;
                                              [activityIndicator startAnimating];
                                          }
                                      });
                                  }
                                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
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
