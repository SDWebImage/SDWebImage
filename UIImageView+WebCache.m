/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"
#import "SDWebImageManager.h"

@implementation UIImageView (WebCache)

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];

    self.image = placeholder;
    
    self.alpha = 0.5;
    UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView*)[self viewWithTag:1001];
    if (activityIndicator == nil) {
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activityIndicator.tag = 1001;
        activityIndicator.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [self addSubview:activityIndicator];
        [activityIndicator startAnimating];
        [activityIndicator release];
    }
    else {
        [activityIndicator startAnimating];    
    }
    
    if (url)
    {
        [manager downloadWithURL:url delegate:self];
    }
}

- (void)cancelCurrentImageLoad
{
    [[SDWebImageManager sharedManager] cancelForDelegate:self];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
 
    [[self viewWithTag:1001] removeFromSuperview];
    
    self.alpha = 1.0;
    self.image = image;
}

-(void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error 
{
    
    [[self viewWithTag:1001] removeFromSuperview];
    
    self.alpha = 1.0;
    
}

@end
