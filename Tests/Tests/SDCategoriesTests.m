/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#if SD_UIKIT
#import <MobileCoreServices/MobileCoreServices.h>
#endif

@interface SDCategoriesTests : SDTestCase

@end

@implementation SDCategoriesTests

- (void)test01NSDataImageContentTypeCategory {
    // Test invalid image data
    SDImageFormat format = [NSData sd_imageFormatForImageData:nil];
    expect(format == SDImageFormatUndefined);
    
    // Test invalid format
    CFStringRef type = [NSData sd_UTTypeFromImageFormat:SDImageFormatUndefined];
    expect(CFStringCompare(kUTTypePNG, type, 0)).equal(kCFCompareEqualTo);
}

- (void)test02UIImageMultiFormatCategory {
    // Test invalid image data
    UIImage *image = [UIImage sd_imageWithData:nil];
    expect(image).to.beNil();
    // Test image encode
    image = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSData *data = [image sd_imageData];
    expect(data).notTo.beNil();
    // Test image encode PNG
    data = [image sd_imageDataAsFormat:SDImageFormatPNG];
    expect(data).notTo.beNil();
}

- (void)test03UIImageGIFCategory {
    // Test invalid image data
    UIImage *image = [UIImage sd_imageWithGIFData:nil];
    expect(image).to.beNil();
    // Test valid image data
    NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
    image = [UIImage sd_imageWithGIFData:data];
    expect(image).notTo.beNil();
}

#pragma mark - Helper

<<<<<<< HEAD
- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
=======
- (void)testUIButtonSetImageWithURLHighlightedState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL highlightedState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [button sd_setImageWithURL:originalImageURL
                      forState:UIControlStateHighlighted
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect([button imageForState:UIControlStateHighlighted]).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIButtonSetBackgroundImageWithURLNormalState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setBackgroundImageWithURL normalState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [button sd_setBackgroundImageWithURL:originalImageURL
                                forState:UIControlStateNormal
                               completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                   expect(image).toNot.beNil();
                                   expect(error).to.beNil();
                                   expect(originalImageURL).to.equal(imageURL);
                                   expect([button backgroundImageForState:UIControlStateNormal]).to.equal(image);
                                   [expectation fulfill];
                               }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testFLAnimatedImageViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"FLAnimatedImageView setImageWithURL"];
    
    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestGIFURL];
    
    [imageView sd_setImageWithURL:originalImageURL
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            expect(image).toNot.beNil();
                            expect(error).to.beNil();
                            expect(originalImageURL).to.equal(imageURL);
                            
                            expect(imageView.animatedImage).toNot.beNil();
                            [expectation fulfill];
                                }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testFLAnimatedImageViewSetImageWithPlaceholderFromCacheForSameURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"FLAnimatedImageView set image with a placeholder which is the same as the cached image for same url"];
    /**
     This is a really rare case. Some of user, who query the cache key for one GIF url and get the placeholder
     Then use the placeholder and trigger a query for same url, because it will hit memory cache immediately, so the two `setImageBlock` call will have the same image instance and hard to distinguish. (Because we should not do async disk cache check for placeholder)
     */
    
    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"http://assets.sbnation.com/assets/2512203/dogflops.gif"];
    NSString *key = [SDWebImageManager.sharedManager cacheKeyForURL:originalImageURL];
    
    [SDWebImageManager.sharedManager loadImageWithURL:originalImageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
        
        UIImage *cachedImage = [SDImageCache.sharedImageCache imageFromCacheForKey:key];
        expect(cachedImage).toNot.beNil(); // Should be stored
        cachedImage.sd_FLAnimatedImage = nil; // Cleanup the associated FLAnimatedImage instance
        
        [imageView sd_setImageWithURL:originalImageURL
                     placeholderImage:cachedImage
                            completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                expect(image).to.equal(cachedImage); // should hit the cache and it's the same as placeholder
                                expect(imageView.animatedImage).toNot.beNil();
                                [expectation fulfill];
                            }];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewImageProgressKVOWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView imageProgressKVO failed"];
    UIView *view = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    
    [view.sd_imageProgress addObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew context:SDCategoriesTestsContext];
    
    // Clear the disk cache to force download from network
    [[SDImageCache sharedImageCache] removeImageForKey:kTestJpegURL withCompletion:^{
        [view sd_internalSetImageWithURL:originalImageURL placeholderImage:nil options:0 operationKey:nil setImageBlock:nil progress:nil completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            expect(view.sd_imageProgress.fractionCompleted).equal(1.0);
            expect([view.sd_imageProgress.userInfo[NSStringFromSelector(_cmd)] boolValue]).equal(YES);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:^(NSError * _Nullable error) {
        [view.sd_imageProgress removeObserver:self forKeyPath:NSStringFromSelector(@selector(fractionCompleted)) context:SDCategoriesTestsContext];
    }];
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"gif"];
}

@end
