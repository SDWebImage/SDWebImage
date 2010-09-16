/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import "SDImageCache.h"
#import "SDWebImageDownloader.h"

static SDWebImageManager *instance;

@implementation SDWebImageManager

- (id)init
{
    if ((self = [super init]))
    {
        delegates = [[NSMutableArray alloc] init];
        downloaders = [[NSMutableArray alloc] init];
        downloaderForURL = [[NSMutableDictionary alloc] init];
        failedURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [delegates release], delegates = nil;
    [downloaders release], downloaders = nil;
    [downloaderForURL release], downloaderForURL = nil;
    [failedURLs release], failedURLs = nil;
    [super dealloc];
}


+ (id)sharedManager
{
    if (instance == nil)
    {
        instance = [[SDWebImageManager alloc] init];
    }

    return instance;
}

/**
 * @deprecated
 */
- (UIImage *)imageWithURL:(NSURL *)url
{
    return [[SDImageCache sharedImageCache] imageFromKey:[url absoluteString]];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate
{
    if (!url || !delegate || [failedURLs containsObject:url])
    {
        return;
    }

    // Check the on-disk cache async so we don't block the main thread
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:delegate, @"delegate", url, @"url", nil];
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:[url absoluteString] delegate:self userInfo:info];
}

- (void)cancelForDelegate:(id<SDWebImageManagerDelegate>)delegate
{
    NSUInteger idx = [delegates indexOfObjectIdenticalTo:delegate];

    if (idx == NSNotFound)
    {
        return;
    }

    SDWebImageDownloader *downloader = [[downloaders objectAtIndex:idx] retain];

    [delegates removeObjectAtIndex:idx];
    [downloaders removeObjectAtIndex:idx];

    if (![downloaders containsObject:downloader])
    {
        // No more delegate are waiting for this download, cancel it
        [downloader cancel];
        [downloaderForURL removeObjectForKey:downloader.url];
    }

    [downloader release];
}

#pragma mark SDImageCacheDelegate

- (void)imageCache:(SDImageCache *)imageCache didFindImage:(UIImage *)image forKey:(NSString *)key userInfo:(NSDictionary *)info
{
    id<SDWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];
    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
    {
        [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
    }
}

- (void)imageCache:(SDImageCache *)imageCache didNotFindImageForKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id<SDWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];

    // Share the same downloader for identical URLs so we don't download the same URL several times
    SDWebImageDownloader *downloader = [downloaderForURL objectForKey:url];

    if (!downloader)
    {
        downloader = [SDWebImageDownloader downloaderWithURL:url delegate:self];
        [downloaderForURL setObject:downloader forKey:url];
    }

    [delegates addObject:delegate];
    [downloaders addObject:downloader];
}

#pragma mark SDWebImageDownloaderDelegate

- (void)imageDownloader:(SDWebImageDownloader *)downloader didFinishWithImage:(UIImage *)image
{
    [downloader retain];

    // Notify all the delegates with this downloader
    for (NSInteger idx = [downloaders count] - 1; idx >= 0; idx--)
    {
        SDWebImageDownloader *aDownloader = [downloaders objectAtIndex:idx];
        if (aDownloader == downloader)
        {
            id<SDWebImageManagerDelegate> delegate = [delegates objectAtIndex:idx];

            if (image && [delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
            {
                [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
            }

            [downloaders removeObjectAtIndex:idx];
            [delegates removeObjectAtIndex:idx];
        }
    }

    if (image)
    {
        // Store the image in the cache
        [[SDImageCache sharedImageCache] storeImage:image
                                          imageData:downloader.imageData
                                             forKey:[downloader.url absoluteString]
                                             toDisk:YES];
    }
    else
    {
        // The image can't be downloaded from this URL, mark the URL as failed so we won't try and fail again and again
        [failedURLs addObject:downloader.url];
    }


    // Release the downloader
    [downloaderForURL removeObjectForKey:downloader.url];
    [downloader release];
}


@end
