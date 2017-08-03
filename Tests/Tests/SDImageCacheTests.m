/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <SDWebImage/SDImageCache.h>

NSString *kImageTestKey = @"TestImageKey.jpg";

@interface SDImageCacheTests : SDTestCase
@property (strong, nonatomic) SDImageCache *sharedImageCache;
@end

@implementation SDImageCacheTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.sharedImageCache = [SDImageCache sharedImageCache];
    [self clearAllCaches];
}

- (void)test01SharedImageCache {
    expect(self.sharedImageCache).toNot.beNil();
}

- (void)test02Singleton{
    expect(self.sharedImageCache).to.equal([SDImageCache sharedImageCache]);
}

- (void)test03ImageCacheCanBeInstantiated {
    SDImageCache *imageCache = [[SDImageCache alloc] init];
    expect(imageCache).toNot.equal([SDImageCache sharedImageCache]);
}

- (void)test04ClearDiskCache{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear disk cache"];
    
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [self.sharedImageCache clearDiskOnCompletion:^{
        [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
            if (!isInCache) {
                [expectation fulfill];
            } else {
                XCTFail(@"Image should not be in cache");
            }
        }];
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.equal([self imageForTesting]);
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test05ClearMemoryCache{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Clear memory cache"];
    
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [self.sharedImageCache clearMemory];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        if (isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:
- (void)test06InsertionOfImage {
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey"];
    
    UIImage *image = [self imageForTesting];
    [self.sharedImageCache storeImage:image forKey:kImageTestKey completion:nil];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.equal(image);
    [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        if (isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should be in cache");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

// Testing storeImage:forKey:toDisk:YES
- (void)test07InsertionOfImageForcingDiskStorage{
    XCTestExpectation *expectation = [self expectationWithDescription:@"storeImage forKey toDisk=YES"];
    
    UIImage *image = [self imageForTesting];
    [self.sharedImageCache storeImage:image forKey:kImageTestKey toDisk:YES completion:nil];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.equal(image);
    [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        if (isInCache) {
            [expectation fulfill];
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
    [self.sharedImageCache storeImage:image forKey:kImageTestKey toDisk:NO completion:nil];
    
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.equal([self imageForTesting]);
    [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        if (!isInCache) {
            [expectation fulfill];
        } else {
            XCTFail(@"Image should not be in cache");
        }
    }];
    [self.sharedImageCache clearMemory];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil();
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test09RetrieveImageThroughNSOperation{
    //- (NSOperation *)queryCacheOperationForKey:(NSString *)key done:(SDWebImageQueryCompletedBlock)doneBlock;
    UIImage *imageForTesting = [self imageForTesting];
    [self.sharedImageCache storeImage:imageForTesting forKey:kImageTestKey completion:nil];
    NSOperation *operation = [self.sharedImageCache queryCacheOperationForKey:kImageTestKey done:^(UIImage *image, NSData *data, SDImageCacheType cacheType) {
        expect(image).to.equal(imageForTesting);
    }];
    expect(operation).toNot.beNil;
}

- (void)test10RemoveImageForKeyWithCompletion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [self.sharedImageCache removeImageForKey:kImageTestKey withCompletion:^{
        expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    }];
}

- (void)test11RemoveImageforKeyNotFromDiskWithCompletion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [self.sharedImageCache removeImageForKey:kImageTestKey fromDisk:NO withCompletion:^{
        expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).toNot.beNil;
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    }];
}

- (void)test12RemoveImageforKeyFromDiskWithCompletion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    [self.sharedImageCache removeImageForKey:kImageTestKey fromDisk:YES withCompletion:^{
        expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    }];
}

- (void)test20InitialCacheSize{
    expect([self.sharedImageCache getSize]).to.equal(0);
}

- (void)test21InitialDiskCount{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    expect([self.sharedImageCache getDiskCount]).to.equal(1);
}

- (void)test22DiskCountAfterInsertion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    expect([self.sharedImageCache getDiskCount]).to.equal(1);
}

- (void)test31DefaultCachePathForAnyKey{
    NSString *path = [self.sharedImageCache defaultCachePathForKey:kImageTestKey];
    expect(path).toNot.beNil;
}

- (void)test32CachePathForNonExistingKey{
    NSString *path = [self.sharedImageCache cachePathForKey:kImageTestKey inPath:[self.sharedImageCache defaultCachePathForKey:kImageTestKey]];
    expect(path).to.beNil;
}

- (void)test33CachePathForExistingKey{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey completion:nil];
    NSString *path = [self.sharedImageCache cachePathForKey:kImageTestKey inPath:[self.sharedImageCache defaultCachePathForKey:kImageTestKey]];
    expect(path).notTo.beNil;
}

// TODO -- Testing image data insertion

- (void)test40InsertionOfImageData {
    
    NSData *imageData = [NSData dataWithContentsOfFile:[self testImagePath]];
    [self.sharedImageCache storeImageDataToDisk:imageData forKey:kImageTestKey];
    
    UIImage *storedImageFromMemory = [self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey];
    expect(storedImageFromMemory).to.equal(nil);
    
    NSString *cachePath = [self.sharedImageCache defaultCachePathForKey:kImageTestKey];
    NSData *storedImageData = [NSData dataWithContentsOfFile:cachePath];
    expect([storedImageData isEqualToData:imageData]).will.beTruthy;
    
    [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(YES);
    }];
    
    [self.sharedImageCache calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        expect(fileCount).to.beLessThan(100);
    }];
}

#pragma mark Helper methods

- (void)clearAllCaches{
    [self.sharedImageCache deleteOldFilesWithCompletionBlock:nil];
    
    // TODO: this is not ok, clearDiskOnCompletion will clear async, this means that when we execute the tests, the cache might not be cleared
    [self.sharedImageCache clearDiskOnCompletion:nil];
    [self.sharedImageCache clearMemory];
}

- (UIImage *)imageForTesting{
    static UIImage *reusableImage = nil;
    if (!reusableImage) {
        reusableImage = [UIImage imageWithContentsOfFile:[self testImagePath]];
    }
    return reusableImage;
}

- (NSString *)testImagePath {
    
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

@end
