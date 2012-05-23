/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"

@interface UIImageView (Private)

-(void) removeActivityIndicator;

@end

@implementation UIImageView (WebCache)

-(void) removeActivityIndicator {
  
  UIActivityIndicatorView *ai = (UIActivityIndicatorView *)[self viewWithTag:TAG_ACTIVITY_INDICATOR];
  
  if (ai) {
    [ai removeFromSuperview];
  }
}

-(void) setImageWithURL:(NSURL *)url usingActivityIndicatorStyle : (UIActivityIndicatorViewStyle) activityStyle
{
  
  UIActivityIndicatorView *ai = (UIActivityIndicatorView *)[self viewWithTag:TAG_ACTIVITY_INDICATOR];
  if (ai == nil) {
    ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:activityStyle];
    ai.center = self.center;
    ai.hidesWhenStopped = YES;
    ai.tag = TAG_ACTIVITY_INDICATOR;
    [self addSubview:ai];
  }
  
  [ai startAnimating];
  [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self setImageWithURL:url placeholderImage:placeholder options:0];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];

    self.image = placeholder;

    if (url)
    {
        [manager downloadWithURL:url delegate:self options:options];
    }
}

#if NS_BLOCKS_AVAILABLE
- (void)setImageWithURL:(NSURL *)url success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
{
    [self setImageWithURL:url placeholderImage:nil success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];

    self.image = placeholder;

    if (url)
    {
        [manager downloadWithURL:url delegate:self options:options success:success failure:failure];
    }
}
#endif

- (void)cancelCurrentImageLoad
{
  [self removeActivityIndicator];
    [[SDWebImageManager sharedManager] cancelForDelegate:self];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
  [self removeActivityIndicator];
    self.image = image;
}

@end
