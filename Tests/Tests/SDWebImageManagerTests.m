/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <SDWebImage/SDWebImageManager.h>

@interface SDWebImageManagerTests : SDTestCase

@end

@implementation SDWebImageManagerTests

- (void)test01ThatSharedManagerIsNotEqualToInitManager {
    SDWebImageManager *manager = [[SDWebImageManager alloc] init];
    expect(manager).toNot.equal([SDWebImageManager sharedManager]);
}

- (void)test02ThatDownloadInvokesCompletionBlockWithCorrectParamsAsync {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image download completes"];

    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [[SDWebImageManager sharedManager] loadImageWithURL:originalImageURL
                                                options:SDWebImageRefreshCached
                                               progress:nil
                                              completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        expect(image).toNot.beNil();
        expect(error).to.beNil();
        expect(originalImageURL).to.equal(imageURL);

        [expectation fulfill];
        expectation = nil;
    }];
    expect([[SDWebImageManager sharedManager] isRunning]).to.equal(YES);

    [self waitForExpectationsWithCommonTimeout];
}

- (void)test03ThatDownloadWithIncorrectURLInvokesCompletionBlockWithAnErrorAsync {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image download completes"];

    NSURL *originalImageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.png"];
    
    [[SDWebImageManager sharedManager] loadImageWithURL:originalImageURL
                                                options:SDWebImageRefreshCached
                                               progress:nil
                                              completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        expect(image).to.beNil();
        expect(error).toNot.beNil();
        expect(originalImageURL).to.equal(imageURL);
        
        [expectation fulfill];
        expectation = nil;
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test04CachedImageExistsForURL {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image exists in cache"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [[SDWebImageManager sharedManager] cachedImageExistsForURL:imageURL completion:^(BOOL isInCache) {
        if (isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test05DiskImageExistsForURL {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image exists in disk cache"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [[SDWebImageManager sharedManager] diskImageExistsForURL:imageURL completion:^(BOOL isInCache) {
        if (isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test06CancellAll {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel"];
    
    // need a bigger image here, that is why we don't use kTestJpegURL
    // if the image is too small, it will get downloaded before we can cancel :)
    NSURL *imageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage001.jpg"];
    [[SDWebImageManager sharedManager] loadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        XCTFail(@"Should not get here");
    }];
    
    [[SDWebImageManager sharedManager] cancelAll];
    
    // doesn't cancel immediately - since it uses dispatch async
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        expect([[SDWebImageManager sharedManager] isRunning]).to.equal(NO);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test07ThatLoadImageWithSDWebImageRefreshCachedWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image download twice with SDWebImageRefresh failed"];
    NSURL *originalImageURL = [NSURL URLWithString:@"http://via.placeholder.com/10x10.png"];
    __block BOOL firstCompletion = NO;
    [[SDWebImageManager sharedManager] loadImageWithURL:originalImageURL options:SDWebImageRefreshCached progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).toNot.beNil();
        expect(error).to.beNil();
        // #1993, load image with SDWebImageRefreshCached twice should not fail if the first time success.
        
        // Because we call completion before remove the operation from queue, so need a dispatch to avoid get the same operation again. Attention this trap.
        // One way to solve this is use another `NSURL instance` because we use `NSURL` as key but not `NSString`. However, this is implementation detail and no guarantee in the future.
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *newImageURL = [NSURL URLWithString:@"http://via.placeholder.com/10x10.png"];
            [[SDWebImageManager sharedManager] loadImageWithURL:newImageURL options:SDWebImageRefreshCached progress:nil completed:^(UIImage * _Nullable image2, NSData * _Nullable data2, NSError * _Nullable error2, SDImageCacheType cacheType2, BOOL finished2, NSURL * _Nullable imageURL2) {
                expect(image2).toNot.beNil();
                expect(error2).to.beNil();
                if (!firstCompletion) {
                    firstCompletion = YES;
                    [expectation fulfill];
                }
            }];
        });
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 2 handler:nil];
}

@end
