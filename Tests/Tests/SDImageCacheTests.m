/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import "SDWebImageTestCoder.h"
#import "SDMockFileManager.h"
#import "SDWebImageTestCache.h"

static NSString *kTestImageKeyJPEG = @"TestImageKey.jpg";
static NSString *kTestImageKeyPNG = @"TestImageKey.png";

@interface SDImageCacheTests : SDTestCase <NSFileManagerDelegate>

@end

@implementation SDImageCacheTests

- (void)test01SharedImageCache {
    expect([SDImageCache sharedImageCache]).toNot.beNil();
}

- (void)test02Singleton{
    expect([SDImageCache sharedImageCache]).to.equal([SDImageCache sharedImageCache]);
}

- (void)test03ImageCacheCanBeInstantiated {
    SDImageCache *imageCache = [[SDImageCache alloc] init];
    expect(imageCache).toNot.equal([SDImageCache sharedImageCache]);
}

- (void)test04ClearDiskCache{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear disk cache"];
    
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal([self testJPEGImage]);
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            if (!isInCache) {
                [[SDImageCache sharedImageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
                    expect(fileCount).to.equal(0);
                    [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                        [expectation fulfill];
                    }];
                }];
            } else {
                XCTFail(@"Image should not be in cache");
            }
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test05ClearMemoryCache{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear memory cache"];
    
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:^{
        [[SDImageCache sharedImageCache] clearMemory];
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            if (isInCache) {
                [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                    [expectation fulfill];
                }];
            } else {
                XCTFail(@"Image should be in cache");
            }
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:
- (void)test06InsertionOfImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey"];
    
    UIImage *image = [self testJPEGImage];
    [[SDImageCache sharedImageCache] storeImage:image forKey:kTestImageKeyJPEG completion:nil];
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal(image);
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        if (isInCache) {
            [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                [expectation fulfill];
            }];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:toDisk:YES
- (void)test07InsertionOfImageForcingDiskStorage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey toDisk=YES"];
    
    UIImage *image = [self testJPEGImage];
    [[SDImageCache sharedImageCache] storeImage:image forKey:kTestImageKeyJPEG toDisk:YES completion:nil];
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal(image);
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        if (isInCache) {
            [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
                [expectation fulfill];
            }];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:toDisk:NO
- (void)test08InsertionOfImageOnlyInMemory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey toDisk=NO"];
    UIImage *image = [self testJPEGImage];
    [[SDImageCache sharedImageCache] storeImage:image forKey:kTestImageKeyJPEG toDisk:NO completion:nil];
    
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.equal([self testJPEGImage]);
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        if (!isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should not be in cache");
        }
    }];
    [[SDImageCache sharedImageCache] storeImageToMemory:image forKey:kTestImageKeyJPEG];
    [[SDImageCache sharedImageCache] clearMemory];
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil();
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test09RetrieveImageThroughNSOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"queryCacheOperationForKey"];
    UIImage *imageForTesting = [self testJPEGImage];
    [[SDImageCache sharedImageCache] storeImage:imageForTesting forKey:kTestImageKeyJPEG completion:nil];
    NSOperation *operation = [[SDImageCache sharedImageCache] queryCacheOperationForKey:kTestImageKeyJPEG done:^(UIImage *image, NSData *data, SDImageCacheType cacheType) {
        expect(image).to.equal(imageForTesting);
        [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    expect(operation).toNot.beNil;
    [operation start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test10RemoveImageForKeyWithCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:kTestImageKeyJPEG]).to.beNil;
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test11RemoveImageforKeyNotFromDiskWithCompletion{
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey fromDisk:NO"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG fromDisk:NO withCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:kTestImageKeyJPEG]).toNot.beNil;
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test12RemoveImageforKeyFromDiskWithCompletion{
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey fromDisk:YES"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:nil];
    [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG fromDisk:YES withCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:kTestImageKeyJPEG]).to.beNil;
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test13DeleteOldFiles {
    XCTestExpectation *expectation = [self expectationWithDescription:@"deleteOldFiles"];
    [SDImageCache sharedImageCache].config.maxDiskAge = 1; // 1 second to mark all as out-dated
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[SDImageCache sharedImageCache] deleteOldFilesWithCompletionBlock:^{
            expect(SDImageCache.sharedImageCache.totalDiskCount).equal(0);
            [expectation fulfill];
        }];
    });
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test14QueryCacheFirstFrameOnlyHitMemoryCache {
    NSString *key = kTestGIFURL;
    UIImage *animatedImage = [self testGIFImage];
    [[SDImageCache sharedImageCache] storeImageToMemory:animatedImage forKey:key];
    [[SDImageCache sharedImageCache] queryCacheOperationForKey:key done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(cacheType).equal(SDImageCacheTypeMemory);
        expect(image.sd_isAnimated).beTruthy();
        expect(image == animatedImage).beTruthy();
    }];
    [[SDImageCache sharedImageCache] queryCacheOperationForKey:key options:SDImageCacheDecodeFirstFrameOnly done:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(cacheType).equal(SDImageCacheTypeMemory);
        expect(image.sd_isAnimated).beFalsy();
        expect(image == animatedImage).beFalsy();
    }];
    [[SDImageCache sharedImageCache] removeImageFromMemoryForKey:kTestGIFURL];
}

- (void)test20InitialCacheSize{
    expect([[SDImageCache sharedImageCache] totalDiskSize]).to.equal(0);
}

- (void)test21InitialDiskCount{
    XCTestExpectation *expectation = [self expectationWithDescription:@"getDiskCount"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:^{
        expect([[SDImageCache sharedImageCache] totalDiskCount]).to.equal(1);
        [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test31CachePathForAnyKey{
    NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
    expect(path).toNot.beNil;
}

- (void)test32CachePathForNilKey{
    NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:nil];
    expect(path).to.beNil;
}

- (void)test33CachePathForExistingKey{
    XCTestExpectation *expectation = [self expectationWithDescription:@"cachePathForKey inPath"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:^{
        NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
        expect(path).notTo.beNil;
        [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test34CachePathForSimpleKeyWithExtension {
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:kTestJPEGURL];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"jpg");
}

- (void)test35CachePathForKeyWithDotButNoExtension {
    NSString *urlString = @"https://maps.googleapis.com/maps/api/staticmap?center=48.8566,2.3522&format=png&maptype=roadmap&scale=2&size=375x200&zoom=15";
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:urlString];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"");
}

- (void)test36CachePathForKeyWithURLQueryParams {
    NSString *urlString = @"https://imggen.alicdn.com/3b11cea896a9438329d85abfb07b30a8.jpg?aid=tanx&tid=1166&m=%7B%22img_url%22%3A%22https%3A%2F%2Fgma.alicdn.com%2Fbao%2Fuploaded%2Fi4%2F1695306010722305097%2FTB2S2KjkHtlpuFjSspoXXbcDpXa_%21%210-saturn_solar.jpg_sum.jpg%22%2C%22title%22%3A%22%E6%A4%8D%E7%89%A9%E8%94%B7%E8%96%87%E7%8E%AB%E7%91%B0%E8%8A%B1%22%2C%22promot_name%22%3A%22%22%2C%22itemid%22%3A%22546038044448%22%7D&e=cb88dab197bfaa19804f6ec796ca906dab536b88fe6d4475795c7ee661a7ede1&size=640x246";
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:urlString];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"jpg");
}

- (void)test37CachePathForKeyWithTooLongExtension {
    NSString *urlString = @"https://imggen.alicdn.com/3b11cea896a9438329d85abfb07b30a8.jpgasaaaaaaaaaaaaaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjaaaaaaaaaaaaaaaaajjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj";
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:urlString];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"");
}

- (void)test40InsertionOfImageData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Insertion of image data works"];
    
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSData *imageData = [image sd_imageDataAsFormat:SDImageFormatJPEG];
    [[SDImageCache sharedImageCache] storeImageDataToDisk:imageData forKey:kTestImageKeyJPEG];
    
    expect([[SDImageCache sharedImageCache] diskImageDataExistsWithKey:kTestImageKeyJPEG]).beTruthy();
    UIImage *storedImageFromMemory = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
    expect(storedImageFromMemory).to.equal(nil);
    
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
    UIImage *cachedImage = [[UIImage alloc] initWithContentsOfFile:cachePath];
    NSData *storedImageData = [cachedImage sd_imageDataAsFormat:SDImageFormatJPEG];
    expect(storedImageData.length).to.beGreaterThan(0);
    expect(cachedImage.size).to.equal(image.size);
    // can't directly compare image and cachedImage because apparently there are some slight differences, even though the image is the same
    
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(YES);
        
        [[SDImageCache sharedImageCache] removeImageForKey:kTestImageKeyJPEG withCompletion:^{
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test41ThatCustomDecoderWorksForImageCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom decoder for SDImageCache not works"];
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:@"TestDecode"];
    SDWebImageTestCoder *testDecoder = [[SDWebImageTestCoder alloc] init];
    [[SDImageCodersManager sharedManager] addCoder:testDecoder];
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    NSString *key = @"TestPNGImageEncodedToDataAndRetrieveToJPEG";
    
    [cache storeImage:image imageData:nil forKey:key toDisk:YES completion:^{
        [cache clearMemory];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL diskImageDataBySearchingAllPathsForKey = @selector(diskImageDataBySearchingAllPathsForKey:);
#pragma clang diagnostic pop
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSData *data = [cache performSelector:diskImageDataBySearchingAllPathsForKey withObject:key];
#pragma clang diagnostic pop
        NSString *str1 = @"TestEncode";
        NSString *str2 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![str1 isEqualToString:str2]) {
            XCTFail(@"Custom decoder not work for SDImageCache, check -[SDWebImageTestDecoder encodedDataWithImage:format:]");
        }
        
        UIImage *diskCacheImage = [cache imageFromDiskCacheForKey:key];
        
        // Decoded result is JPEG
        NSString * decodedImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
        UIImage *testJPEGImage = [[UIImage alloc] initWithContentsOfFile:decodedImagePath];
        
        NSData *data1 = [testJPEGImage sd_imageDataAsFormat:SDImageFormatPNG];
        NSData *data2 = [diskCacheImage sd_imageDataAsFormat:SDImageFormatPNG];
        
        if (![data1 isEqualToData:data2]) {
            XCTFail(@"Custom decoder not work for SDImageCache, check -[SDWebImageTestDecoder decodedImageWithData:]");
        }
        
        [[SDImageCodersManager sharedManager] removeCoder:testDecoder];
        
        [[SDImageCache sharedImageCache] removeImageForKey:key withCompletion:^{
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test41StoreImageDataToDiskWithCustomFileManager {
    NSData *imageData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    NSError *targetError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    
    SDMockFileManager *fileManager = [[SDMockFileManager alloc] init];
    fileManager.mockSelectors = @{NSStringFromSelector(@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)) : targetError};
    expect(fileManager.lastError).to.beNil();
    
    SDImageCacheConfig *config = [SDImageCacheConfig new];
    config.fileManager = fileManager;
    // This disk cache path creation will be mocked with error.
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:@"test" diskCacheDirectory:@"/" config:config];
    [cache storeImageDataToDisk:imageData
                         forKey:kTestImageKeyJPEG];
    expect(fileManager.lastError).equal(targetError);
}

- (void)test41MatchAnimatedImageClassWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"MatchAnimatedImageClass option should work"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:self.testGIFPath];
    
    NSString *kAnimatedImageKey = @"kAnimatedImageKey";
    
    // Store UIImage into cache
    [[SDImageCache sharedImageCache] storeImageToMemory:image forKey:kAnimatedImageKey];
    
    // `MatchAnimatedImageClass` will cause query failed because class does not match
    [SDImageCache.sharedImageCache queryCacheOperationForKey:kAnimatedImageKey options:SDImageCacheMatchAnimatedImageClass context:@{SDWebImageContextAnimatedImageClass : SDAnimatedImage.class} done:^(UIImage * _Nullable image1, NSData * _Nullable data1, SDImageCacheType cacheType1) {
        expect(image1).beNil();
        // This should query success with UIImage
        [SDImageCache.sharedImageCache queryCacheOperationForKey:kAnimatedImageKey options:0 context:@{SDWebImageContextAnimatedImageClass : SDAnimatedImage.class} done:^(UIImage * _Nullable image2, NSData * _Nullable data2, SDImageCacheType cacheType2) {
            expect(image2).notTo.beNil();
            expect(image2).equal(image);
            
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test42StoreCacheWithImageAndFormatWithoutImageData {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"StoreImage UIImage without sd_imageFormat should use PNG for alpha channel"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"StoreImage UIImage without sd_imageFormat should use JPEG for non-alpha channel"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"StoreImage UIImage/UIAnimatedImage with sd_imageFormat should use that format"];
    XCTestExpectation *expectation4 = [self expectationWithDescription:@"StoreImage SDAnimatedImage should use animatedImageData"];
    XCTestExpectation *expectation5 = [self expectationWithDescription:@"StoreImage UIAnimatedImage without sd_imageFormat should use GIF"];
    
    NSString *kAnimatedImageKey1 = @"kAnimatedImageKey1";
    NSString *kAnimatedImageKey2 = @"kAnimatedImageKey2";
    NSString *kAnimatedImageKey3 = @"kAnimatedImageKey3";
    NSString *kAnimatedImageKey4 = @"kAnimatedImageKey4";
    NSString *kAnimatedImageKey5 = @"kAnimatedImageKey5";
    
    // Case 1: UIImage without `sd_imageFormat` should use PNG for alpha channel
    NSData *pngData = [NSData dataWithContentsOfFile:[self testPNGPath]];
    UIImage *pngImage = [UIImage sd_imageWithData:pngData];
    expect(pngImage.sd_isAnimated).beFalsy();
    expect(pngImage.sd_imageFormat).equal(SDImageFormatPNG);
    // Remove sd_imageFormat
    pngImage.sd_imageFormat = SDImageFormatUndefined;
    // Check alpha channel
    expect([SDImageCoderHelper CGImageContainsAlpha:pngImage.CGImage]).beTruthy();
    
    [SDImageCache.sharedImageCache storeImage:pngImage forKey:kAnimatedImageKey1 toDisk:YES completion:^{
        UIImage *diskImage = [SDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey1];
        // Should save to PNG
        expect(diskImage.sd_isAnimated).beFalsy();
        expect(diskImage.sd_imageFormat).equal(SDImageFormatPNG);
        [expectation1 fulfill];
    }];
    
    // Case 2: UIImage without `sd_imageFormat` should use JPEG for non-alpha channel
    SDGraphicsImageRendererFormat *format = [SDGraphicsImageRendererFormat preferredFormat];
    format.opaque = YES;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:pngImage.size format:format];
    // Non-alpha image, also test `SDGraphicsImageRenderer` behavior here :)
    UIImage *nonAlphaImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        [pngImage drawInRect:CGRectMake(0, 0, pngImage.size.width, pngImage.size.height)];
    }];
    expect(nonAlphaImage).notTo.beNil();
    expect([SDImageCoderHelper CGImageContainsAlpha:nonAlphaImage.CGImage]).beFalsy();
    
    [SDImageCache.sharedImageCache storeImage:nonAlphaImage forKey:kAnimatedImageKey2 toDisk:YES completion:^{
        UIImage *diskImage = [SDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey2];
        // Should save to JPEG
        expect(diskImage.sd_isAnimated).beFalsy();
        expect(diskImage.sd_imageFormat).equal(SDImageFormatJPEG);
        [expectation2 fulfill];
    }];
    
    NSData *gifData = [NSData dataWithContentsOfFile:[self testGIFPath]];
    UIImage *gifImage = [UIImage sd_imageWithData:gifData]; // UIAnimatedImage
    expect(gifImage.sd_isAnimated).beTruthy();
    expect(gifImage.sd_imageFormat).equal(SDImageFormatGIF);
    
    // Case 3: UIImage with `sd_imageFormat` should use that format
    [SDImageCache.sharedImageCache storeImage:gifImage forKey:kAnimatedImageKey3 toDisk:YES completion:^{
        UIImage *diskImage = [SDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey3];
        // Should save to GIF
        expect(diskImage.sd_isAnimated).beTruthy();
        expect(diskImage.sd_imageFormat).equal(SDImageFormatGIF);
        [expectation3 fulfill];
    }];
    
    // Case 4: SDAnimatedImage should use `animatedImageData`
    SDAnimatedImage *animatedImage = [SDAnimatedImage imageWithData:gifData];
    expect(animatedImage.animatedImageData).notTo.beNil();
    [SDImageCache.sharedImageCache storeImage:animatedImage forKey:kAnimatedImageKey4 toDisk:YES completion:^{
        NSData *data = [SDImageCache.sharedImageCache diskImageDataForKey:kAnimatedImageKey4];
        // Should save with animatedImageData
        expect(data).equal(animatedImage.animatedImageData);
        [expectation4 fulfill];
    }];
    
    // Case 5: UIAnimatedImage without sd_imageFormat should use GIF not APNG
    NSData *apngData = [NSData dataWithContentsOfFile:[self testAPNGPath]];
    UIImage *apngImage = [UIImage sd_imageWithData:apngData];
    expect(apngImage.sd_isAnimated).beTruthy();
    expect(apngImage.sd_imageFormat).equal(SDImageFormatPNG);
    // Remove sd_imageFormat
    apngImage.sd_imageFormat = SDImageFormatUndefined;
    
    [SDImageCache.sharedImageCache storeImage:apngImage forKey:kAnimatedImageKey5 toDisk:YES completion:^{
        UIImage *diskImage = [SDImageCache.sharedImageCache imageFromDiskCacheForKey:kAnimatedImageKey5];
        // Should save to GIF
        expect(diskImage.sd_isAnimated).beTruthy();
        expect(diskImage.sd_imageFormat).equal(SDImageFormatGIF);
        [expectation5 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - SDMemoryCache & SDDiskCache
- (void)test42CustomMemoryCache {
    SDImageCacheConfig *config = [[SDImageCacheConfig alloc] init];
    config.memoryCacheClass = [SDWebImageTestMemoryCache class];
    NSString *nameSpace = @"SDWebImageTestMemoryCache";
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:nameSpace diskCacheDirectory:nil config:config];
    SDWebImageTestMemoryCache *memCache = cache.memoryCache;
    expect([memCache isKindOfClass:[SDWebImageTestMemoryCache class]]).to.beTruthy();
}

- (void)test43CustomDiskCache {
    SDImageCacheConfig *config = [[SDImageCacheConfig alloc] init];
    config.diskCacheClass = [SDWebImageTestDiskCache class];
    NSString *nameSpace = @"SDWebImageTestDiskCache";
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:nameSpace diskCacheDirectory:nil config:config];
    SDWebImageTestDiskCache *diskCache = cache.diskCache;
    expect([diskCache isKindOfClass:[SDWebImageTestDiskCache class]]).to.beTruthy();
}

- (void)test44DiskCacheMigrationFromOldVersion {
    SDImageCacheConfig *config = [[SDImageCacheConfig alloc] init];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    config.fileManager = fileManager;
    
    // Fake to store a.png into old path
    NSString *newDefaultPath = [[[self userCacheDirectory] stringByAppendingPathComponent:@"com.hackemist.SDImageCache"] stringByAppendingPathComponent:@"default"];
    NSString *oldDefaultPath = [[[self userCacheDirectory] stringByAppendingPathComponent:@"default"] stringByAppendingPathComponent:@"com.hackemist.SDWebImageCache.default"];
    [fileManager createDirectoryAtPath:oldDefaultPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createFileAtPath:[oldDefaultPath stringByAppendingPathComponent:@"a.png"] contents:[NSData dataWithContentsOfFile:[self testPNGPath]] attributes:nil];
    // Call migration
    SDDiskCache *diskCache = [[SDDiskCache alloc] initWithCachePath:newDefaultPath config:config];
    [diskCache moveCacheDirectoryFromPath:oldDefaultPath toPath:newDefaultPath];
    
    // Expect a.png into new path
    BOOL exist = [fileManager fileExistsAtPath:[newDefaultPath stringByAppendingPathComponent:@"a.png"]];
    expect(exist).beTruthy();
}

- (void)test45DiskCacheRemoveExpiredData {
    NSString *cachePath = [[self userCacheDirectory] stringByAppendingPathComponent:@"disk"];
    SDImageCacheConfig *config = SDImageCacheConfig.defaultCacheConfig;
    config.maxDiskAge = 1; // 1 second
    config.maxDiskSize = 10; // 10 KB
    SDDiskCache *diskCache = [[SDDiskCache alloc] initWithCachePath:cachePath config:config];
    [diskCache removeAllData];
    expect(diskCache.totalSize).equal(0);
    expect(diskCache.totalCount).equal(0);
    // 20KB -> maxDiskSize
    NSUInteger length = 20;
    void *bytes = malloc(length);
    NSData *data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    [diskCache setData:data forKey:@"20KB"];
    expect(diskCache.totalSize).equal(length);
    expect(diskCache.totalCount).equal(1);
    [diskCache removeExpiredData];
    expect(diskCache.totalSize).equal(0);
    expect(diskCache.totalCount).equal(0);
    // 1KB with 5s -> maxDiskAge
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDDiskCache removeExpireData timeout"];
    length = 1;
    bytes = malloc(length);
    data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    [diskCache setData:data forKey:@"1KB"];
    expect(diskCache.totalSize).equal(length);
    expect(diskCache.totalCount).equal(1);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [diskCache removeExpiredData];
        expect(diskCache.totalSize).equal(0);
        expect(diskCache.totalCount).equal(0);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#if SD_UIKIT
- (void)test46MemoryCacheWeakCache {
    SDMemoryCache *memoryCache = [[SDMemoryCache alloc] init];
    memoryCache.config.shouldUseWeakMemoryCache = NO;
    memoryCache.config.maxMemoryCost = 10;
    memoryCache.config.maxMemoryCount = 5;
    expect(memoryCache.countLimit).equal(5);
    expect(memoryCache.totalCostLimit).equal(10);
    // Don't use weak cache
    NSObject *object = [NSObject new];
    [memoryCache setObject:object forKey:@"1"];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    NSObject *cachedObject = [memoryCache objectForKey:@"1"];
    expect(cachedObject).beNil();
    // Use weak cache
    memoryCache.config.shouldUseWeakMemoryCache = YES;
    object = [NSObject new];
    [memoryCache setObject:object forKey:@"1"];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    cachedObject = [memoryCache objectForKey:@"1"];
    expect(object).equal(cachedObject);
}
#endif

- (void)test47DiskCacheExtendedData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCache extended data read/write works"];
    UIImage *image = [self testPNGImage];
    NSDictionary *extendedObject = @{@"Test" : @"Object"};
    image.sd_extendedObject = extendedObject;
    [SDImageCache.sharedImageCache removeImageFromMemoryForKey:kTestImageKeyPNG];
    [SDImageCache.sharedImageCache removeImageFromDiskForKey:kTestImageKeyPNG];
    // Write extended data
    [SDImageCache.sharedImageCache storeImage:image forKey:kTestImageKeyPNG completion:^{
        NSData *extendedData = [SDImageCache.sharedImageCache.diskCache extendedDataForKey:kTestImageKeyPNG];
        expect(extendedData).toNot.beNil();
        // Read extended data
        UIImage *newImage = [SDImageCache.sharedImageCache imageFromDiskCacheForKey:kTestImageKeyPNG];
        id newExtendedObject = newImage.sd_extendedObject;
        expect(extendedObject).equal(newExtendedObject);
        // Remove extended data
        [SDImageCache.sharedImageCache.diskCache setExtendedData:nil forKey:kTestImageKeyPNG];
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - SDImageCache & SDImageCachesManager
- (void)test50SDImageCacheQueryOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCache query op works"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG toDisk:NO completion:nil];
    [[SDImageCachesManager sharedManager] queryImageForKey:kTestImageKeyJPEG options:0 context:nil cacheType:SDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(image).notTo.beNil();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test51SDImageCacheStoreOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCache store op works"];
    [[SDImageCachesManager sharedManager] storeImage:[self testJPEGImage] imageData:nil forKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeAll completion:^{
        UIImage *image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(image).notTo.beNil();
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beTruthy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test52SDImageCacheRemoveOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCache remove op works"];
    [[SDImageCachesManager sharedManager] removeImageForKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeDisk completion:^{
        UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(memoryImage).notTo.beNil();
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beFalsy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test53SDImageCacheContainsOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCache contains op works"];
    [[SDImageCachesManager sharedManager] containsImageForKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeAll completion:^(SDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(SDImageCacheTypeMemory);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test54SDImageCacheClearOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCache clear op works"];
    [[SDImageCachesManager sharedManager] clearWithCacheType:SDImageCacheTypeAll completion:^{
        UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(memoryImage).to.beNil();
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beFalsy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test55SDImageCachesManagerOperationPolicySimple {
    SDImageCachesManager *cachesManager = [[SDImageCachesManager alloc] init];
    SDImageCache *cache1 = [[SDImageCache alloc] initWithNamespace:@"cache1"];
    SDImageCache *cache2 = [[SDImageCache alloc] initWithNamespace:@"cache2"];
    cachesManager.caches = @[cache1, cache2];
    
    [[NSFileManager defaultManager] removeItemAtPath:cache1.diskCachePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:cache2.diskCachePath error:nil];
    
    // LowestOnly
    cachesManager.queryOperationPolicy = SDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.storeOperationPolicy = SDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.removeOperationPolicy = SDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.containsOperationPolicy = SDImageCachesManagerOperationPolicyLowestOnly;
    cachesManager.clearOperationPolicy = SDImageCachesManagerOperationPolicyLowestOnly;
    [cachesManager queryImageForKey:kTestImageKeyJPEG options:0 context:nil cacheType:SDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(image).to.beNil();
    }];
    [cachesManager storeImage:[self testJPEGImage] imageData:nil forKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeMemory completion:nil];
    // Check Logic works, cache1 only
    UIImage *memoryImage1 = [cache1 imageFromMemoryCacheForKey:kTestImageKeyJPEG];
    expect(memoryImage1).equal([self testJPEGImage]);
    [cachesManager containsImageForKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeMemory completion:^(SDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(SDImageCacheTypeMemory);
    }];
    [cachesManager removeImageForKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:SDImageCacheTypeMemory completion:nil];
    
    // HighestOnly
    cachesManager.queryOperationPolicy = SDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.storeOperationPolicy = SDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.removeOperationPolicy = SDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.containsOperationPolicy = SDImageCachesManagerOperationPolicyHighestOnly;
    cachesManager.clearOperationPolicy = SDImageCachesManagerOperationPolicyHighestOnly;
    [cachesManager queryImageForKey:kTestImageKeyPNG options:0 context:nil cacheType:SDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(image).to.beNil();
    }];
    [cachesManager storeImage:[self testPNGImage] imageData:nil forKey:kTestImageKeyPNG cacheType:SDImageCacheTypeMemory completion:nil];
    // Check Logic works, cache2 only
    UIImage *memoryImage2 = [cache2 imageFromMemoryCacheForKey:kTestImageKeyPNG];
    expect(memoryImage2).equal([self testPNGImage]);
    [cachesManager containsImageForKey:kTestImageKeyPNG cacheType:SDImageCacheTypeMemory completion:^(SDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(SDImageCacheTypeMemory);
    }];
    [cachesManager removeImageForKey:kTestImageKeyPNG cacheType:SDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:SDImageCacheTypeMemory completion:nil];
}

- (void)test56SDImageCachesManagerOperationPolicyConcurrent {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCachesManager operation cocurrent policy works"];
    SDImageCachesManager *cachesManager = [[SDImageCachesManager alloc] init];
    SDImageCache *cache1 = [[SDImageCache alloc] initWithNamespace:@"cache1"];
    SDImageCache *cache2 = [[SDImageCache alloc] initWithNamespace:@"cache2"];
    cachesManager.caches = @[cache1, cache2];
    
    [[NSFileManager defaultManager] removeItemAtPath:cache1.diskCachePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:cache2.diskCachePath error:nil];
    
    NSString *kConcurrentTestImageKey = @"kConcurrentTestImageKey";
    
    // Cocurrent
    // Check all concurrent op
    cachesManager.queryOperationPolicy = SDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.storeOperationPolicy = SDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.removeOperationPolicy = SDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.containsOperationPolicy = SDImageCachesManagerOperationPolicyConcurrent;
    cachesManager.clearOperationPolicy = SDImageCachesManagerOperationPolicyConcurrent;
    [cachesManager queryImageForKey:kConcurrentTestImageKey options:0 context:nil cacheType:SDImageCacheTypeAll completion:nil];
    [cachesManager storeImage:[self testJPEGImage] imageData:nil forKey:kConcurrentTestImageKey cacheType:SDImageCacheTypeMemory completion:nil];
    [cachesManager removeImageForKey:kConcurrentTestImageKey cacheType:SDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:SDImageCacheTypeMemory completion:nil];
    
    // Check Logic works, check cache1(memory+JPEG) & cache2(disk+PNG) at the same time. Cache1(memory) is fast and hit.
    [cache1 storeImage:[self testJPEGImage] forKey:kConcurrentTestImageKey toDisk:NO completion:nil];
    [cache2 storeImage:[self testPNGImage] forKey:kConcurrentTestImageKey toDisk:YES completion:^{
        UIImage *memoryImage1 = [cache1 imageFromMemoryCacheForKey:kConcurrentTestImageKey];
        expect(memoryImage1).notTo.beNil();
        [cache2 removeImageFromMemoryForKey:kConcurrentTestImageKey];
        [cachesManager containsImageForKey:kConcurrentTestImageKey cacheType:SDImageCacheTypeAll completion:^(SDImageCacheType containsCacheType) {
            // Cache1 hit
            expect(containsCacheType).equal(SDImageCacheTypeMemory);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test57SDImageCachesManagerOperationPolicySerial {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDImageCachesManager operation serial policy works"];
    SDImageCachesManager *cachesManager = [[SDImageCachesManager alloc] init];
    SDImageCache *cache1 = [[SDImageCache alloc] initWithNamespace:@"cache1"];
    SDImageCache *cache2 = [[SDImageCache alloc] initWithNamespace:@"cache2"];
    cachesManager.caches = @[cache1, cache2];
    
    [[NSFileManager defaultManager] removeItemAtPath:cache1.diskCachePath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:cache2.diskCachePath error:nil];
    
    NSString *kSerialTestImageKey = @"kSerialTestImageKey";
    
    // Serial
    // Check all serial op
    cachesManager.queryOperationPolicy = SDImageCachesManagerOperationPolicySerial;
    cachesManager.storeOperationPolicy = SDImageCachesManagerOperationPolicySerial;
    cachesManager.removeOperationPolicy = SDImageCachesManagerOperationPolicySerial;
    cachesManager.containsOperationPolicy = SDImageCachesManagerOperationPolicySerial;
    cachesManager.clearOperationPolicy = SDImageCachesManagerOperationPolicySerial;
    [cachesManager queryImageForKey:kSerialTestImageKey options:0 context:nil cacheType:SDImageCacheTypeAll completion:nil];
    [cachesManager storeImage:[self testJPEGImage] imageData:nil forKey:kSerialTestImageKey cacheType:SDImageCacheTypeMemory completion:nil];
    [cachesManager removeImageForKey:kSerialTestImageKey cacheType:SDImageCacheTypeMemory completion:nil];
    [cachesManager clearWithCacheType:SDImageCacheTypeMemory completion:nil];
    
    // Check Logic work, from cache2(disk+PNG) -> cache1(memory+JPEG). Cache2(disk) is slow but hit.
    [cache1 storeImage:[self testJPEGImage] forKey:kSerialTestImageKey toDisk:NO completion:nil];
    [cache2 storeImage:[self testPNGImage] forKey:kSerialTestImageKey toDisk:YES completion:^{
        UIImage *memoryImage1 = [cache1 imageFromMemoryCacheForKey:kSerialTestImageKey];
        expect(memoryImage1).notTo.beNil();
        [cache2 removeImageFromMemoryForKey:kSerialTestImageKey];
        [cachesManager containsImageForKey:kSerialTestImageKey cacheType:SDImageCacheTypeAll completion:^(SDImageCacheType containsCacheType) {
            // Cache2 hit
            expect(containsCacheType).equal(SDImageCacheTypeDisk);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test58CustomImageCache {
    NSString *cachePath = [[self userCacheDirectory] stringByAppendingPathComponent:@"custom"];
    SDImageCacheConfig *config = [[SDImageCacheConfig alloc] init];
    SDWebImageTestCache *cache = [[SDWebImageTestCache alloc] initWithCachePath:cachePath config:config];
    expect(cache.memoryCache).notTo.beNil();
    expect(cache.diskCache).notTo.beNil();
    
    // Clear
    [cache clearWithCacheType:SDImageCacheTypeAll completion:nil];
    // Store
    UIImage *image1 = self.testJPEGImage;
    NSString *key1 = @"testJPEGImage";
    [cache storeImage:image1 imageData:nil forKey:key1 cacheType:SDImageCacheTypeAll completion:nil];
    // Contain
    [cache containsImageForKey:key1 cacheType:SDImageCacheTypeAll completion:^(SDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(SDImageCacheTypeMemory);
    }];
    // Query
    [cache queryImageForKey:key1 options:0 context:nil cacheType:SDImageCacheTypeAll completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(image).equal(image1);
        expect(data).beNil();
        expect(cacheType).equal(SDImageCacheTypeMemory);
    }];
    // Remove
    [cache removeImageForKey:key1 cacheType:SDImageCacheTypeAll completion:nil];
    // Contain
    [cache containsImageForKey:key1 cacheType:SDImageCacheTypeAll completion:^(SDImageCacheType containsCacheType) {
        expect(containsCacheType).equal(SDImageCacheTypeNone);
    }];
    // Clear
    [cache clearWithCacheType:SDImageCacheTypeAll completion:nil];
    NSArray<NSString *> *cacheFiles = [cache.diskCache.fileManager contentsOfDirectoryAtPath:cachePath error:nil];
    expect(cacheFiles.count).equal(0);
}

#pragma mark Helper methods

- (UIImage *)testJPEGImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        reusableImage = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    }
    return reusableImage;
}

- (UIImage *)testPNGImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        reusableImage = [[UIImage alloc] initWithContentsOfFile:[self testPNGPath]];
    }
    return reusableImage;
}

- (UIImage *)testGIFImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
        reusableImage = [UIImage sd_imageWithData:data];
    }
    return reusableImage;
}

- (UIImage *)testAPNGImage {
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        NSData *data = [NSData dataWithContentsOfFile:[self testAPNGPath]];
        reusableImage = [UIImage sd_imageWithData:data];
    }
    return reusableImage;
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (NSString *)testPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"png"];
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImage" ofType:@"gif"];
    return testPath;
}

- (NSString *)testAPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImageAnimated" ofType:@"apng"];
    return testPath;
}

- (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

@end
