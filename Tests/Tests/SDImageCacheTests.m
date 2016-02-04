//
//  SDImageCacheTests.m
//  SDWebImage Tests
//
//  Created by Bogdan Poplauschi on 20/06/14.
//
//

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <Expecta.h>

#import "SDImageCache.h"

NSString *kImageTestKey = @"TestImageKey.jpg";

@interface SDImageCacheTests : XCTestCase
@property (strong, nonatomic) SDImageCache *sharedImageCache;
@end

@implementation SDImageCacheTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.sharedImageCache = [SDImageCache sharedImageCache];
    [self clearAllCaches];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSharedImageCache {
    expect(self.sharedImageCache).toNot.beNil();
}

- (void)testSingleton{
    expect(self.sharedImageCache).to.equal([SDImageCache sharedImageCache]);
}

- (void)testClearDiskCache{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache clearDiskOnCompletion:^{
        expect([self.sharedImageCache diskImageExistsWithKey:kImageTestKey]).to.equal(NO);
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.equal([self imageForTesting]);
    }];
}

- (void)testClearMemoryCache{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache clearMemory];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    // Seems not able to access the files correctly (maybe only from test?)
    //expect([self.sharedImageCache diskImageExistsWithKey:kImageTestKey]).to.equal(YES);
    [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(YES);
    }];
}

// Testing storeImage:forKey:
- (void)testInsertionOfImage {
    UIImage *image = [self imageForTesting];
    [self.sharedImageCache storeImage:image forKey:kImageTestKey];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.equal(image);
    expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).to.equal(image);
}

// Testing storeImage:forKey:toDisk:YES
- (void)testInsertionOfImageForcingDiskStorage{
    UIImage *image = [self imageForTesting];
    [self.sharedImageCache storeImage:image forKey:kImageTestKey toDisk:YES];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.equal(image);
    // Seems not able to access the files correctly (maybe only from test?)
    //expect([self.sharedImageCache diskImageExistsWithKey:kImageTestKey]).to.equal(YES);
    [self.sharedImageCache diskImageExistsWithKey:kImageTestKey completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(YES);
    }];
}

// Testing storeImage:forKey:toDisk:NO
- (void)testInsertionOfImageOnlyInMemory {
    UIImage *image = [self imageForTesting];
    [self.sharedImageCache storeImage:image forKey:@"TestImage" toDisk:NO];
    [self.sharedImageCache diskImageExistsWithKey:@"TestImage" completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(YES);
    }];
    [self.sharedImageCache clearMemory];
    [self.sharedImageCache diskImageExistsWithKey:@"TestImage" completion:^(BOOL isInCache) {
        expect(isInCache).to.equal(NO);
    }];
}

- (void)testRetrievalImageThroughNSOperation{
    //- (NSOperation *)queryDiskCacheForKey:(NSString *)key done:(SDWebImageQueryCompletedBlock)doneBlock;
    UIImage *imageForTesting = [self imageForTesting];
    [self.sharedImageCache storeImage:imageForTesting forKey:kImageTestKey];
    NSOperation *operation = [self.sharedImageCache queryDiskCacheForKey:kImageTestKey done:^(UIImage *image, SDImageCacheType cacheType) {
        expect(image).to.equal(imageForTesting);
    }];
    expect(operation).toNot.beNil;
}

- (void)testRemoveImageForKey{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache removeImageForKey:kImageTestKey];
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
}

- (void)testRemoveImageForKeyWithCompletion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache removeImageForKey:kImageTestKey withCompletion:^{
        expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    }];
}

- (void)testRemoveImageForKeyNotFromDisk{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache removeImageForKey:kImageTestKey fromDisk:NO];
    expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).toNot.beNil;
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
}

- (void)testRemoveImageForKeyFromDisk{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache removeImageForKey:kImageTestKey fromDisk:NO];
    expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
    expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
}

- (void)testRemoveImageforKeyNotFromDiskWithCompletion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache removeImageForKey:kImageTestKey fromDisk:NO withCompletion:^{
        expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).toNot.beNil;
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    }];
}

- (void)testRemoveImageforKeyFromDiskWithCompletion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    [self.sharedImageCache removeImageForKey:kImageTestKey fromDisk:YES withCompletion:^{
        expect([self.sharedImageCache imageFromDiskCacheForKey:kImageTestKey]).to.beNil;
        expect([self.sharedImageCache imageFromMemoryCacheForKey:kImageTestKey]).to.beNil;
    }];
}

// TODO -- Testing insertion with recalculate
- (void)testInsertionOfImageOnlyInDisk {
}

- (void)testInitialCacheSize{
    expect([self.sharedImageCache getSize]).to.equal(0);
}

- (void)testInitialDiskCount{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    expect([self.sharedImageCache getDiskCount]).to.equal(1);
}

- (void)testDiskCountAfterInsertion{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    expect([self.sharedImageCache getDiskCount]).to.equal(1);
}

- (void)testDefaultCachePathForAnyKey{
    NSString *path = [self.sharedImageCache defaultCachePathForKey:kImageTestKey];
    expect(path).toNot.beNil;
}

- (void)testCachePathForNonExistingKey{
    NSString *path = [self.sharedImageCache cachePathForKey:kImageTestKey inPath:[self.sharedImageCache defaultCachePathForKey:kImageTestKey]];
    expect(path).to.beNil;
}

- (void)testCachePathForExistingKey{
    [self.sharedImageCache storeImage:[self imageForTesting] forKey:kImageTestKey];
    NSString *path = [self.sharedImageCache cachePathForKey:kImageTestKey inPath:[self.sharedImageCache defaultCachePathForKey:kImageTestKey]];
    expect(path).notTo.beNil;
}

// TODO -- Testing image data insertion

- (void)testInsertionOfImageData {
    
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
}

#pragma mark Helper methods

- (void)clearAllCaches{
    [self.sharedImageCache clearDisk];
    [self.sharedImageCache clearMemory];
}

- (UIImage *)imageForTesting{
    
    return [UIImage imageWithContentsOfFile:[self testImagePath]];
}

- (NSString *)testImagePath {
    
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

@end
