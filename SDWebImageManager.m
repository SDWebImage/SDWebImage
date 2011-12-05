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
        downloadDelegates = [[NSMutableArray alloc] init];
        downloaders = [[NSMutableArray alloc] init];
        cacheDelegates = [[NSMutableArray alloc] init];
        cacheURLs = [[NSMutableArray alloc] init];
        downloaderForURL = [[NSMutableDictionary alloc] init];
        failedURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [downloadDelegates release], downloadDelegates = nil;
    [downloaders release], downloaders = nil;
    [cacheDelegates release], cacheDelegates = nil;
    [cacheURLs release], cacheURLs = nil;
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

/**
 * @deprecated
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed
{
    [self downloadWithURL:url delegate:delegate options:(retryFailed ? SDWebImageRetryFailed : 0)];
}

/**
 * @deprecated
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority
{
    SDWebImageOptions options = 0;
    if (retryFailed) options |= SDWebImageRetryFailed;
    if (lowPriority) options |= SDWebImageLowPriority;
    [self downloadWithURL:url delegate:delegate options:options];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate
{
    [self downloadWithURL:url delegate:delegate options:0];
}

- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate options:(SDWebImageOptions)options
{
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }

    if (!url || !delegate || (!(options & SDWebImageRetryFailed) && [failedURLs containsObject:url]))
    {
        return;
    }

    // Check the on-disk cache async so we don't block the main thread
    [cacheDelegates addObject:delegate];
    [cacheURLs addObject:url];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:delegate, @"delegate", url, @"url", [NSNumber numberWithInt:options], @"options", nil];
    [[SDImageCache sharedImageCache] queryDiskCacheForKey:[url absoluteString] delegate:self userInfo:info];
}

- (void)cancelForDelegate:(id<SDWebImageManagerDelegate>)delegate
{
    NSUInteger idx;
    while ((idx = [cacheDelegates indexOfObjectIdenticalTo:delegate]) != NSNotFound)
    {
        [cacheDelegates removeObjectAtIndex:idx];
        [cacheURLs removeObjectAtIndex:idx];
    }

    while ((idx = [downloadDelegates indexOfObjectIdenticalTo:delegate]) != NSNotFound)
    {
        SDWebImageDownloader *downloader = [[downloaders objectAtIndex:idx] retain];

        [downloadDelegates removeObjectAtIndex:idx];
        [downloaders removeObjectAtIndex:idx];

        if (![downloaders containsObject:downloader])
        {
            // No more delegate are waiting for this download, cancel it
            [downloader cancel];
            [downloaderForURL removeObjectForKey:downloader.url];
        }

        [downloader release];
    }
}

#pragma mark SDImageCacheDelegate

- (NSUInteger)indexOfDelegate:(id<SDWebImageManagerDelegate>)delegate waitingForURL:(NSURL *)url
{
    // Do a linear search, simple (even if inefficient)
    NSUInteger idx;
    for (idx = 0; idx < [cacheDelegates count]; idx++)
    {
        if ([cacheDelegates objectAtIndex:idx] == delegate && [[cacheURLs objectAtIndex:idx] isEqual:url])
        {
            return idx;
        }
    }
    return NSNotFound;
}

- (void)imageCache:(SDImageCache *)imageCache didFindImage:(UIImage *)image forKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id<SDWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];

    NSUInteger idx = [self indexOfDelegate:delegate waitingForURL:url];
    if (idx == NSNotFound)
    {
        // Request has since been canceled
        return;
    }

    if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
    {
        [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
    }

    [cacheDelegates removeObjectAtIndex:idx];
    [cacheURLs removeObjectAtIndex:idx];
}

- (void)imageCache:(SDImageCache *)imageCache didNotFindImageForKey:(NSString *)key userInfo:(NSDictionary *)info
{
    NSURL *url = [info objectForKey:@"url"];
    id<SDWebImageManagerDelegate> delegate = [info objectForKey:@"delegate"];
    SDWebImageOptions options = [[info objectForKey:@"options"] intValue];

    NSUInteger idx = [self indexOfDelegate:delegate waitingForURL:url];
    if (idx == NSNotFound)
    {
        // Request has since been canceled
        return;
    }

    [cacheDelegates removeObjectAtIndex:idx];
    [cacheURLs removeObjectAtIndex:idx];

    // Share the same downloader for identical URLs so we don't download the same URL several times
    SDWebImageDownloader *downloader = [downloaderForURL objectForKey:url];

    if (!downloader)
    {
        downloader = [SDWebImageDownloader downloaderWithURL:url delegate:self userInfo:info lowPriority:(options & SDWebImageLowPriority)];
        [downloaderForURL setObject:downloader forKey:url];
    }
    else
    {
        // Reuse shared downloader
        downloader.userInfo = info;
        downloader.lowPriority = (options & SDWebImageLowPriority);
    }

    [downloadDelegates addObject:delegate];
    [downloaders addObject:downloader];
}

#pragma mark SDWebImageDownloaderDelegate

- (void)imageDownloader:(SDWebImageDownloader *)downloader didFinishWithImage:(UIImage *)image
{
    [downloader retain];
    SDWebImageOptions options = [[downloader.userInfo objectForKey:@"options"] intValue];

    // Notify all the downloadDelegates with this downloader
    for (NSInteger idx = (NSInteger)[downloaders count] - 1; idx >= 0; idx--)
    {
        NSUInteger uidx = (NSUInteger)idx;
        SDWebImageDownloader *aDownloader = [downloaders objectAtIndex:uidx];
        if (aDownloader == downloader)
        {
            id<SDWebImageManagerDelegate> delegate = [[[downloadDelegates objectAtIndex:uidx] retain] autorelease];

            if (image)
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFinishWithImage:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFinishWithImage:) withObject:self withObject:image];
                }
            }
            else
            {
                if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)])
                {
                    [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:nil];
                }
            }

            [downloaders removeObjectAtIndex:uidx];
            [downloadDelegates removeObjectAtIndex:uidx];
        }
    }

    if (image)
    {
        // Store the image in the cache
        [[SDImageCache sharedImageCache] storeImage:image
                                          imageData:downloader.imageData
                                             forKey:[downloader.url absoluteString]
                                             toDisk:!(options & SDWebImageCacheMemoryOnly)];
    }
    else if (!(options & SDWebImageRetryFailed))
    {
        // The image can't be downloaded from this URL, mark the URL as failed so we won't try and fail again and again
        // (do this only if SDWebImageRetryFailed isn't activated)
        [failedURLs addObject:downloader.url];
    }


    // Release the downloader
    [downloaderForURL removeObjectForKey:downloader.url];
    [downloader release];
}

- (void)imageDownloader:(SDWebImageDownloader *)downloader didFailWithError:(NSError *)error;
{
    [downloader retain];

    // Notify all the downloadDelegates with this downloader
    for (NSInteger idx = (NSInteger)[downloaders count] - 1; idx >= 0; idx--)
    {
        NSUInteger uidx = (NSUInteger)idx;
        SDWebImageDownloader *aDownloader = [downloaders objectAtIndex:uidx];
        if (aDownloader == downloader)
        {
            id<SDWebImageManagerDelegate> delegate = [[[downloadDelegates objectAtIndex:uidx] retain] autorelease];

            if ([delegate respondsToSelector:@selector(webImageManager:didFailWithError:)])
            {
                [delegate performSelector:@selector(webImageManager:didFailWithError:) withObject:self withObject:error];
            }

            [downloaders removeObjectAtIndex:uidx];
            [downloadDelegates removeObjectAtIndex:uidx];
        }
    }

    // Release the downloader
    [downloaderForURL removeObjectForKey:downloader.url];
    [downloader release];
}

@end
