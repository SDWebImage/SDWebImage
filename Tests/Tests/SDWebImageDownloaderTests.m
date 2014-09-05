//
//  SDWebImageDownloaderTests.m
//  SDWebImage Tests
//
//  Created by Matt Galloway on 01/09/2014.
//
//

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

- (BOOL)spinRunLoopWithTimeout:(NSTimeInterval)timeout untilBlockIsTrue:(BOOL(^)())block {
  CFTimeInterval timeoutDate = CACurrentMediaTime() + 5.;
  while (true) {
      if (block()) {
          return YES;
      }
      if (CACurrentMediaTime() > timeoutDate) {
          return NO;
      }
      CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1., true);
  }
  return NO;
}

- (void)testThatDownloadingSameURLTwiceAndCancellingFirstWorks {
    NSURL *imageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.jpg?20120509154705"];

    id token1 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        XCTFail(@"Shouldn't have completed here.");
                                                                    }];
    expect(token1).toNot.beNil();

    __block BOOL success = NO;
    id token2 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        success = YES;
                                                                    }];
    expect(token2).toNot.beNil();

    [[SDWebImageDownloader sharedDownloader] cancel:token1];

    success = [self spinRunLoopWithTimeout:5. untilBlockIsTrue:^BOOL{
        return success;
    }];

    if (!success) {
        XCTFail(@"Failed to download image");
    }
}

- (void)testThatCancelingDownloadThenRequestingAgainWorks {
    NSURL *imageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.jpg?20120509154705"];

    id token1 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        XCTFail(@"Shouldn't have completed here.");
                                                                    }];
    expect(token1).toNot.beNil();

    [[SDWebImageDownloader sharedDownloader] cancel:token1];

    __block BOOL success = NO;
    id token2 = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                                      options:0
                                                                     progress:nil
                                                                    completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                        success = YES;
                                                                    }];
    expect(token2).toNot.beNil();

    success = [self spinRunLoopWithTimeout:5. untilBlockIsTrue:^BOOL{
        return success;
    }];

    if (!success) {
        XCTFail(@"Failed to download image");
    }
}

@end
