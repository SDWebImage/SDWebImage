/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#define EXP_SHORTHAND   // required by Expecta

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImageView+HighlightedWebCache.h>
#import <SDWebImage/MKAnnotationView+WebCache.h>
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/FLAnimatedImageView+WebCache.h>

@import FLAnimatedImage;

@interface SDCategoriesTests : XCTestCase

@end

@implementation SDCategoriesTests

- (void)testUIImageViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage050.jpg"];
    [imageView sd_setImageWithURL:originalImageURL
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            expect(image).toNot.beNil();
                            expect(error).to.beNil();
                            expect(originalImageURL).to.equal(imageURL);
                            expect(imageView.image).to.equal(image);
                            [expectation fulfill];
                        }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)testUIImageViewSetHighlightedImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIImageView setHighlightedImageWithURL"];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage051.jpg"];
    [imageView sd_setHighlightedImageWithURL:originalImageURL
                                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                       expect(image).toNot.beNil();
                                       expect(error).to.beNil();
                                       expect(originalImageURL).to.equal(imageURL);
                                       expect(imageView.highlightedImage).to.equal(image);
                                       [expectation fulfill];
                                   }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)testMKAnnotationViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"MKAnnotationView setImageWithURL"];
    
    MKAnnotationView *annotationView = [[MKAnnotationView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage052.jpg"];
    [annotationView sd_setImageWithURL:originalImageURL
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                 expect(image).toNot.beNil();
                                 expect(error).to.beNil();
                                 expect(originalImageURL).to.equal(imageURL);
                                 expect(annotationView.image).to.equal(image);
                                 [expectation fulfill];
                             }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)testUIButtonSetImageWithURLNormalState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL normalState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage053.jpg"];
    [button sd_setImageWithURL:originalImageURL
                      forState:UIControlStateNormal
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect([button imageForState:UIControlStateNormal]).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)testUIButtonSetImageWithURLHighlightedState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setImageWithURL highlightedState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage054.jpg"];
    [button sd_setImageWithURL:originalImageURL
                      forState:UIControlStateHighlighted
                     completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                         expect(image).toNot.beNil();
                         expect(error).to.beNil();
                         expect(originalImageURL).to.equal(imageURL);
                         expect([button imageForState:UIControlStateHighlighted]).to.equal(image);
                         [expectation fulfill];
                     }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)testUIButtonSetBackgroundImageWithURLNormalState {
    XCTestExpectation *expectation = [self expectationWithDescription:@"UIButton setBackgroundImageWithURL normalState"];
    
    UIButton *button = [[UIButton alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage055.jpg"];
    [button sd_setBackgroundImageWithURL:originalImageURL
                                forState:UIControlStateNormal
                               completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                                   expect(image).toNot.beNil();
                                   expect(error).to.beNil();
                                   expect(originalImageURL).to.equal(imageURL);
                                   expect([button backgroundImageForState:UIControlStateNormal]).to.equal(image);
                                   [expectation fulfill];
                               }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

- (void)testFLAnimatedImageViewSetImageWithURL {
    XCTestExpectation *expectation = [self expectationWithDescription:@"FLAnimatedImageView setImageWithURL"];
    
    FLAnimatedImageView *imageView = [[FLAnimatedImageView alloc] init];
    NSURL *originalImageURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif"];
    
    [imageView sd_setImageWithURL:originalImageURL
                        completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            expect(image).toNot.beNil();
                            expect(error).to.beNil();
                            expect(originalImageURL).to.equal(imageURL);
                            
                            expect(imageView.animatedImage).toNot.beNil();
                            [expectation fulfill];
                                }];
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

@end
