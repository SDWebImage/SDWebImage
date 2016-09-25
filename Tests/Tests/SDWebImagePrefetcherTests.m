/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>

#import <SDWebImage/SDWebImagePrefetcher.h>

@interface SDWebImagePrefetcherTests : XCTestCase

@end

@implementation SDWebImagePrefetcherTests

- (void)test01ThatSharedPrefetcherIsNotEqualToInitPrefetcher {
    SDWebImagePrefetcher *prefetcher = [[SDWebImagePrefetcher alloc] init];
    expect(prefetcher).toNot.equal([SDWebImagePrefetcher sharedImagePrefetcher]);
}

- (void)test02PrefetchMultipleImages {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct prefetch of multiple images"];
    
    NSMutableArray *imageURLs = [NSMutableArray array];
    
    for (int i=40; i<43; i++) {
        NSString *imageURLString = [NSString stringWithFormat:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage%03d.jpg", i];
        NSURL *imageURL = [NSURL URLWithString:imageURLString];
        [imageURLs addObject:imageURL];
    }
    
    __block int numberOfPrefetched = 0;
    
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
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)test03PrefetchWithEmptyArrayWillCallTheCompletionWithAllZeros {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Prefetch with empty array"];
    
    [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[] progress:nil completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
        expect(noOfFinishedUrls).to.equal(0);
        expect(noOfSkippedUrls).to.equal(0);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

// TODO: test the prefetcher delegate works

@end
