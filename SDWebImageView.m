/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import "SDWebImageView.h"
#import "SDImageCache.h"
#import "SDWebImageDownloader.h"

@implementation SDWebImageView

- (void)dealloc
{
    [placeHolderImage release];
    [downloader release];
    [super dealloc];
}

#pragma mark RemoteImageView

- (void)setImageWithURL:(NSURL *)url
{
    if (downloader != nil)
    {
        // Remove in progress downloader from queue
        [downloader cancel];
        [downloader release];
        downloader = nil;
    }

    // Save the placeholder image in order to re-apply it when view is reused
    if (placeHolderImage == nil)
    {
        placeHolderImage = [self.image retain];
    }
    else
    {
        self.image = placeHolderImage;
    }

    UIImage *cachedImage = [[SDImageCache sharedImageCache] imageFromKey:[url absoluteString]];

    if (cachedImage)
    {
        self.image = cachedImage;
    }
    else
    {        
        downloader = [[SDWebImageDownloader downloaderWithURL:url target:self action:@selector(downloadFinishedWithImage:)] retain];
    }
}

- (void)downloadFinishedWithImage:(UIImage *)anImage
{
    // Apply image to the underlaying UIImageView
    self.image = anImage;

    // Store the image in the cache
    [[SDImageCache sharedImageCache] storeImage:anImage forKey:[downloader.url absoluteString]];

    // Free the downloader
    [downloader release];
    downloader = nil;
}

@end
