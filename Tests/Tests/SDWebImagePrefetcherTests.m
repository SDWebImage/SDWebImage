/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <SDWebImage/SDWebImagePrefetcher.h>

@interface SDWebImagePrefetcherTests : SDTestCase

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

// TODO: test the prefetcher delegate works

@end
