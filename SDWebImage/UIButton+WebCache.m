/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+WebCache.h"
#import "SDWebImageManager.h"

@implementation UIButton (WebCache)

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
    [self setImageWithURL:url
         placeholderImage:placeholder
                  options:options
                 forState:UIControlStateNormal];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options forState:(UIControlState)state
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    [self setImage:placeholder forState:state];
    
    
    if (url)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:state] forKey:@"state"];
        [manager downloadWithURL:url delegate:self options:options userInfo:userInfo];
    }
}

#if NS_BLOCKS_AVAILABLE
- (void)setImageWithURL:(NSURL *)url success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setImageWithURL:url placeholderImage:nil success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setImageWithURL:url placeholderImage:placeholder options:0 success:success failure:failure];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setImageWithURL:url
         placeholderImage:placeholder
                  options:options
                  success:success
                  failure:failure
                 forState:UIControlStateNormal];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure forState:(UIControlState)state;
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    [self setImage:placeholder forState:state];
    
    if (url)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:state] forKey:@"state"];
        [manager downloadWithURL:url delegate:self options:options userInfo:userInfo success:success failure:failure];
    }
}
#endif

- (void)setBackgroundImageWithURL:(NSURL *)url
{
    [self setBackgroundImageWithURL:url placeholderImage:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self setBackgroundImageWithURL:url placeholderImage:placeholder options:0];
}

- (void)setBackgroundImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    [self setBackgroundImageWithURL:url
                   placeholderImage:placeholder
                            options:options
                           forState:UIControlStateNormal];
}

- (void)setBackgroundImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options forState:(UIControlState)state
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    [self setBackgroundImage:placeholder forState:state];
    
    if (url)
    {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"background", @"type",
                              [NSNumber numberWithInt:state], @"state",
                              nil];
        [manager downloadWithURL:url delegate:self options:options userInfo:info];
    }
}

#if NS_BLOCKS_AVAILABLE
- (void)setBackgroundImageWithURL:(NSURL *)url success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setBackgroundImageWithURL:url placeholderImage:nil success:success failure:failure];
}

- (void)setBackgroundImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setBackgroundImageWithURL:url placeholderImage:placeholder options:0 success:success failure:failure];
}

- (void)setBackgroundImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure;
{
    [self setBackgroundImageWithURL:url
                   placeholderImage:placeholder
                            options:options
                            success:success
                            failure:failure
                           forState:UIControlStateNormal];
}

- (void)setBackgroundImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options success:(SDWebImageSuccessBlock)success failure:(SDWebImageFailureBlock)failure forState:(UIControlState)state;
{
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    
    // Remove in progress downloader from queue
    [manager cancelForDelegate:self];
    
    [self setBackgroundImage:placeholder forState:state];
    
    if (url)
    {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"background", @"type",
                              [NSNumber numberWithInt:state], @"state",
                              nil];
        [manager downloadWithURL:url delegate:self options:options userInfo:info success:success failure:failure];
    }
}
#endif


- (void)cancelCurrentImageLoad
{
    @synchronized(self)
    {
        [[SDWebImageManager sharedManager] cancelForDelegate:self];
    }
}

- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info
{
    UIControlState state = [[info objectForKey:@"state"] intValue];
    
    if ([[info valueForKey:@"type"] isEqualToString:@"background"])
    {
        [self setBackgroundImage:image forState:state];
    }
    else
    {
        [self setImage:image forState:state];
    }
}


- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info
{
    UIControlState state = [[info objectForKey:@"state"] intValue];
    
    if ([[info valueForKey:@"type"] isEqualToString:@"background"])
    {
        [self setBackgroundImage:image forState:state];
    }
    else
    {
        [self setImage:image forState:state];
    }
}

@end
