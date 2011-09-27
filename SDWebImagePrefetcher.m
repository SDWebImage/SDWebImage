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
@property (nonatomic, retain) NSArray *prefetchList;    // Array of URLs
@end

@implementation SDWebImagePrefetcher

static SDWebImagePrefetcher *instance;

@synthesize prefetchList;
@synthesize maxConcurrentDownloads;

- (void)startPrefetchingAtIndex:(NSUInteger)index withManager:(SDWebImageManager *)imageManager {
    if (index >= [self.prefetchList count]) {
        return;
    }
    _requestedCount++;
    NSURL *url = [self.prefetchList objectAtIndex:index];
    [imageManager downloadWithURL:url delegate:self retryFailed:NO lowPriority:YES];
}

- (void)reportStatus {
    NSUInteger total = [self.prefetchList count];
    NSLog(@"Finished prefetching (%d successful, %d skipped, timeElasped %.2f)", total - _skippedCount, _skippedCount, CFAbsoluteTimeGetCurrent() - _startedTime);
}

- (void)startPrefetchingWithList:(NSArray *)list {
    [self cancelPrefetching];   // Prevent duplicate prefetch request
    _startedTime = CFAbsoluteTimeGetCurrent();
    self.prefetchList = list;

    // Starts from the very first image on the list
    int listCount = [self.prefetchList count];
    for (int i = 0; i < self.maxConcurrentDownloads && _requestedCount < listCount; i++) {
        [self startPrefetchingAtIndex:i withManager:[SDWebImageManager sharedManager]];
    }
}

- (void)cancelPrefetching {
    self.prefetchList = nil;
    _skippedCount = 0;
    _requestedCount = 0;
    _finishedCount = 0;
    [[SDWebImageManager sharedManager] cancelForDelegate:self];
}

#pragma mark SDWebImagePrefetcher (SDWebImageManagerDelegate)

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image {
    _finishedCount++;
    NSLog(@"Prefetched %d out of %d", _finishedCount, [self.prefetchList count]);

    if ([self.prefetchList count] > _requestedCount) {
        [self startPrefetchingAtIndex:_requestedCount withManager:imageManager];
    } else if (_finishedCount == _requestedCount) {
        [self reportStatus];
    }
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error {
    _finishedCount++;
    NSLog(@"Prefetched %d out of %d (Failed)", _finishedCount, [self.prefetchList count]);

    // Add last failed 
    _skippedCount++;
    
    if ([self.prefetchList count] > _requestedCount) {
        [self startPrefetchingAtIndex:_requestedCount withManager:imageManager];
    } else if (_finishedCount == _requestedCount) {
        [self reportStatus];
    }
}


#pragma mark SDWebImagePrefetcher (Life Cycle)

- (void)dealloc {
    self.prefetchList = nil;
    [super dealloc];
}

#pragma mark SDWebImagePrefetcher (class methods)

+ (SDWebImagePrefetcher *)sharedImagePrefetcher
{
    if (instance == nil)
    {
        instance = [[SDWebImagePrefetcher alloc] init];
        instance.maxConcurrentDownloads = 3;
    }
    
    return instance;
}

@end
