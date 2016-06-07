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
#import <Expecta.h>

#import "SDWebImageDownloader.h"

@interface SDWebImageDownloaderTests : XCTestCase

@end

@implementation SDWebImageDownloaderTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatDownloadingSameURLTwiceAndCancellingFirstWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];

    NSURL *imageURL = [NSURL URLWithString:@"http://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage000.jpg"];

    id token1 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        XCTFail(@"Shouldn't have completed here.");
                                                                    }];
    expect(token1).toNot.beNil();

    id token2 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        [expectation fulfill];
                                                                    }];
    expect(token2).toNot.beNil();

    [[SDWebImageDownloader sharedDownloader] cancel:token1];

    [self waitForExpectationsWithTimeout:5. handler:nil];
}

- (void)testThatCancelingDownloadThenRequestingAgainWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];

    NSURL *imageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.jpg?20120509154705"];

    id token1 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        XCTFail(@"Shouldn't have completed here.");
                                                                    }];
    expect(token1).toNot.beNil();

    [[SDWebImageDownloader sharedDownloader] cancel:token1];

    id token2 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        [expectation fulfill];
                                                                    }];
    expect(token2).toNot.beNil();

    [self waitForExpectationsWithTimeout:5. handler:nil];
}

@end
