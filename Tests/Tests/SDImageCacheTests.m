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
#import <SDWebImage/SDWebImageCachesManager.h>
#import "SDWebImageTestDecoder.h"
#import "SDMockFileManager.h"
#import "SDWebImageTestCache.h"

static NSString *kTestImageKeyJPEG = @"TestImageKey.jpg";
static NSString *kTestImageKeyPNG = @"TestImageKey.png";

@interface SDImageCache ()

@property (nonatomic, strong, nonnull) id<SDMemoryCache> memCache;
@property (nonatomic, strong, nonnull) id<SDDiskCache> diskCache;

@end

@interface SDImageCacheTests : SDTestCase <NSFileManagerDelegate>

@end

@implementation SDImageCacheTests

+ (void)setUp {
    [[SDWebImageCachesManager sharedManager] addCache:[SDImageCache sharedImageCache]];
}

+ (void)tearDown {
    [[SDWebImageCachesManager sharedManager] removeCache:[SDImageCache sharedImageCache]];
}

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

- (void)test20InitialCacheSize{
    expect([[SDImageCache sharedImageCache] getSize]).to.equal(0);
}

- (void)test21InitialDiskCount{
    XCTestExpectation *expectation = [self expectationWithDescription:@"getDiskCount"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG completion:^{
        expect([[SDImageCache sharedImageCache] getDiskCount]).to.equal(1);
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
    NSString *path = [[SDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
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
    
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    [[SDImageCache sharedImageCache] storeImageDataToDisk:imageData forKey:kTestImageKeyJPEG];
    
    UIImage *storedImageFromMemory = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
    expect(storedImageFromMemory).to.equal(nil);
    
    NSString *cachePath = [[SDImageCache sharedImageCache] cachePathForKey:kTestImageKeyJPEG];
    UIImage *cachedImage = [[UIImage alloc] initWithContentsOfFile:cachePath];
    NSData *storedImageData = UIImageJPEGRepresentation(cachedImage, 1.0);
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
    NSData *imageData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    NSError *targetError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
    
    SDMockFileManager *fileManager = [[SDMockFileManager alloc] init];
    fileManager.delegate = self;
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

#pragma mark - SDMemoryCache & SDDiskCache
- (void)test42CustomMemoryCache {
    SDImageCacheConfig *config = [[SDImageCacheConfig alloc] init];
    config.memoryCacheClass = [SDWebImageTestMemoryCache class];
    NSString *nameSpace = @"SDWebImageTestMemoryCache";
    NSString *cacheDictionary = [self makeDiskCachePath:nameSpace];
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:nameSpace diskCacheDirectory:cacheDictionary config:config];
    SDWebImageTestMemoryCache *memCache = cache.memCache;
    expect([memCache isKindOfClass:[SDWebImageTestMemoryCache class]]).to.beTruthy();
}

- (void)test43CustomDiskCache {
    SDImageCacheConfig *config = [[SDImageCacheConfig alloc] init];
    config.diskCacheClass = [SDWebImageTestDiskCache class];
    NSString *nameSpace = @"SDWebImageTestDiskCache";
    NSString *cacheDictionary = [self makeDiskCachePath:nameSpace];
    SDImageCache *cache = [[SDImageCache alloc] initWithNamespace:nameSpace diskCacheDirectory:cacheDictionary config:config];
    SDWebImageTestDiskCache *diskCache = cache.diskCache;
    expect([diskCache isKindOfClass:[SDWebImageTestDiskCache class]]).to.beTruthy();
}

#pragma mark - SDWebImageCache & SDWebImageCachesManager
- (void)test50SDWebImageCacheQueryOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageCache query op works"];
    [[SDImageCache sharedImageCache] storeImage:[self testJPEGImage] forKey:kTestImageKeyJPEG toDisk:NO completion:nil];
    [[SDWebImageCachesManager sharedManager] queryImageForKey:kTestImageKeyJPEG options:0 context:nil completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        expect(image).notTo.beNil();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test51SDWebImageCacheStoreOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageCache store op works"];
    [[SDWebImageCachesManager sharedManager] storeImage:[self testJPEGImage] imageData:nil forKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeBoth completion:^{
        UIImage *image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(image).notTo.beNil();
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beTruthy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test52SDWebImageCacheRemoveOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageCache remove op works"];
    [[SDWebImageCachesManager sharedManager] removeImageForKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeDisk completion:^{
        UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(memoryImage).notTo.beNil();
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beFalsy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test53SDWebImageCacheContainsOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageCache contains op works"];
    [[SDWebImageCachesManager sharedManager] containsImageForKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeBoth completion:^(SDImageCacheType containsCacheType) {
        expect(containsCacheType == SDImageCacheTypeMemory).to.beTruthy();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test54SDWebImageCacheClearOp {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageCache clear op works"];
    [[SDWebImageCachesManager sharedManager] clearWithCacheType:SDImageCacheTypeBoth completion:^{
        UIImage *memoryImage = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:kTestImageKeyJPEG];
        expect(memoryImage).to.beNil();
        [[SDImageCache sharedImageCache] diskImageExistsWithKey:kTestImageKeyJPEG completion:^(BOOL isInCache) {
            expect(isInCache).to.beFalsy();
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test55SDWebImageCachesManagerOperationPolicy {
    XCTestExpectation *expectation = [self expectationWithDescription:@"SDWebImageCachesManager operation policy works"];
    SDWebImageCachesManager *cachesManager = [[SDWebImageCachesManager alloc] init];
    SDImageCache *cache1 = [[SDImageCache alloc] initWithNamespace:@"cache1"];
    SDImageCache *cache2 = [[SDImageCache alloc] initWithNamespace:@"cache2"];
    [cachesManager addCache:cache1];
    [cachesManager addCache:cache2];
    
    // LowestOnly
    cachesManager.storeOperationPolicy = SDWebImageCachesManagerOperationPolicyLowestOnly;
    [cachesManager storeImage:[self testJPEGImage] imageData:nil forKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeMemory completion:nil];
    UIImage *memoryImage1 = [cache1 imageFromMemoryCacheForKey:kTestImageKeyJPEG];
    expect(memoryImage1).equal([self testJPEGImage]);
    
    // HighestOnly
    cachesManager.storeOperationPolicy = SDWebImageCachesManagerOperationPolicyHighestOnly;
    [cachesManager storeImage:[self testPNGImage] imageData:nil forKey:kTestImageKeyPNG cacheType:SDImageCacheTypeMemory completion:nil];
    UIImage *memoryImage2 = [cache2 imageFromMemoryCacheForKey:kTestImageKeyPNG];
    expect(memoryImage2).equal([self testPNGImage]);
    
    // Cocurrent
    // Check with contains op
    cachesManager.containsOperationPolicy = SDWebImageCachesManagerOperationPolicyConcurrent;
    [cachesManager containsImageForKey:kTestImageKeyJPEG cacheType:SDImageCacheTypeMemory completion:^(SDImageCacheType containsCacheType) {
        expect(containsCacheType == SDImageCacheTypeMemory).to.beTruthy();
    }];
    [cache1 clearMemory];
    [cache2 clearMemory];
    
    // Serial
    // Check with contains op, which can provide `containsCacheType` represent order
    cachesManager.containsOperationPolicy = SDWebImageCachesManagerOperationPolicySerial;
    NSString *sameTestImageKey = @"sameTestImageKey";
    [cache1 storeImage:[self testJPEGImage] forKey:sameTestImageKey toDisk:NO completion:nil];
    [cache2 storeImage:[self testPNGImage] forKey:sameTestImageKey toDisk:YES completion:^{
        [cachesManager containsImageForKey:sameTestImageKey cacheType:SDImageCacheTypeBoth completion:^(SDImageCacheType containsCacheType) {
            // Cache2 hit first
            expect(containsCacheType == SDImageCacheTypeBoth);
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
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

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (NSString *)testPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"png"];
}

- (nullable NSString *)makeDiskCachePath:(nonnull NSString*)fullNamespace {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:fullNamespace];
}

@end
