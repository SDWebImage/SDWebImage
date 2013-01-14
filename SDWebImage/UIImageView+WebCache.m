/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"

@interface UIImageView (WebCachePrivate)

-(NSURL *) retinaURL:(NSURL *) url;
-(BOOL) isRetina;
@end

@implementation UIImageView (WebCache)


+(BOOL) isRetina{
    return ([UIScreen mainScreen].scale == 2.0f);
}

+(NSURL *) retinaURL:(NSURL *) url{
    if ([UIImageView isRetina]) {
        NSString * lastComponent = [url lastPathComponent];
        
        NSString *extension = [url pathExtension];
        if ([lastComponent rangeOfString:@"_2x"].location == NSNotFound) {
            NSString * replacedLastComponent = [lastComponent stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@",extension] withString:[NSString stringWithFormat:@"_2x.%@",extension]];
            url = [NSURL URLWithString:[[[url absoluteString] stringByReplacingOccurrencesOfString:lastComponent withString:replacedLastComponent] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
            //[url urlen]
        }
    }
    
    return url;
}

-(BOOL) isRetina{
    return [UIImageView isRetina];
}

-(NSURL *) retinaURL:(NSURL *)url{
    return [UIImageView retinaURL:url];
}

- (void)setImageWithURL:(NSURL *)url
{
    
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setOptimizedImageWithURL:(NSURL *)url
{
    url = [self retinaURL:url];
    [self setImageWithURL:url placeholderImage:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self setImageWithURL:url placeholderImage:placeholder options:0];
}

- (void)setOptimizedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    url = [self retinaURL:url];
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
- (void)setOptimizedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    self.image = placeholder;

    if (url)
    {
        url = [self retinaURL:url];
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
- (void)setOptimizedImageWithURL:(NSURL *)url success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
{
    [self setOptimizedImageWithURL:url placeholderImage:nil success:success failure:failure];
}

- (void)setOptimizedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
{
    [self setOptimizedImageWithURL:url placeholderImage:placeholder options:0 success:success failure:failure];
}

- (void)setOptimizedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    self.image = placeholder;
    
    if (url)
    {
        if ([UIImageView isRetina]) {
            url = [UIImageView retinaURL:url];

        }
        [manager downloadWithURL:url delegate:self options:options success:success failure:failure];
    }
}
#endif

- (void)cancelCurrentImageLoad
{
    [[SDWebImageManager sharedManager] cancelForDelegate:self];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url
{
    self.image = image;
    [self setNeedsLayout];
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
    self.image = image;
    [self setNeedsLayout];
}

@end
