/*
 * This file is part of the DMWebImage package.
 * (c) Dailymotion - Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "DMWebImageDownloader.h"

static NSOperationQueue *downloadQueue;

@implementation DMWebImageDownloader

@synthesize url, target, action;

- (void)dealloc
{
    [url release];
    [super dealloc];
}

+ (id)downloaderWithURL:(NSURL *)url target:(id)target action:(SEL)action
{
    DMWebImageDownloader *downloader = [[[DMWebImageDownloader alloc] init] autorelease];
    downloader.url = url;
    downloader.target = target;
    downloader.action = action;

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
    
    if (!self.isCancelled)
    {
        [target performSelector:action withObject:image];
    }

    [pool release];
}

@end
