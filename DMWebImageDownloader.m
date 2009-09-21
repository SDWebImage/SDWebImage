/*
 * This file is part of the DMWebImage package.
 * (c) Dailymotion - Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "DMWebImageDownloader.h"
#import "DMImageCache.h"

static NSOperationQueue *queue;

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

    if (queue == nil)
    {
        queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 8;
    }

    [queue addOperation:downloader];
    
    return downloader;
}

+ (void)setMaxConcurrentDownloads:(NSUInteger)max
{
    if (queue == nil)
    {
        queue = [[NSOperationQueue alloc] init];
    }

    queue.maxConcurrentOperationCount = max;
}

- (void)main 
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
    
    if (!self.isCancelled)
    {
        [target performSelector:action withObject:image];
    }

    [[DMImageCache sharedImageCache] storeImage:image forKey:[url absoluteString]];

    [pool release];
}

@end
