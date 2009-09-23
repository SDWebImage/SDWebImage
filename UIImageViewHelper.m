/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import "UIImageViewHelper.h"
#import "SDImageCache.h"

@implementation UIImageViewHelper

@synthesize placeHolderImage;

- (id)initWithDelegate:(UIImageView *)aDelegate
{
    if (self = [super init])
    {
        delegate = aDelegate;
        self.hidden = YES;
    }
    return self;
}

- (UIImage *)imageWithURL:(NSURL *)url
{
    return [[SDImageCache sharedImageCache] imageFromKey:[url absoluteString]];
}

- (void)downloadWithURL:(NSURL *)url
{
    downloader = [[SDWebImageDownloader downloaderWithURL:url target:self action:@selector(downloadFinishedWithImage:)] retain];
}

- (void)cancel
{
    [downloader cancel];
    [downloader release];
    downloader = nil;
}

- (void)downloadFinishedWithImage:(UIImage *)anImage
{
    // Apply image to the underlaying UIImageView
    delegate.image = anImage;
    
    // Store the image in the cache
    [[SDImageCache sharedImageCache] storeImage:anImage forKey:[downloader.url absoluteString]];
    
    // Free the downloader
    [downloader release];
    downloader = nil;
}

@end