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

- (void)startPrefetchingAtIndex:(NSUInteger)index withManager:(SDWebImageManager *)imageManager {
    NSURL *url = [self.prefetchList objectAtIndex:index];
    _lastPrefetchedIndex = index;
    [imageManager downloadWithURL:url delegate:self retryFailed:NO lowPriority:YES];
}

- (void)reportStatus {
    NSUInteger total = [self.prefetchList count];
    NSLog(@"Finished prefetching (%d successful, %d skipped)", total - _skippedCount, _skippedCount);
}

- (void)startPrefetchingWithList:(NSArray *)list {
    [self cancelPrefetching];   // Prevent duplicate prefetch request
    self.prefetchList = list;

    // Starts from the very first image on the list
    [self startPrefetchingAtIndex:0 withManager:[SDWebImageManager sharedManager]];
}

- (void)cancelPrefetching {
    self.prefetchList = nil;
    _skippedCount = 0;
    [[SDWebImageManager sharedManager] cancelForDelegate:self];
}

#pragma mark SDWebImagePrefetcher (SDWebImageManagerDelegate)

- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image {
    NSLog(@"Prefetched %d out of %d", _lastPrefetchedIndex + 1, [self.prefetchList count]);

    if ([self.prefetchList count] > _lastPrefetchedIndex + 1) {
        [self startPrefetchingAtIndex:_lastPrefetchedIndex + 1 withManager:imageManager];
    } else {
        [self reportStatus];
    }
}

- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error {
    NSLog(@"Prefetched %d out of %d (Failed)", _lastPrefetchedIndex + 1, [self.prefetchList count]);

    // Add last failed 
    _skippedCount++;
    
    if ([self.prefetchList count] > _lastPrefetchedIndex + 1) {
        [self startPrefetchingAtIndex:_lastPrefetchedIndex + 1 withManager:imageManager];
    } else {
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
    }
    
    return instance;
}

@end
