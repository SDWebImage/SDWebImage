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

@interface SDWebCacheCategoriesTests : SDTestCase

@property (nonatomic, strong) UIWindow *window;

@end

@implementation SDWebCacheCategoriesTests

- (void)testUIImageViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [imageView sd_setImageWithURL:originalImageURL
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            expect(image).toNot.beNil();
                            expect(error).to.beNil();
                            expect(originalImageURL).to.equal(imageURL);
                            expect(imageView.image).to.equal(image);
                            [expectation fulfill];
                        }];
    [self waitForExpectationsWithCommonTimeout];
}

#if SD_UIKIT
- (void)testUIImageViewSetHighlightedImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setHighlightedImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [imageView sd_setHighlightedImageWithURL:originalImageURL
                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                       expect(image).toNot.beNil();
                                       expect(error).to.beNil();
                                       expect(originalImageURL).to.equal(imageURL);
                                       expect(imageView.highlightedImage).to.equal(image);
                                       [expectation fulfill];
                                   }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIImageViewSetAnimationImagesWithURLs {
    XCTestExpectation *expectation = [self expectationWithDescription:@"MKAnnotationView setImageWithURL"];
    
    const NSUInteger urlCount = 30;
    NSString *urlformat = @"https://raw.githubusercontent.com/mikeswanson/JBWatchActivityIndicator/master/Common%%20Images/Normal%%20Size%%20(1.0x)/30/Activity%d%%402x.png";
    NSMutableArray<NSURL *> *urls = [NSMutableArray arrayWithCapacity:urlCount];
    for (int i = 1; i <= urlCount; i++) {
        NSString *url = [NSString stringWithFormat:urlformat, i];
        [urls addObject:[NSURL URLWithString:url]];
    }
    
    __block NSUInteger counter = 0;
    UIImageView *imageView = [[UIImageView alloc] init];
    [imageView sd_setAnimationImagesWithURLs:[urls copy] progress:^(NSUInteger noOfFinishedUrls, NSUInteger noOfTotalUrls) {
        counter++;
        expect(counter).equal(noOfFinishedUrls);
        expect(noOfTotalUrls).equal(urlCount);
    } completed:^(NSUInteger noOfFinishedUrls, NSUInteger noOfSkippedUrls) {
        expect(noOfSkippedUrls).equal(0);
        expect(noOfFinishedUrls).equal(urlCount);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * 5 handler:nil];
}

#endif

- (void)testMKAnnotationViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"MKAnnotationView setImageWithURL"];
    
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [annotationView sd_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 expect(image).toNot.beNil();
                                 expect(error).to.beNil();
                                 expect(originalImageURL).to.equal(imageURL);
                                 expect(annotationView.image).to.equal(image);
                                 [expectation fulfill];
                             }];
    [self waitForExpectationsWithCommonTimeout];
}

#if SD_UIKIT
- (void)testUIButtonSetImageWithURLNormalState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL normalState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    [button sd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect([button imageForState:UIControlStateNormal]).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIButtonSetImageWithURLHighlightedState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL highlightedState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
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
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
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
#endif

#if SD_MAC
- (void)testNSButtonSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"NSButton setImageWithURL"];
    
    NSButton *button = [[NSButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [button sd_setImageWithURL:originalImageURL
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect(button.image).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testNSButtonSetAlternateImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"NSButton setAlternateImageWithURL"];
    
    NSButton *button = [[NSButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    [button sd_setAlternateImageWithURL:originalImageURL
                              completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                  expect(image).toNot.beNil();
                                  expect(error).to.beNil();
                                  expect(originalImageURL).to.equal(imageURL);
                                  expect(button.alternateImage).to.equal(image);
                                  [expectation fulfill];
                              }];
    [self waitForExpectationsWithCommonTimeout];
}
#endif

- (void)testUIViewImageProgressKVOWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView imageProgressKVO failed"];
    UIView *view = [[UIView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:kTestJPEGURL];
    
    [self.KVOController observe:view.sd_imageProgress keyPath:NSStringFromSelector(@selector(fractionCompleted)) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        NSProgress *progress = object;
        NSNumber *completedValue = change[NSKeyValueChangeNewKey];
        expect(progress.fractionCompleted).equal(completedValue.doubleValue);
        // mark that KVO is called
        [progress setUserInfoObject:@(YES) forKey:NSStringFromSelector(@selector(testUIViewImageProgressKVOWork))];
    }];
    
    // Clear the disk cache to force download from network
    [[SDImageCache sharedImageCache] removeImageForKey:kTestJPEGURL withCompletion:^{
        [view sd_internalSetImageWithURL:originalImageURL placeholderImage:nil options:0 context:nil setImageBlock:nil progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(view.sd_imageProgress.fractionCompleted).equal(1.0);
            expect([view.sd_imageProgress.userInfo[NSStringFromSelector(_cmd)] boolValue]).equal(YES);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewTransitionWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView transition does not work"];
    
    // Attach a window, or CALayer will not submit drawing
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    // Cover each convenience method
    imageView.sd_imageTransition = SDWebImageTransition.fadeTransition;
    imageView.sd_imageTransition = SDWebImageTransition.flipFromTopTransition;
    imageView.sd_imageTransition = SDWebImageTransition.flipFromLeftTransition;
    imageView.sd_imageTransition = SDWebImageTransition.flipFromBottomTransition;
    imageView.sd_imageTransition = SDWebImageTransition.flipFromRightTransition;
    imageView.sd_imageTransition = SDWebImageTransition.curlUpTransition;
    imageView.sd_imageTransition = SDWebImageTransition.curlDownTransition;
    imageView.sd_imageTransition.duration = 1;
    
#if SD_UIKIT
    [self.window addSubview:imageView];
#else
    imageView.wantsLayer = YES;
    [self.window.contentView addSubview:imageView];
#endif
    
    UIImage *placeholder = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    __weak typeof(imageView) wimageView = imageView;
    [imageView sd_setImageWithURL:originalImageURL
                 placeholderImage:placeholder
                          options:SDWebImageForceTransition
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            __strong typeof(wimageView) simageView = imageView;
                            // Delay to let CALayer commit the transition in next runloop
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
                                // Check current view contains layer animation
                                NSArray *animationKeys = simageView.layer.animationKeys;
                                expect(animationKeys.count).beGreaterThan(0);
                                [expectation fulfill];
                            });
                        }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)testUIViewIndicatorWork {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIView indicator does not work"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.sd_imageIndicator = SDWebImageActivityIndicator.grayIndicator;
    // Cover each convience method, finally use progress indicator for test
    imageView.sd_imageIndicator = SDWebImageActivityIndicator.grayLargeIndicator;
    imageView.sd_imageIndicator = SDWebImageActivityIndicator.whiteIndicator;
    imageView.sd_imageIndicator = SDWebImageActivityIndicator.whiteLargeIndicator;
#if SD_IOS
    imageView.sd_imageIndicator = SDWebImageProgressIndicator.barIndicator;
#endif
    imageView.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    // Test setter trigger removeFromSuperView
    expect(imageView.subviews.count).equal(1);
    
    NSURL *originalImageURL = [NSURL URLWithString:kTestJpegURL];
    __weak typeof(imageView) wimageView = imageView;
    [imageView sd_setImageWithURL:originalImageURL
                 placeholderImage:nil options:SDWebImageFromLoaderOnly progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         __strong typeof(wimageView) simageView = imageView;
                         UIView *indicatorView = simageView.subviews.firstObject;
                         expect(indicatorView).equal(simageView.sd_imageIndicator.indicatorView);
                         
                         if (receivedSize <= 0 || expectedSize <= 0) {
                             return;
                         }
                         
                         // Base on current implementation, since we dispatch the progressBlock to main queue, the indicator's progress state should be synchonized
                         double progress = 0;
                         double imageProgress = (double)receivedSize / (double)expectedSize;
#if SD_UIKIT
                         progress = ((UIProgressView *)simageView.sd_imageIndicator.indicatorView).progress;
#else
                         progress = ((NSProgressIndicator *)simageView.sd_imageIndicator.indicatorView).doubleValue / 100;
#endif
                         expect(progress).equal(imageProgress);
                     });
                 } completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                     __strong typeof(wimageView) simageView = imageView;
                     double progress = 0;
#if SD_UIKIT
                     progress = ((UIProgressView *)simageView.sd_imageIndicator.indicatorView).progress;
#else
                     progress = ((NSProgressIndicator *)simageView.sd_imageIndicator.indicatorView).doubleValue / 100;
#endif
                     // Finish progress is 1
                     expect(progress).equal(1);
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

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

@end
