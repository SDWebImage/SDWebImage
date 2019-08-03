/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"

@interface SDWebImagePrefetcher ()

@property (strong, atomic, nonnull) NSMutableSet<SDWebImagePrefetchToken *> *runningTokens;

@end

@interface SDWebImagePrefetcherTests : SDTestCase <SDWebImagePrefetcherDelegate>

@property (nonatomic, strong) SDWebImagePrefetcher *prefetcher;
@property (atomic, assign) NSUInteger finishedCount;
@property (atomic, assign) NSUInteger skippedCount;
@property (atomic, assign) NSUInteger totalCount;

@end

@implementation SDWebImagePrefetcherTests

- (void)test01ThatSharedPrefetcherIsNotEqualToInitPrefetcher {
    SDWebImagePrefetcher *prefetcher = [[SDWebImagePrefetcher alloc] init];
    expect(prefetcher).toNot.equal([SDWebImagePrefetcher sharedImagePrefetcher]);
}

- (void)test02PrefetchMultipleImages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct prefetch of multiple images"];
    
    NSArray *imageURLs = @[@"http://via.placeholder.com/20x20.jpg",
                           @"http://via.placeholder.com/30x30.jpg",
                           @"http://via.placeholder.com/40x40.jpg"];
    
    __block NSUInteger numberOfPrefetched = 0;
    
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:imageURLs progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
            numberOfPrefetched += 1;
            expect(numberOfPrefetched).to.equal(noOfFinishedUrls);
            expect(noOfFinishedUrls).to.beLessThanOrEqualTo(noOfTotalUrls);
            expect(noOfTotalUrls).to.equal(imageURLs.count);
        } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
            expect(numberOfPrefetched).to.equal(noOfFinishedUrls);
            expect(noOfFinishedUrls).to.equal(imageURLs.count);
            expect(noOfSkippedUrls).to.equal(0);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 3 handler:nil];
}

- (void)test03PrefetchWithEmptyArrayWillCallTheCompletionWithAllZeros {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prefetch with empty array"];
    
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[] progress:nil completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
        expect(noOfFinishedUrls).to.equal(0);
        expect(noOfSkippedUrls).to.equal(0);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test04PrefetchWithMultipleArrayDifferentQueueWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prefetch with multiple array at different queue failed"];
    
    NSArray *imageURLs1 = @[@"http://via.placeholder.com/20x20.jpg",
                            @"http://via.placeholder.com/30x30.jpg"];
    NSArray *imageURLs2 = @[@"http://via.placeholder.com/30x30.jpg",
                           @"http://via.placeholder.com/40x40.jpg"];
    dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_queue_t queue2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    __block int numberOfPrefetched1 = 0;
    __block int numberOfPrefetched2 = 0;
    __block BOOL prefetchFinished1 = NO;
    __block BOOL prefetchFinished2 = NO;
    
    // Clear the disk cache to make it more realistic for multi-thread environment
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        dispatch_async(queue1, ^{
            [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:imageURLs1 progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
                numberOfPrefetched1 += 1;
            } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
                expect(numberOfPrefetched1).to.equal(noOfFinishedUrls);
                prefetchFinished1 = YES;
                // both completion called
                if (prefetchFinished1 && prefetchFinished2) {
                    [expectation fulfill];
                }
            }];
        });
        dispatch_async(queue2, ^{
            [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:imageURLs2 progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
                numberOfPrefetched2 += 1;
            } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
                expect(numberOfPrefetched2).to.equal(noOfFinishedUrls);
                prefetchFinished2 = YES;
                // both completion called
                if (prefetchFinished1 && prefetchFinished2) {
                    [expectation fulfill];
                }
            }];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test05PrefetchLargeURLsAndDelegateWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prefetch large URLs and delegate failed"];
    
    // This test also test large URLs and thread-safe problem. You can tested with 2000 urls and get the correct result locally. However, due to the limit of CI, 20 is enough.
    NSMutableArray<NSURL *> *imageURLs = [NSMutableArray arrayWithCapacity:20];
    for (size_t i = 1; i <= 20; i++) {
        NSString *url = [NSString stringWithFormat:@"http://via.placeholder.com/%zux%zu.jpg", i, i];
        [imageURLs addObject:[NSURL URLWithString:url]];
    }
    self.prefetcher = [SDWebImagePrefetcher new];
    self.prefetcher.delegate = self;
    // Current implementation, the delegate method called before the progressBlock and completionBlock
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        [self.prefetcher prefetchURLs:[imageURLs copy] progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
            expect(self.finishedCount).to.equal(noOfFinishedUrls);
            expect(self.totalCount).to.equal(noOfTotalUrls);
        } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
            expect(self.finishedCount).to.equal(noOfFinishedUrls);
            expect(self.skippedCount).to.equal(noOfSkippedUrls);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 20 handler:nil];
}

- (void)test06PrefetchCancelToken {
    NSArray *imageURLs = @[@"http://via.placeholder.com/20x20.jpg",
                           @"http://via.placeholder.com/30x30.jpg",
                           @"http://via.placeholder.com/40x40.jpg"];
    SDWebImagePrefetcher *prefetcher = [[SDWebImagePrefetcher alloc] init];
    SDWebImagePrefetchToken *token = [prefetcher prefetchURLs:imageURLs];
    expect(prefetcher.runningTokens.count).equal(1);
    [token cancel];
    expect(prefetcher.runningTokens.count).equal(0);
}

- (void)test07DownloaderCancelDuringPrefetching {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Downloader cancel during prefetch should not hung up"];
    
    NSArray *imageURLs = @[@"http://via.placeholder.com/5000x5000.jpg",
                           @"http://via.placeholder.com/6000x6000.jpg",
                           @"http://via.placeholder.com/7000x7000.jpg"];
    for (NSString *url in imageURLs) {
        [SDImageCache.sharedImageCache removeImageFromDiskForKey:url];
    }
    SDWebImagePrefetcher *prefetcher = [[SDWebImagePrefetcher alloc] init];
    prefetcher.maxConcurrentPrefetchCount = 3;
    [prefetcher prefetchURLs:imageURLs progress:nil completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
        expect(noOfSkippedUrls).equal(3);
        [expectation fulfill];
    }];
    
    // Cancel all download, should not effect the prefetcher logic or cause hung up
    // Prefetch is not sync, so using wait for testing
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        [SDWebImageDownloader.sharedDownloader cancelAllDownloads];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)imagePrefetcher:(SDWebImagePrefetcher *)imagePrefetcher didFinishWithTotalCount:(NSUInteger)totalCount skippedCount:(NSUInteger)skippedCount {
    expect(imagePrefetcher).to.equal(self.prefetcher);
    self.skippedCount = skippedCount;
    self.totalCount = totalCount;
}

- (void)imagePrefetcher:(SDWebImagePrefetcher *)imagePrefetcher didPrefetchURL:(NSURL *)imageURL finishedCount:(NSUInteger)finishedCount totalCount:(NSUInteger)totalCount {
    expect(imagePrefetcher).to.equal(self.prefetcher);
    self.finishedCount = finishedCount;
    self.totalCount = totalCount;
}

@end
