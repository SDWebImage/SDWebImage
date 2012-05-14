/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImagePrefetcher.h"
#import "SDWebImageManager.h"

@interface SDWebImagePrefetcher ()
@property (nonatomic, retain) NSArray *prefetchURLs;
@end

@implementation SDWebImagePrefetcher

static SDWebImagePrefetcher *instance;

@synthesize prefetchURLs;
@synthesize maxConcurrentDownloads;
@synthesize options;

+ (SDWebImagePrefetcher *)sharedImagePrefetcher
{
    if (instance == nil)
    {
        instance = [[SDWebImagePrefetcher alloc] init];
        instance.maxConcurrentDownloads = 3;
        instance.options = (SDWebImageLowPriority);
    }

    return instance;
}

- (void)startPrefetchingAtIndex:(NSUInteger)index withManager:(SDWebImageManager *)imageManager
{
    if (index >= [self.prefetchURLs count]) return;
    _requestedCount++;
    [imageManager downloadWithURL:[self.prefetchURLs objectAtIndex:index] delegate:self options:self.options];
}

- (void)reportStatus
{
    NSUInteger total = [self.prefetchURLs count];
    NSLog(@"Finished prefetching (%d successful, %d skipped, timeElasped %.2f)", total - _skippedCount, _skippedCount, CFAbsoluteTimeGetCurrent() - _startedTime);
}

- (void)prefetchURLs:(NSArray *)urls
{
    [self cancelPrefetching]; // Prevent duplicate prefetch request
    _startedTime = CFAbsoluteTimeGetCurrent();
    self.prefetchURLs = urls;

    // Starts prefetching from the very first image on the list with the max allowed concurrency
    NSUInteger listCount = [self.prefetchURLs count];
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    for (NSUInteger i = 0; i < self.maxConcurrentDownloads && _requestedCount < listCount; i++)
    {
        [self startPrefetchingAtIndex:i withManager:manager];
    }
}

- (void)cancelPrefetching
{
    self.prefetchURLs = nil;
    _skippedCount = 0;
    _requestedCount = 0;
    _finishedCount = 0;
    [[SDWebImageManager sharedManager] cancelForDelegate:self];
}

#pragma mark SDWebImagePrefetcher (SDWebImageManagerDelegate)

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
{
    _finishedCount++;
    NSLog(@"Prefetched %d out of %d", _finishedCount, [self.prefetchURLs count]);

    if ([self.prefetchURLs count] > _requestedCount)
    {
        [self startPrefetchingAtIndex:_requestedCount withManager:imageManager];
    }
    else if (_finishedCount == _requestedCount)
    {
        [self reportStatus];
    }
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error
{
    _finishedCount++;
    NSLog(@"Prefetched %d out of %d (Failed)", _finishedCount, [self.prefetchURLs count]);

    // Add last failed
    _skippedCount++;

    if ([self.prefetchURLs count] > _requestedCount)
    {
        [self startPrefetchingAtIndex:_requestedCount withManager:imageManager];
    }
    else if (_finishedCount == _requestedCount)
    {
        [self reportStatus];
    }
}

- (void)dealloc
{
    self.prefetchURLs = nil;
    SDWISuperDealoc;
}

@end
