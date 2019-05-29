/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import "SDWebImageTestTransformer.h"

@interface SDWebImageManagerTests : SDTestCase

@end

@implementation SDWebImageManagerTests

- (void)test01ThatSharedManagerIsNotEqualToInitManager {
    SDWebImageManager *manager = [[SDWebImageManager alloc] init];
    expect(manager).toNot.equal([SDWebImageManager sharedManager]);
}

- (void)test02ThatDownloadInvokesCompletionBlockWithCorrectParamsAsync {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image download completes"];

    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    
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

- (void)test06CancellAll {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel"];
    
    // need a bigger image here, that is why we don't use kTestJPEGURL
    // if the image is too small, it will get downloaded before we can cancel :)
    NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif"];
    [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
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

- (void)test08ThatImageTransformerWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image transformer work"];
    NSURL *url = [NSURL URLWithString:kTestJPEGURL];
    SDWebImageTestTransformer *transformer = [[SDWebImageTestTransformer alloc] init];
    
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithCache:[SDImageCache sharedImageCache] loader:[SDWebImageDownloader sharedDownloader]];
    manager.transformer = transformer;
    [[SDImageCache sharedImageCache] removeImageForKey:kTestJPEGURL withCompletion:^{
        [manager loadImageWithURL:url options:SDWebImageTransformAnimatedImage progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(image).equal(transformer.testImage);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test09ThatCacheKeyFilterWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cache key filter work"];
    NSURL *url = [NSURL URLWithString:kTestJPEGURL];
    
    NSString *cacheKey = @"kTestJPEGURL";
    SDWebImageCacheKeyFilter *cacheKeyFilter = [SDWebImageCacheKeyFilter cacheKeyFilterWithBlock:^NSString * _Nullable(NSURL * _Nonnull imageURL) {
        if ([url isEqual:imageURL]) {
            return cacheKey;
        } else {
            return url.absoluteString;
        }
    }];
    
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithCache:[SDImageCache sharedImageCache] loader:[SDWebImageDownloader sharedDownloader]];
    manager.cacheKeyFilter = cacheKeyFilter;
    // Check download and retrieve custom cache key
    [manager loadImageWithURL:url options:0 context:@{SDWebImageContextStoreCacheType : @(SDImageCacheTypeMemory)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(cacheType).equal(SDImageCacheTypeNone);
        
        // Check memory cache exist
        [manager.imageCache containsImageForKey:cacheKey cacheType:SDImageCacheTypeMemory completion:^(SDImageCacheType containsCacheType) {
            expect(containsCacheType).equal(SDImageCacheTypeMemory);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test10ThatCacheSerializerWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cache serializer work"];
    NSURL *url = [NSURL URLWithString:kTestJPEGURL];
    __block NSData *imageData;
    
    SDWebImageCacheSerializer *cacheSerializer = [SDWebImageCacheSerializer cacheSerializerWithBlock:^NSData * _Nullable(UIImage * _Nonnull image, NSData * _Nullable data, NSURL * _Nullable imageURL) {
        imageData = [image sd_imageDataAsFormat:SDImageFormatPNG];
        return imageData;
    }];
    
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithCache:[SDImageCache sharedImageCache] loader:[SDWebImageDownloader sharedDownloader]];
    manager.cacheSerializer = cacheSerializer;
    // Check download and store custom disk data
    [[SDImageCache sharedImageCache] removeImageForKey:kTestJPEGURL withCompletion:^{
        [manager loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            // Dispatch to let store disk finish
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
                NSData *diskImageData = [[SDImageCache sharedImageCache] diskImageDataForKey:kTestJPEGURL];
                expect(diskImageData).equal(imageData); // disk data equal to serializer data
                
                [expectation fulfill];
            });
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

@end
