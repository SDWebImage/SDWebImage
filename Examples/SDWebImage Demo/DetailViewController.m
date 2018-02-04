/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "DetailViewController.h"
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/FLAnimatedImageView+WebCache.h>

@interface DetailViewController ()

@property (strong, nonatomic) IBOutlet FLAnimatedImageView *imageView;

@end

@implementation DetailViewController

- (void)configureView
{
    if (!self.imageView.sd_imageIndicator) {
        self.imageView.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    }
    [self.imageView sd_setImageWithURL:self.imageURL
                      placeholderImage:nil
                               options:SDWebImageProgressiveDownload];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
