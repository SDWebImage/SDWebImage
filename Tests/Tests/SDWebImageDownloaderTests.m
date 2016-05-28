//
//  UIImageViewWebCacheTests.m
//  SDWebImage Tests
//
//  Created by Mariano Heredia on 12/4/15.
//
//

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <Expecta.h>
#import "SDWebImageDownloader.h"

static int64_t kAsyncTestTimeout = 5;

@interface UIImageViewWebCacheTests : XCTestCase

@end


@implementation UIImageViewWebCacheTests


- (void)testThatCanceledDownloadDoNotInvokeProgressBlock {
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"Progress block canceled"];
    
    NSURL *imageURL = [NSURL URLWithString:@"https://duckduckgo.com/assets/icons/meta/DDG-icon_256x256.png"];

    __block BOOL secondOperationHasBeenCanceled = NO;
    
    // Starts downloading a given URL
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                          options:0
                                                   progress:^(NSInteger receivedSize, NSInteger expectedSize) {}
                                                  completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                      [expectation fulfill];
                                                      expectation = nil;
                                                      
                                                  }];
    
    SDWebImageDownloaderProgressBlock progressBlock1 = ^(NSInteger receivedSize, NSInteger expectedSize) {
        // Check if this progress block still needs to be called.
        expect(secondOperationHasBeenCanceled).equal(NO);
    };
    

    // Start a second download operation for the same imageURL
    id <SDWebImageOperation> o = [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL
                                                    options:0
                                                   progress:progressBlock1
                                                  completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {}];
    

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // Shortly after, cancel the download operation...
        [o cancel];
        secondOperationHasBeenCanceled = YES;
    });

    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:nil];
}

@end
