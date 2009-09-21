/*
 * This file is part of the DMWebImage package.
 * (c) Dailymotion - Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import "DMWebImageView.h"
#import "DMImageCache.h"
#import "DMWebImageDownloader.h"

@implementation DMWebImageView

- (void)dealloc
{
    [placeHolderImage release];
    [currentOperation release];
    [super dealloc];
}

#pragma mark RemoteImageView

- (void)setImageWithURL:(NSURL *)url
{
    if (currentOperation != nil)
    {
        [currentOperation cancel]; // remove from queue
        [currentOperation release];
        currentOperation = nil;
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

    UIImage *cachedImage = [[DMImageCache sharedImageCache] imageFromKey:[url absoluteString]];

    if (cachedImage)
    {
        self.image = cachedImage;
    }
    else
    {        
        currentOperation = [[DMWebImageDownloader downloaderWithURL:url target:self action:@selector(downloadFinishedWithImage:)] retain];
    }
}

- (void)downloadFinishedWithImage:(UIImage *)anImage
{
    self.image = anImage;
    [currentOperation release];
    currentOperation = nil;
}

@end
