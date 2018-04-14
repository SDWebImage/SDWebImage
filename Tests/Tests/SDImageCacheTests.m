/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/SDWebImageCodersManager.h>
#import "SDWebImageTestDecoder.h"
#import "SDMockFileManager.h"

NSString *kImageTestKey = @"TestImageKey.jpg";

@interface SDImageCacheTests : SDTestCase
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
    
    [[SDImageCache sharedImageCache] storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.equal([self imageForTesting]);
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
            if (!isInCache) {
                [[SDImageCache sharedImageCache] calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
                    expect(fileCount).to.equal(0);
                    [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
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
    
    [[SDImageCache sharedImageCache] storeImage:[self imageForTesting] forKey:kImageTestKey completion:^{
        [[SDImageCache sharedImageCache] clearMemory];
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
            if (isInCache) {
                [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
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
    
    UIImage *image = [self imageForTesting];
    [[SDImageCache sharedImageCache] storeImage:image forKey:kImageTestKey completion:nil];
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.equal(image);
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        if (isInCache) {
            [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
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
    
    UIImage *image = [self imageForTesting];
    [[SDImageCache sharedImageCache] storeImage:image forKey:kImageTestKey toDisk:YES completion:nil];
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.equal(image);
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        if (isInCache) {
            [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
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
    UIImage *image = [self imageForTesting];
    [[SDImageCache sharedImageCache] storeImage:image forKey:kImageTestKey toDisk:NO completion:nil];
    
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.equal([self imageForTesting]);
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        if (!isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should not be in cache");
        }
    }];
    [[SDImageCache sharedImageCache] clearMemory];
    expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.beNil();
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test09RetrieveImageThroughNSOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"queryCacheOperationForKey"];
    UIImage *imageForTesting = [self imageForTesting];
    [[SDImageCache sharedImageCache] storeImage:imageForTesting forKey:kImageTestKey completion:nil];
    NSOperation *operation = [[SDImageCache sharedImageCache] queryCacheOperationForKey:kImageTestKey done:^(UIImage *image, NSData *data, SDImageCacheType cacheType) {
        expect(image).to.equal(imageForTesting);
        [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
            [expectation fulfill];
        }];
    }];
    expect(operation).toNot.beNil;
    [operation start];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test10RemoveImageForKeyWithCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey"];
    [[SDImageCache sharedImageCache] storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test11RemoveImageforKeyNotFromDiskWithCompletion{
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey fromDisk:NO"];
    [[SDImageCache sharedImageCache] storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey fromDisk:NO withCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:kImageTestKey]).toNot.beNil;
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test12RemoveImageforKeyFromDiskWithCompletion{
    XCTestExpectation *expectation = [self expectationWithDescription:@"removeImageForKey fromDisk:YES"];
    [[SDImageCache sharedImageCache] storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey fromDisk:YES withCompletion:^{
        expect([[SDImageCache sharedImageCache] imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
        expect([[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test20InitialCacheSize{
    expect([[SDImageCache sharedImageCache] getSize]).to.equal(0);
}

- (void)test21InitialDiskCount{
    XCTestExpectation *expectation = [self expectationWithDescription:@"getDiskCount"];
    [[SDImageCache sharedImageCache] storeImage:[self imageForTesting] forKey:kImageTestKey completion:^{
        expect([[SDImageCache sharedImageCache] getDiskCount]).to.equal(1);
        [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test31CachePathForAnyKey{
    NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:kImageTestKey];
    expect(path).toNot.beNil;
}

- (void)test32CachePathForNilKey{
    NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:nil];
    expect(path).to.beNil;
}

- (void)test33CachePathForExistingKey{
    XCTestExpectation *expectation = [self expectationWithDescription:@"cachePathForKey inPath"];
    [[SDImageCache sharedImageCache] storeImage:[self imageForTesting] forKey:kImageTestKey completion:^{
        NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:kImageTestKey];
        expect(path).notTo.beNil;
        [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test34CachePathForSimpleKeyWithExtension {
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:kTestJpegURL];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"jpg");
}

- (void)test35CachePathForKeyWithDotButNoExtension {
    NSString *urlString = @"https://maps.googleapis.com/maps/api/staticmap?center=48.8566,2.3522&format=png&maptype=roadmap&scale=2&size=375x200&zoom=15";
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:urlString];
    expect(cachePath).toNot.beNil();
    expect([cachePath pathExtension]).to.equal(@"");
}

#if SD_UIKIT
- (void)test40InsertionOfImageData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Insertion of image data works"];
    
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[self testImagePath]];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [[SDImageCache sharedImageCache] storeImageDataToDisk:imageData forKey:kImageTestKey];
    
    UIImage *storedImageFromMemory = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kImageTestKey];
    expect(storedImageFromMemory).to.equal(nil);
    
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:kImageTestKey];
    UIImage *cachedImage = [[UIImage alloc] initWithContentsOfFile:cachePath];
    NSData *storedImageData = UIImageJPEGRepresentation(cachedImage, 1.0);
    expect(storedImageData.length).to.beGreaterThan(0);
    expect(cachedImage.size).to.equal(image.size);
    // can't directly compare image and cachedImage because apparently there are some slight differences, even though the image is the same
    
    [[SDImageCache sharedImageCache] diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(YES);
        
        [[SDImageCache sharedImageCache] removeImageForKey:kImageTestKey withCompletion:^{
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test41ThatCustomDecoderWorksForImageCache {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom decoder for SDImageCache not works"];
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:@"TestDecode"];
    SDWebImageTestDecoder *testDecoder = [[SDWebImageTestDecoder alloc] init];
    [[SDWebImageCodersManager sharedManager] addCoder:testDecoder];
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
        
        NSData *data1 = UIImagePNGRepresentation(testJPEGImage);
        NSData *data2 = UIImagePNGRepresentation(diskCacheImage);
        
        if (![data1 isEqualToData:data2]) {
            XCTFail(@"Custom decoder not work for SDImageCache, check -[SDWebImageTestDecoder decodedImageWithData:]");
        }
        
        [[SDWebImageCodersManager sharedManager] removeCoder:testDecoder];
        
        [[SDImageCache sharedImageCache] removeImageForKey:key withCompletion:^{
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}
#endif

- (void)test41StoreImageDataToDiskWithCustomFileManager {
    NSData *imageData = [NSData dataWithContentsOfFile:[self testImagePath]];
    NSError *targetError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    
    SDMockFileManager *fileManager = [[SDMockFileManager alloc] init];
    fileManager.mockSelectors = @{NSStringFromSelector(@selector(createDirectoryAtPath:withIntermediateDirectories:attributes:error:)) : targetError};
    expect(fileManager.lastError).to.beNil();
    
    SDImageCacheConfig *config = [SDImageCacheConfig new];
    config.fileManager = fileManager;
    // This disk cache path creation will be mocked with error.
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:@"test" diskCacheDirectory:@"/" config:config];
    [cache storeImageDataToDisk:imageData
                         forKey:kImageTestKey];
    expect(fileManager.lastError).equal(targetError);
}

#pragma mark Helper methods

- (UIImage *)imageForTesting{
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        reusableImage = [[UIImage alloc] initWithContentsOfFile:[self testImagePath]];
    }
    return reusableImage;
}

- (NSString *)testImagePath {
    
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

@end
