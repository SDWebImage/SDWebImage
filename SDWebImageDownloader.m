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

@synthesize url, target, action;

- (void)dealloc
{
    [url release];
    [super dealloc];
}

+ (id)downloaderWithURL:(NSURL *)url target:(id)target action:(SEL)action
{
    SDWebImageDownloader *downloader = [[[SDWebImageDownloader alloc] init] autorelease];
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
