/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import "SDWebImageTestTransformer.h"
#import "SDWebImageTestCache.h"
#import "SDWebImageTestLoader.h"

// Keep strong references for object
@interface SDObjectContainer<ObjectType> : NSObject
@property (nonatomic, strong, readwrite) ObjectType object;
@end

@implementation SDObjectContainer
@end

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
    
    [SDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestJPEGURL];
    [SDImageCache.sharedImageCache removeImageFromDiskForKey:kTestJPEGURL];
    SDObjectContainer<SDWebImageCombinedOperation *> *container = [SDObjectContainer new];
    container.object = [[SDWebImageManager sharedManager] loadImageWithURL:originalImageURL
                                                                   options:0
                                                                  progress:nil
                                                                 completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        expect(image).toNot.beNil();
        expect(error).to.beNil();
        expect(originalImageURL).to.equal(imageURL);
        
        // When download, the cache operation will reset to nil since it's always finished
        SDWebImageCombinedOperation *operation = container.object;
        expect(container).notTo.beNil();
        expect(operation.cacheOperation).beNil();
        expect(operation.loaderOperation).notTo.beNil();
        container.object = nil;
        
        [expectation fulfill];
        expectation = nil;
    }];
    expect([[SDWebImageManager sharedManager] isRunning]).to.equal(YES);

    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 2 handler:nil];
}

- (void)test03ThatDownloadWithIncorrectURLInvokesCompletionBlockWithAnErrorAsync {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Image download completes"];

    NSURL *originalImageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.png"];
    
    [[SDWebImageManager sharedManager] loadImageWithURL:originalImageURL
                                                options:0
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
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel should callback with error"];
    
    // need a bigger image here, that is why we don't use kTestJPEGURL
    // if the image is too small, it will get downloaded before we can cancel :)
    NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif"];
    [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(error).notTo.beNil();
        expect(error.code).equal(SDWebImageErrorCancelled);
    }];
    
    [[SDWebImageManager sharedManager] cancelAll];
    
    // doesn't cancel immediately - since it uses dispatch async
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        expect([[SDWebImageManager sharedManager] isRunning]).to.equal(NO);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 2 handler:nil];
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
        [manager loadImageWithURL:url options:SDWebImageTransformAnimatedImage | SDWebImageTransformVectorImage progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
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

- (void)test11ThatOptionsProcessorWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Options processor work"];
    __block BOOL optionsProcessorCalled = NO;
    
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithCache:[SDImageCache sharedImageCache] loader:[SDWebImageDownloader sharedDownloader]];
    manager.optionsProcessor = [SDWebImageOptionsProcessor optionsProcessorWithBlock:^SDWebImageOptionsResult * _Nullable(NSURL * _Nonnull url, SDWebImageOptions options, SDWebImageContext * _Nullable context) {
        if ([url.absoluteString isEqualToString:kTestPNGURL]) {
            optionsProcessorCalled = YES;
            return [[SDWebImageOptionsResult alloc] initWithOptions:0 context:@{SDWebImageContextImageScaleFactor : @(3)}];
        } else {
            return nil;
        }
    }];
    
    NSURL *url = [NSURL URLWithString:kTestPNGURL];
    [[SDImageCache sharedImageCache] removeImageForKey:kTestPNGURL withCompletion:^{
        [manager loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(image.scale).equal(3);
            expect(optionsProcessorCalled).beTruthy();
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test12ThatStoreCacheTypeWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image store cache type (including transformer) work"];
    
    // Use a fresh manager && cache to avoid get effected by other test cases
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:@"SDWebImageStoreCacheType"];
    [cache clearDiskOnCompletion:nil];
    SDWebImageManager *manager = [[SDWebImageManager alloc] initWithCache:cache loader:SDWebImageDownloader.sharedDownloader];
    SDWebImageTestTransformer *transformer = [[SDWebImageTestTransformer alloc] init];
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    manager.transformer = transformer;
    
    // test: original image -> disk only, transformed image -> memory only
    SDWebImageContext *context = @{SDWebImageContextOriginalStoreCacheType : @(SDImageCacheTypeDisk), SDWebImageContextStoreCacheType : @(SDImageCacheTypeMemory)};
    NSURL *url = [NSURL URLWithString:kTestAPNGPURL];
    NSString *originalKey = [manager cacheKeyForURL:url];
    NSString *transformedKey = [manager cacheKeyForURL:url context:context];
    
    [manager loadImageWithURL:url options:SDWebImageTransformAnimatedImage context:context progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).equal(transformer.testImage);
        // the transformed image should not inherite any attribute from original one
        expect(image.sd_imageFormat).equal(SDImageFormatJPEG);
        expect(image.sd_isAnimated).beFalsy();
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2*kMinDelayNanosecond), dispatch_get_main_queue(), ^{
            // original -> disk only
            UIImage *originalImage = [cache imageFromMemoryCacheForKey:originalKey];
            expect(originalImage).beNil();
            NSData *originalData = [cache diskImageDataForKey:originalKey];
            expect(originalData).notTo.beNil();
            originalImage = [UIImage sd_imageWithData:originalData];
            expect(originalImage).notTo.beNil();
            expect(originalImage.sd_imageFormat).equal(SDImageFormatPNG);
            expect(originalImage.sd_isAnimated).beTruthy();
            // transformed -> memory only
            [manager.imageCache containsImageForKey:transformedKey cacheType:SDImageCacheTypeAll completion:^(SDImageCacheType transformedCacheType) {
                expect(transformedCacheType).equal(SDImageCacheTypeMemory);
                [cache clearDiskOnCompletion:nil];
                [expectation fulfill];
            }];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test13ThatScaleDownLargeImageUseThumbnailDecoding {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageScaleDownLargeImages should translate to thumbnail decoding"];
    NSURL *originalImageURL = [NSURL URLWithString:@"http://via.placeholder.com/3999x3999.png"]; // Max size for this API
    NSUInteger defaultLimitBytes = SDImageCoderHelper.defaultScaleDownLimitBytes;
    SDImageCoderHelper.defaultScaleDownLimitBytes = 1000 * 1000 * 4; // Limit 1000x1000 pixel
    // From v5.5.0, the `SDWebImageScaleDownLargeImages` translate to `SDWebImageContextImageThumbnailPixelSize`, and works for progressive loading
    [SDImageCache.sharedImageCache removeImageFromDiskForKey:originalImageURL.absoluteString];
    [SDWebImageManager.sharedManager loadImageWithURL:originalImageURL options:SDWebImageScaleDownLargeImages | SDWebImageProgressiveLoad progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).notTo.beNil();
        expect(image.size).equal(CGSizeMake(1000, 1000));
        if (finished) {
            expect(image.sd_isIncremental).beFalsy();
            [expectation fulfill];
        } else {
            expect(image.sd_isIncremental).beTruthy();
        }
    }];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        SDImageCoderHelper.defaultScaleDownLimitBytes = defaultLimitBytes;
    }];
}

- (void)test13ThatScaleDownLargeImageEXIFOrientationImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageScaleDownLargeImages works on EXIF orientation image"];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/recurser/exif-orientation-examples/master/Landscape_2.jpg"];
    [SDWebImageManager.sharedManager loadImageWithURL:originalImageURL options:SDWebImageScaleDownLargeImages | SDWebImageAvoidDecodeImage progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).notTo.beNil();
#if SD_UIKIT
        UIImageOrientation orientation = [SDImageCoderHelper imageOrientationFromEXIFOrientation:kCGImagePropertyOrientationUpMirrored];
        expect(image.imageOrientation).equal(orientation);
#endif
        if (finished) {
            expect(image.sd_isIncremental).beFalsy();
            [expectation fulfill];
        } else {
            expect(image.sd_isIncremental).beTruthy();
        }
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test14ThatCustomCacheAndLoaderWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom Cache and Loader during manger query"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/100x100.png"];
    SDWebImageContext *context = @{
        SDWebImageContextImageCache : SDWebImageTestCache.sharedCache,
        SDWebImageContextImageLoader : SDWebImageTestLoader.sharedLoader
    };
    [SDWebImageTestCache.sharedCache clearWithCacheType:SDImageCacheTypeAll completion:nil];
    [SDWebImageManager.sharedManager loadImageWithURL:url options:SDWebImageWaitStoreCache context:context progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).notTo.beNil();
        expect(image.size.width).equal(100);
        expect(image.size.height).equal(100);
        expect(data).notTo.beNil();
        NSString *cacheKey = [SDWebImageManager.sharedManager cacheKeyForURL:imageURL];
        // Check Disk Cache (SDWebImageWaitStoreCache behavior)
        [SDWebImageTestCache.sharedCache containsImageForKey:cacheKey cacheType:SDImageCacheTypeDisk completion:^(SDImageCacheType containsCacheType) {
            expect(containsCacheType).equal(SDImageCacheTypeDisk);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test15ThatQueryCacheTypeWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image query cache type works"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/101x101.png"];
    NSString *key = [SDWebImageManager.sharedManager cacheKeyForURL:url];
    NSData *testImageData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    [SDImageCache.sharedImageCache storeImageDataToDisk:testImageData forKey:key];
    
    // Query memory first
    [SDWebImageManager.sharedManager loadImageWithURL:url options:SDWebImageFromCacheOnly context:@{SDWebImageContextQueryCacheType : @(SDImageCacheTypeMemory)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image).beNil();
        expect(cacheType).equal(SDImageCacheTypeNone);
        // Query disk secondly
        [SDWebImageManager.sharedManager loadImageWithURL:url options:SDWebImageFromCacheOnly context:@{SDWebImageContextQueryCacheType : @(SDImageCacheTypeDisk)} progress:nil completed:^(UIImage * _Nullable image2, NSData * _Nullable data2, NSError * _Nullable error2, SDImageCacheType cacheType2, BOOL finished2, NSURL * _Nullable imageURL2) {
            expect(image2).notTo.beNil();
            expect(cacheType2).equal(SDImageCacheTypeDisk);
            [SDImageCache.sharedImageCache removeImageFromDiskForKey:key];
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test15ThatOriginalQueryCacheTypeWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image original query cache type with transformer works"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/102x102.png"];
    SDWebImageTestTransformer *transformer = [[SDWebImageTestTransformer alloc] init];
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSString *originalKey = [SDWebImageManager.sharedManager cacheKeyForURL:url];
    NSString *transformedKey = [SDWebImageManager.sharedManager cacheKeyForURL:url context:@{SDWebImageContextImageTransformer : transformer}];
    
    [[SDWebImageManager sharedManager] loadImageWithURL:url options:0 context:@{SDWebImageContextImageTransformer : transformer, SDWebImageContextOriginalStoreCacheType : @(SDImageCacheTypeAll)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        // Get the transformed image
        expect(image).equal(transformer.testImage);
        // Now, the original image is stored into memory/disk cache
        UIImage *originalImage = [SDImageCache.sharedImageCache imageFromMemoryCacheForKey:originalKey];
        expect(originalImage.size).equal(CGSizeMake(102, 102));
        // Query again with original cache type, which should not trigger any download
        UIImage *transformedImage = [SDImageCache.sharedImageCache imageFromMemoryCacheForKey:transformedKey];
        expect(image).equal(transformedImage);
        [SDImageCache.sharedImageCache removeImageFromDiskForKey:transformedKey];
        [SDImageCache.sharedImageCache removeImageFromMemoryForKey:transformedKey];
        [SDWebImageManager.sharedManager loadImageWithURL:url options:SDWebImageFromCacheOnly context:@{SDWebImageContextImageTransformer : transformer, SDWebImageContextOriginalQueryCacheType : @(SDImageCacheTypeAll)} progress:nil completed:^(UIImage * _Nullable image2, NSData * _Nullable data2, NSError * _Nullable error2, SDImageCacheType cacheType2, BOOL finished2, NSURL * _Nullable imageURL2) {
            // Get the transformed image
            expect(image2).equal(transformer.testImage);
            [SDImageCache.sharedImageCache removeImageFromMemoryForKey:originalKey];
            [SDImageCache.sharedImageCache removeImageFromDiskForKey:originalKey];
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test16ThatTransformerUseDifferentCacheForOriginalAndTransformedImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Image transformer use different cache instance for original image and transformed image works"];
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/103x103.png"];
    SDWebImageTestTransformer *transformer = [[SDWebImageTestTransformer alloc] init];
    transformer.testImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSString *originalKey = [SDWebImageManager.sharedManager cacheKeyForURL:url];
    NSString *transformedKey = [SDWebImageManager.sharedManager cacheKeyForURL:url context:@{SDWebImageContextImageTransformer : transformer}];
    
    SDImageCache *transformerCache = [[SDImageCache alloc] initWithNamespace:@"TransformerCache"];
    SDImageCache *originalCache = [[SDImageCache alloc] initWithNamespace:@"OriginalCache"];
    
    [[SDWebImageManager sharedManager] loadImageWithURL:url options:SDWebImageWaitStoreCache context:
     @{SDWebImageContextImageTransformer : transformer,
       SDWebImageContextOriginalImageCache : originalCache,
       SDWebImageContextImageCache : transformerCache,
       SDWebImageContextOriginalStoreCacheType: @(SDImageCacheTypeMemory),
       SDWebImageContextStoreCacheType: @(SDImageCacheTypeMemory)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        // Get the transformed image
        expect(image).equal(transformer.testImage);
        // Now, the original image is stored into originalCache
        UIImage *originalImage = [originalCache imageFromMemoryCacheForKey:originalKey];
        expect(originalImage.size).equal(CGSizeMake(103, 103));
        expect([transformerCache imageFromMemoryCacheForKey:originalKey]).beNil();
        
        // The transformed image is stored into transformerCache
        UIImage *transformedImage = [transformerCache imageFromMemoryCacheForKey:transformedKey];
        expect(image).equal(transformedImage);
        expect([originalCache imageFromMemoryCacheForKey:transformedKey]).beNil();
        
        [originalCache clearWithCacheType:SDImageCacheTypeAll completion:nil];
        [transformerCache clearWithCacheType:SDImageCacheTypeAll completion:nil];
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 10 handler:nil];
}

- (void)test17ThatThumbnailCacheQueryNotWriteToWrongKey {
    // 1. When query thumbnail decoding for SDImageCache, the thumbnailed image should not stored into full size key
    XCTestExpectation *expectation = [self expectationWithDescription:@"Thumbnail for cache should not store the wrong key"];
    
    // 500x500
    CGSize fullSize = CGSizeMake(500, 500);
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:fullSize];
    UIImage *fullSizeImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, fullSize.width, fullSize.height));
    }];
    expect(fullSizeImage.size).equal(fullSize);
    
    NSString *fullSizeKey = @"kTestRectangle";
    // Disk only
    [SDImageCache.sharedImageCache storeImageDataToDisk:fullSizeImage.sd_imageData forKey:fullSizeKey];
    
    CGSize thumbnailSize = CGSizeMake(100, 100);
    NSString *thumbnailKey = SDThumbnailedKeyForKey(fullSizeKey, thumbnailSize, YES);
    // thumbnail size key miss, full size key hit
    [SDImageCache.sharedImageCache queryCacheOperationForKey:fullSizeKey options:0 context:@{SDWebImageContextImageThumbnailPixelSize : @(thumbnailSize)} done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(image.size).equal(thumbnailSize);
        expect(cacheType).equal(SDImageCacheTypeDisk);
        // Currently, thumbnail decoding does not write back to the original key's memory cache
        // But this may change in the future once I change the API for `SDImageCacheProtocol`
        expect([SDImageCache.sharedImageCache imageFromMemoryCacheForKey:fullSizeKey]).beNil();
        expect([SDImageCache.sharedImageCache imageFromMemoryCacheForKey:thumbnailKey]).beNil();
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test18ThatThumbnailLoadingCanUseFullSizeCache {
    // 2. When using SDWebImageManager to load thumbnail image, it will prefers the full size image and thumbnail decoding on the fly, no network
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Thumbnail for loading should prefers full size cache when thumbnail cache miss, like Transformer behavior"];
    
    // 500x500
    CGSize fullSize = CGSizeMake(500, 500);
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:fullSize];
    UIImage *fullSizeImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, CGRectMake(0, 0, fullSize.width, fullSize.height));
    }];
    expect(fullSizeImage.size).equal(fullSize);
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/500x500.png"];
    NSString *fullSizeKey = [SDWebImageManager.sharedManager cacheKeyForURL:url];
    [SDImageCache.sharedImageCache storeImageDataToDisk:fullSizeImage.sd_imageData forKey:fullSizeKey];
    
    CGSize thumbnailSize = CGSizeMake(100, 100);
    NSString *thumbnailKey = SDThumbnailedKeyForKey(fullSizeKey, thumbnailSize, YES);
    [SDImageCache.sharedImageCache removeImageFromDiskForKey:thumbnailKey];
    // Load with thumbnail, should use full size cache instead to decode and scale down
    [SDWebImageManager.sharedManager loadImageWithURL:url options:0 context:@{SDWebImageContextImageThumbnailPixelSize : @(thumbnailSize)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        expect(image.size).equal(thumbnailSize);
        expect(cacheType).equal(SDImageCacheTypeDisk);
        expect(finished).beTruthy();
        
        // The thumbnail one should stored into memory and disk cache with thumbnail key as well
        expect([SDImageCache.sharedImageCache imageFromMemoryCacheForKey:thumbnailKey].size).equal(thumbnailSize);
        expect([SDImageCache.sharedImageCache imageFromDiskCacheForKey:thumbnailKey].size).equal(thumbnailSize);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test19ThatDifferentThumbnailLoadShouldCallbackDifferentSize {
    // 3. Current SDWebImageDownloader use the **URL** as primiary key to bind operation, however, different loading pipeline may ask different image size for same URL, this design does not match
    // We use a hack logic to do a re-decode check when the callback image's decode options does not match the loading pipeline provided, it will re-decode the full data with global queue :)
    // Ugly unless we re-define the design of SDWebImageDownloader, maybe change that `addHandlersForProgress` with context options args as well. Different context options need different callback image
    
    NSURL *url = [NSURL URLWithString:@"http://via.placeholder.com/501x501.png"];
    NSString *fullSizeKey = [SDWebImageManager.sharedManager cacheKeyForURL:url];
    [SDImageCache.sharedImageCache removeImageFromDiskForKey:fullSizeKey];
    for (int i = 490; i < 500; i++) {
        // 490x490, ..., 499x499
        CGSize thumbnailSize = CGSizeMake(i, i);
        NSString *thumbnailKey = SDThumbnailedKeyForKey(fullSizeKey, thumbnailSize, YES);
        [SDImageCache.sharedImageCache removeImageFromDiskForKey:thumbnailKey];
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"Different thumbnail loading for same URL should callback different image size: (%dx%d)", i, i]];
        [SDImageCache.sharedImageCache removeImageFromDiskForKey:url.absoluteString];
        __block SDWebImageCombinedOperation *operation;
        operation = [SDWebImageManager.sharedManager loadImageWithURL:url options:0 context:@{SDWebImageContextImageThumbnailPixelSize : @(thumbnailSize)} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(image.size).equal(thumbnailSize);
            expect(cacheType).equal(SDImageCacheTypeNone);
            expect(finished).beTruthy();
            
            NSURLRequest *request = ((SDWebImageDownloadToken *)operation.loaderOperation).request;
            NSLog(@"thumbnail image size: (%dx%d) loaded with the shared request: %p", i, i, request);
            [expectation fulfill];
        }];
    }
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 5 handler:nil];
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

@end
