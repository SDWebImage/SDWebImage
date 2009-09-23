/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"

static NSOperationQueue *downloadQueue;

@implementation SDWebImageDownloader

@synthesize url, delegate;

- (void)dealloc
{
    [url release];
    [super dealloc];
}

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate
{
    SDWebImageDownloader *downloader = [[[SDWebImageDownloader alloc] init] autorelease];
    downloader.url = url;
    downloader.delegate = delegate;

    if (downloadQueue == nil)
    {
        downloadQueue = [[NSOperationQueue alloc] init];
        downloadQueue.maxConcurrentOperationCount = 8;
    }

    [downloadQueue addOperation:downloader];
    
    return downloader;
}

+ (void)setMaxConcurrentDownloads:(NSUInteger)max
{
    if (downloadQueue == nil)
    {
        downloadQueue = [[NSOperationQueue alloc] init];
    }

    downloadQueue.maxConcurrentOperationCount = max;
}

- (void)main 
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    if (!self.isCancelled && [delegate respondsToSelector:@selector(imageDownloader:didFinishWithImage:)])
    {
        [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
    }

    [pool release];
}

@end
