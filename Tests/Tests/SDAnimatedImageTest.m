/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <KVOController/KVOController.h>

static const NSUInteger kTestGIFFrameCount = 5; // local TestImage.gif loop count

// Internal header
@interface SDAnimatedImageView ()

@property (nonatomic, assign) BOOL isProgressive;

@end

@interface SDAnimatedImageTest : SDTestCase

@property (nonatomic, strong) UIWindow *window;

@end

@implementation SDAnimatedImageTest

- (void)tearDown {
    [[SDImageCache sharedImageCache] removeImageForKey:kTestGIFURL fromDisk:YES withCompletion:nil];
}

- (void)test01AnimatedImageInitWithData {
    NSData *invalidData = [@"invalid data" dataUsingEncoding:NSUTF8StringEncoding];
    SDAnimatedImage *image = [[SDAnimatedImage alloc] initWithData:invalidData];
    expect(image).beNil();
    
    NSData *validData = [self testGIFData];
    image = [[SDAnimatedImage alloc] initWithData:validData scale:2];
    expect(image).notTo.beNil(); // image
    expect(image.scale).equal(2); // scale
    expect(image.animatedImageData).equal(validData); // data
    expect(image.animatedImageFormat).equal(SDImageFormatGIF); // format
    expect(image.animatedImageLoopCount).equal(0); // loop count
    expect(image.animatedImageFrameCount).equal(kTestGIFFrameCount); // frame count
    expect([image animatedImageFrameAtIndex:1]).notTo.beNil(); // 1 frame
}

- (void)test02AnimatedImageInitWithContentsOfFile {
    SDAnimatedImage *image = [[SDAnimatedImage alloc] initWithContentsOfFile:[self testGIFPath]];
    expect(image).notTo.beNil();
    expect(image.scale).equal(1); // scale
    // enough, other can be test with InitWithData
}

- (void)test03AnimatedImageInitWithAnimatedCoder {
    NSData *validData = [self testGIFData];
    SDImageGIFCoder *coder = [[SDImageGIFCoder alloc] initWithAnimatedImageData:validData options:nil];
    SDAnimatedImage *image = [[SDAnimatedImage alloc] initWithAnimatedCoder:coder scale:1];
    expect(image).notTo.beNil();
    // enough, other can be test with InitWithData
}

- (void)test04AnimatedImageImageNamed {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
#if SD_UIKIT
    SDAnimatedImage *image = [SDAnimatedImage imageNamed:@"TestImage.gif" inBundle:bundle compatibleWithTraitCollection:nil];
#else
    SDAnimatedImage *image = [SDAnimatedImage imageNamed:@"TestImage.gif" inBundle:bundle];
#endif
    expect(image).notTo.beNil();
    expect([image.animatedImageData isEqualToData:[self testGIFData]]).beTruthy();
}

- (void)test05AnimatedImagePreloadFrames {
    NSData *validData = [self testGIFData];
    SDAnimatedImage *image = [SDAnimatedImage imageWithData:validData];
    
    // Preload all frames
    [image preloadAllFrames];
    
    NSArray *loadedAnimatedImageFrames = [image valueForKey:@"loadedAnimatedImageFrames"]; // Access the internal property, only for test and may be changed in the future
    expect(loadedAnimatedImageFrames.count).equal(kTestGIFFrameCount);
    
    // Test one frame
    UIImage *frame = [image animatedImageFrameAtIndex:0];
    expect(frame).notTo.beNil();
}

- (void)test06AnimatedImageViewSetImage {
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    UIImage *image = [[UIImage alloc] initWithData:[self testJPEGData]];
    imageView.image = image;
    expect(imageView.image).notTo.beNil();
    expect(imageView.currentFrame).beNil(); // current frame
}

- (void)test08AnimatedImageViewSetAnimatedImageGIF {
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    SDAnimatedImage *image = [SDAnimatedImage imageWithData:[self testGIFData]];
    imageView.image = image;
    expect(imageView.image).notTo.beNil();
    expect(imageView.currentFrame).notTo.beNil(); // current frame
}

- (void)test09AnimatedImageViewSetAnimatedImageAPNG {
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    SDAnimatedImage *image = [SDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.image = image;
    expect(imageView.image).notTo.beNil();
    expect(imageView.currentFrame).notTo.beNil(); // current frame
}

- (void)test10AnimatedImageInitWithCoder {
    SDAnimatedImage *image1 = [SDAnimatedImage imageWithContentsOfFile:[self testGIFPath]];
    expect(image1).notTo.beNil();
    NSData *encodedData = [NSKeyedArchiver archivedDataWithRootObject:image1];
    expect(encodedData).notTo.beNil();
    SDAnimatedImage *image2 = [NSKeyedUnarchiver unarchiveObjectWithData:encodedData];
    expect(image2).notTo.beNil();
    
    // Check each property
    expect(image1.scale).equal(image2.scale);
    expect(image1.size).equal(image2.size);
    expect(image1.animatedImageFormat).equal(image2.animatedImageFormat);
    expect(image1.animatedImageData).equal(image2.animatedImageData);
    expect(image1.animatedImageLoopCount).equal(image2.animatedImageLoopCount);
    expect(image1.animatedImageFrameCount).equal(image2.animatedImageFrameCount);
}

- (void)test11AnimatedImageViewIntrinsicContentSize {
    // Test that SDAnimatedImageView.intrinsicContentSize return the correct value of image size
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    SDAnimatedImage *image = [SDAnimatedImage imageWithData:[self testAPNGPData]];
    imageView.image = image;
    expect(imageView.intrinsicContentSize).equal(image.size);
}

- (void)test12AnimatedImageViewLayerContents {
    // Test that SDAnimatedImageView with built-in UIImage/NSImage will actually setup the layer for display
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    UIImage *image = [[UIImage alloc] initWithData:[self testJPEGData]];
    imageView.image = image;
#if SD_MAC
    expect(imageView.wantsUpdateLayer).beTruthy();
#else
    expect(imageView.layer.contents).notTo.beNil();
#endif
}

- (void)test20AnimatedImageViewRendering {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test SDAnimatedImageView rendering"];
    SDAnimatedImageView *imageView = [[SDAnimatedImageView alloc] init];
#if SD_UIKIT
    [self.window addSubview:imageView];
#else
    [self.window.contentView addSubview:imageView];
#endif
    
    NSMutableDictionary *frames = [NSMutableDictionary dictionaryWithCapacity:kTestGIFFrameCount];
    
    [self.KVOController observe:imageView keyPaths:@[NSStringFromSelector(@selector(currentFrameIndex)), NSStringFromSelector(@selector(currentLoopCount))] options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        NSUInteger frameIndex = imageView.currentFrameIndex;
        NSUInteger loopCount = imageView.currentLoopCount;
        [frames setObject:@(YES) forKey:@(frameIndex)];
        
        BOOL framesRendered = NO;
        if (frames.count >= kTestGIFFrameCount) {
            // All frames rendered
            framesRendered = YES;
        }
        BOOL loopFinished = NO;
        if (loopCount >= 1) {
            // One loop finished
            loopFinished = YES;
        }
        if (framesRendered && loopFinished) {
#if SD_UIKIT
            [imageView stopAnimating];
#else
            imageView.animates = NO;
#endif
            [expectation fulfill];
        }
    }];
    
    SDAnimatedImage *image = [SDAnimatedImage imageWithData:[self testGIFData]];
    imageView.image = image;
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test21AnimatedImageViewSetProgressiveAnimatedImage {
    NSData *gifData = [self testGIFData];
    SDImageGIFCoder *progressiveCoder = [[SDImageGIFCoder alloc] initIncrementalWithOptions:nil];
    // simulate progressive decode, pass partial data
    NSData *partialData = [gifData subdataWithRange:NSMakeRange(0, gifData.length - 1)];
    [progressiveCoder updateIncrementalData:partialData finished:NO];
    
    SDAnimatedImage *partialImage = [[SDAnimatedImage alloc] initWithAnimatedCoder:progressiveCoder scale:1];
    partialImage.sd_isIncremental = YES;
    
    SDAnimatedImageView *imageView = [[SDAnimatedImageView alloc] init];
    imageView.image = partialImage;
    
    BOOL isProgressive = imageView.isProgressive;
    expect(isProgressive).equal(YES);
    
    // pass full data
    [progressiveCoder updateIncrementalData:gifData finished:YES];
    
    SDAnimatedImage *fullImage = [[SDAnimatedImage alloc] initWithAnimatedCoder:progressiveCoder scale:1];
    
    imageView.image = fullImage;
    
    isProgressive = imageView.isProgressive;
    expect(isProgressive).equal(NO);
}

- (void)test22AnimatedImageViewCategory {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test SDAnimatedImageView view category"];
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    NSURL *testURL = [NSURL URLWithString:kTestGIFURL];
    [imageView sd_setImageWithURL:testURL completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        expect([image isKindOfClass:[SDAnimatedImage class]]).beTruthy();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test23AnimatedImageViewCategoryProgressive {
    XCTestExpectation *expectation = [self expectationWithDescription:@"test SDAnimatedImageView view category"];
    SDAnimatedImageView *imageView = [SDAnimatedImageView new];
    NSURL *testURL = [NSURL URLWithString:kTestGIFURL];
    [imageView sd_setImageWithURL:testURL placeholderImage:nil options:SDWebImageProgressiveLoad progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = imageView.image;
            // Progressive image may be nil when download data is not enough
            if (image) {
                expect(image.sd_isIncremental).beTruthy();
                expect([image conformsToProtocol:@protocol(SDAnimatedImage)]).beTruthy();
                BOOL isProgressive = imageView.isProgressive;
                expect(isProgressive).equal(YES);
            }
        });
    } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        expect([image isKindOfClass:[SDAnimatedImage class]]).beTruthy();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - Helper
- (UIWindow *)window {
    if (!_window) {
        UIScreen *mainScreen = [UIScreen mainScreen];
#if SD_UIKIT
        _window = [[UIWindow alloc] initWithFrame:mainScreen.bounds];
#else
        _window = [[NSWindow alloc] initWithContentRect:mainScreen.frame styleMask:0 backing:NSBackingStoreBuffered defer:NO screen:mainScreen];
#endif
    }
    return _window;
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImage" ofType:@"gif"];
    return testPath;
}

- (NSData *)testGIFData {
    NSData *testData = [NSData dataWithContentsOfFile:[self testGIFPath]];
    return testData;
}

- (NSString *)testAPNGPPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImageAnimated" ofType:@"apng"];
    return testPath;
}

- (NSData *)testAPNGPData {
    return [NSData dataWithContentsOfFile:[self testAPNGPPath]];
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    NSString *testPath = [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
    return testPath;
}

- (NSData *)testJPEGData {
    NSData *testData = [NSData dataWithContentsOfFile:[self testJPEGPath]];
    return testData;
}

@end
