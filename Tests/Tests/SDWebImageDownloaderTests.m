/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import "SDWebImageTestDownloadOperation.h"
#import "SDWebImageTestCoder.h"
#import "SDWebImageTestLoader.h"
#import <compression.h>

#define kPlaceholderTestURLTemplate @"https://via.placeholder.com/10000x%d.png"

/**
 *  Category for SDWebImageDownloader so we can access the operationClass
 */
@interface SDWebImageDownloadToken ()
@property (nonatomic, weak, nullable) NSOperation<SDWebImageDownloaderOperation> *downloadOperation;
@end

@interface SDWebImageDownloader ()
@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;
@end


@interface SDWebImageDownloaderTests : SDTestCase

@property (nonatomic, strong) NSMutableArray<NSURL *> *executionOrderURLs;

@end

@implementation SDWebImageDownloaderTests

- (void)test01ThatSharedDownloaderIsNotEqualToInitDownloader {
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    expect(downloader).toNot.equal([SDWebImageDownloader sharedDownloader]);
    [downloader invalidateSessionAndCancel:YES];
}

- (void)test02ThatByDefaultDownloaderSetsTheAcceptHTTPHeader {
    expect([[SDWebImageDownloader sharedDownloader] valueForHTTPHeaderField:@"Accept"]).to.match(@"image/\\*,\\*/\\*;q=0.8");
}

- (void)test03ThatSetAndGetValueForHTTPHeaderFieldWork {
    NSString *headerValue = @"Tests";
    NSString *headerName = @"AppName";
    // set it
    [[SDWebImageDownloader sharedDownloader] setValue:headerValue forHTTPHeaderField:headerName];
    expect([[SDWebImageDownloader sharedDownloader] valueForHTTPHeaderField:headerName]).to.equal(headerValue);
    // clear it
    [[SDWebImageDownloader sharedDownloader] setValue:nil forHTTPHeaderField:headerName];
    expect([[SDWebImageDownloader sharedDownloader] valueForHTTPHeaderField:headerName]).to.beNil();
}

- (void)test04ThatASimpleDownloadWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple download"];
    NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong: %@", error.description);
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test05ThatSetAndGetMaxConcurrentDownloadsWorks {
    NSInteger initialValue = SDWebImageDownloader.sharedDownloader.config.maxConcurrentDownloads;
    
    SDWebImageDownloader.sharedDownloader.config.maxConcurrentDownloads = 3;
    expect(SDWebImageDownloader.sharedDownloader.config.maxConcurrentDownloads).to.equal(3);
    
    SDWebImageDownloader.sharedDownloader.config.maxConcurrentDownloads = initialValue;
}

- (void)test06ThatUsingACustomDownloaderOperationWorks {
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] initWithConfig:nil];
    NSURL *imageURL1 = [NSURL URLWithString:kTestJPEGURL];
    NSURL *imageURL2 = [NSURL URLWithString:kTestPNGURL];
    NSURL *imageURL3 = [NSURL URLWithString:kTestGIFURL];
    // we try to set a usual NSOperation as operation class. Should not work
    downloader.config.operationClass = [NSOperation class];
    SDWebImageDownloadToken *token = [downloader downloadImageWithURL:imageURL1 options:0 progress:nil completed:nil];
    NSOperation<SDWebImageDownloaderOperation> *operation = token.downloadOperation;
    expect([operation class]).to.equal([SDWebImageDownloaderOperation class]);
    
    // setting an NSOperation subclass that conforms to SDWebImageDownloaderOperation - should work
    downloader.config.operationClass = [SDWebImageTestDownloadOperation class];
    token = [downloader downloadImageWithURL:imageURL2 options:0 progress:nil completed:nil];
    operation = token.downloadOperation;
    expect([operation class]).to.equal([SDWebImageTestDownloadOperation class]);
    
    // Assert the NSOperation conforms to `SDWebImageOperation`
    expect([NSOperation.class conformsToProtocol:@protocol(SDWebImageOperation)]).beTruthy();
    expect([operation conformsToProtocol:@protocol(SDWebImageOperation)]).beTruthy();
    
    // back to the original value
    downloader.config.operationClass = nil;
    token = [downloader downloadImageWithURL:imageURL3 options:0 progress:nil completed:nil];
    operation = token.downloadOperation;
    expect([operation class]).to.equal([SDWebImageDownloaderOperation class]);
    
    [downloader invalidateSessionAndCancel:YES];
}

- (void)test07ThatDownloadImageWithNilURLCallsCompletionWithNils {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion is called with nils"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:nil options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(image).to.beNil();
        expect(data).to.beNil();
        expect(error.code).equal(SDWebImageErrorInvalidURL);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test08ThatAHTTPAuthDownloadWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Auth download"];
    SDWebImageDownloaderConfig *config = SDWebImageDownloaderConfig.defaultDownloaderConfig;
    config.username = @"httpwatch";
    config.password = @"httpwatch01";
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] initWithConfig:config];
    NSURL *imageURL = [NSURL URLWithString:@"http://www.httpwatch.com/httpgallery/authentication/authenticatedimage/default.aspx?0.35786508303135633"];
    [downloader downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong: %@", error.description);
        }
    }];
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        [downloader invalidateSessionAndCancel:YES];
    }];
}

- (void)test09ThatProgressiveJPEGWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive JPEG download"];
    NSURL *imageURL = [NSURL URLWithString:kTestProgressiveJPEGURL];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderProgressiveLoad progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else if (finished) {
            XCTFail(@"Something went wrong: %@", error.description);
        } else {
            // progressive updates
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test10That404CaseCallsCompletionWithError {
    NSURL *imageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.jpg?20120509154705"];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"404"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (!image && !data && error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong: %@", error.description);
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test11ThatCancelWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Cancel"];
    
    NSURL *imageURL = [NSURL URLWithString:@"http://via.placeholder.com/1000x1000.png"];
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader]
                                      downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                          expect(error).notTo.beNil();
                                          expect(error.domain).equal(SDWebImageErrorDomain);
                                          expect(error.code).equal(SDWebImageErrorCancelled);
                                      }];
    expect([SDWebImageDownloader sharedDownloader].currentDownloadCount).to.equal(1);
    
    [token cancel];
    
    // doesn't cancel immediately - since it uses dispatch async
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        expect([SDWebImageDownloader sharedDownloader].currentDownloadCount).to.equal(0);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test11ThatCancelAllDownloadWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"CancelAllDownloads"];
    // Previous test case download may not finished, so we just check the download count should + 1 after new request
    NSUInteger currentDownloadCount = [SDWebImageDownloader sharedDownloader].currentDownloadCount;
    
    // Choose a large image to avoid download too fast
    NSURL *imageURL = [NSURL URLWithString:@"https://www.sample-videos.com/img/Sample-png-image-1mb.png"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL completed:nil];
    expect([SDWebImageDownloader sharedDownloader].currentDownloadCount).to.equal(currentDownloadCount + 1);
    
    [[SDWebImageDownloader sharedDownloader] cancelAllDownloads];
    
    // doesn't cancel immediately - since it uses dispatch async
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        expect([SDWebImageDownloader sharedDownloader].currentDownloadCount).to.equal(0);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test12ThatWeCanUseAnotherSessionForEachDownloadOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Owned session"];
    NSURL *url = [NSURL URLWithString:kTestJPEGURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    request.HTTPShouldUsePipelining = YES;
    request.allHTTPHeaderFields = @{@"Accept": @"image/*;q=0.8"};
    
    SDWebImageDownloaderOperation *operation = [[SDWebImageDownloaderOperation alloc] initWithRequest:request
                                                                                            inSession:nil
                                                                                              options:0];
    [operation addHandlersForProgress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *imageURL) {
        
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong: %@", error.description);
        }
    }];
    
    [operation start];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test13ThatDownloadCanContinueWhenTheAppEntersBackground {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Simple download"];
    NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderContinueInBackground progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong: %@", error.description);
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test14ThatPNGWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"PNG"];
    NSURL *imageURL = [NSURL URLWithString:kTestPNGURL];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong: %@", error.description);
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test15DownloaderLIFOExecutionOrder {
    SDWebImageDownloaderConfig *config = [[SDWebImageDownloaderConfig alloc] init];
    config.executionOrder = SDWebImageDownloaderLIFOExecutionOrder; // Last In First Out
    config.maxConcurrentDownloads = 1; // 1
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] initWithConfig:config];
    self.executionOrderURLs = [NSMutableArray array];
    
    // Input order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 (wait for 7 started and immediately) -> 8 -> 9 -> 10 -> 11 -> 12 -> 13 -> 14
    // Expected result: 1 (first one has no dependency) -> 7 -> 14 -> 13 -> 12 -> 11 -> 10 -> 9 -> 8 -> 6 -> 5 -> 4 -> 3 -> 2
    int waitIndex = 7;
    int maxIndex = 14;
    NSMutableArray<XCTestExpectation *> *expectations = [NSMutableArray array];
    for (int i = 1; i <= maxIndex; i++) {
        XCTestExpectation *expectation = [self expectationWithDescription:[NSString stringWithFormat:@"URL %d order wrong", i]];
        [expectations addObject:expectation];
    }
    
    for (int i = 1; i <= waitIndex; i++) {
        [self createLIFOOperationWithDownloader:downloader expectation:expectations[i-1] index:i];
    }
    [[NSNotificationCenter defaultCenter] addObserverForName:SDWebImageDownloadStartNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        SDWebImageDownloaderOperation *operation = note.object;
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kPlaceholderTestURLTemplate, waitIndex]];
        if (![operation.request.URL isEqual:url]) {
            return;
        }
        for (int i = waitIndex + 1; i <= maxIndex; i++) {
            [self createLIFOOperationWithDownloader:downloader expectation:expectations[i-1] index:i];
        }
    }];
    
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout * maxIndex handler:nil];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wshadow"
- (void)createLIFOOperationWithDownloader:(SDWebImageDownloader *)downloader expectation:(XCTestExpectation *)expectation index:(int)index {
    int waitIndex = 7;
    int maxIndex = 14;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kPlaceholderTestURLTemplate, index]];
    [self.executionOrderURLs addObject:url];
    [downloader downloadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        printf("URL%d finished\n", index);
        NSMutableArray *pendingArray = [NSMutableArray array];
        if (index == 1) {
            // 1
            for (int j = 1; j <= waitIndex; j++) {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kPlaceholderTestURLTemplate, j]];
                [pendingArray addObject:url];
            }
        } else if (index == waitIndex) {
            // 7
            for (int j = 2; j <= maxIndex; j++) {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kPlaceholderTestURLTemplate, j]];
                [pendingArray addObject:url];
            }
        } else if (index > waitIndex) {
            // 8-14
            for (int j = 2; j <= index; j++) {
                if (j == waitIndex) continue;
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kPlaceholderTestURLTemplate, j]];
                [pendingArray addObject:url];
            }
        } else if (index < waitIndex) {
            // 2-6
            for (int j = 2; j <= index; j++) {
                if (j == waitIndex) continue;
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kPlaceholderTestURLTemplate, j]];
                [pendingArray addObject:url];
            }
        }
        expect(self.executionOrderURLs).equal(pendingArray);
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kPlaceholderTestURLTemplate, index]];
        [self.executionOrderURLs removeObject:url];
        [expectation fulfill];
    }];
}
#pragma clang diagnostic pop

- (void)test17ThatMinimumProgressIntervalWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Minimum progress interval"];
    SDWebImageDownloaderConfig *config = SDWebImageDownloaderConfig.defaultDownloaderConfig;
    config.minimumProgressInterval = 0.51; // This will make the progress only callback twice (once is 51%, another is 100%)
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] initWithConfig:config];
    NSURL *imageURL = [NSURL URLWithString:@"https://raw.githubusercontent.com/recurser/exif-orientation-examples/master/Landscape_1.jpg"];
    __block NSUInteger allProgressCount = 0; // All progress (including operation start / first HTTP response, etc)
    [downloader downloadImageWithURL:imageURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        allProgressCount++;
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (allProgressCount > 0) {
            [expectation fulfill];
            allProgressCount = 0;
            return;
        } else {
            XCTFail(@"Progress callback more than once");
        }
    }];
     
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        [downloader invalidateSessionAndCancel:YES];
    }];
}

- (void)test18ThatProgressiveGIFWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive GIF download"];
    NSURL *imageURL = [NSURL URLWithString:kTestGIFURL];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderProgressiveLoad progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else if (finished) {
            XCTFail(@"Something went wrong: %@", error.description);
        } else {
            // progressive updates
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test19ThatProgressiveAPNGWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive APNG download"];
    NSURL *imageURL = [NSURL URLWithString:kTestAPNGPURL];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderProgressiveLoad progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else if (finished) {
            XCTFail(@"Something went wrong: %@", error.description);
        } else {
            // progressive updates
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

/**
 *  Per #883 - Fix multiple requests for same image and then canceling one
 *  Old SDWebImage (3.x) could not handle correctly multiple requests for the same image + cancel
 *  In 4.0, via #883 added `SDWebImageDownloadToken` so we can cancel exactly the request we want
 *  This test validates the scenario of making 2 requests for the same image and cancelling the 1st one
 */
- (void)test20ThatDownloadingSameURLTwiceAndCancellingFirstWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    
    NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
    
    SDWebImageDownloadToken *token1 = [[SDWebImageDownloader sharedDownloader]
                                       downloadImageWithURL:imageURL
                                       options:0
                                       progress:nil
                                       completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                           expect(error).notTo.beNil();
                                           expect(error.code).equal(SDWebImageErrorCancelled);
                                       }];
    expect(token1).toNot.beNil();
    
    SDWebImageDownloadToken *token2 = [[SDWebImageDownloader sharedDownloader]
                                       downloadImageWithURL:imageURL
                                       options:0
                                       progress:nil
                                       completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                           if (image && data && !error && finished) {
                                               [expectation fulfill];
                                           } else {
                                               XCTFail(@"Something went wrong: %@", error.description);
                                           }
                                       }];
    expect(token2).toNot.beNil();

    [token1 cancel];

    [self waitForExpectationsWithCommonTimeout];
}

/**
 *  Per #883 - Fix multiple requests for same image and then canceling one
 *  Old SDWebImage (3.x) could not handle correctly multiple requests for the same image + cancel
 *  In 4.0, via #883 added `SDWebImageDownloadToken` so we can cancel exactly the request we want
 *  This test validates the scenario of requesting an image, cancel and then requesting it again
 */
- (void)test21ThatCancelingDownloadThenRequestingAgainWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Correct image downloads"];
    
    NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
    
    SDWebImageDownloadToken *token1 = [[SDWebImageDownloader sharedDownloader]
                                       downloadImageWithURL:imageURL
                                       options:0
                                       progress:nil
                                       completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                           expect(error).notTo.beNil();
                                           expect(error.code).equal(SDWebImageErrorCancelled);
                                       }];
    expect(token1).toNot.beNil();
    
    [token1 cancel];
    
    SDWebImageDownloadToken *token2 = [[SDWebImageDownloader sharedDownloader]
                                       downloadImageWithURL:imageURL
                                       options:0
                                       progress:nil
                                       completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                           if (image && data && !error && finished) {
                                               [expectation fulfill];
                                           } else {
                                               NSLog(@"image = %@, data = %@, error = %@", image, data, error);
                                               XCTFail(@"Something went wrong: %@", error.description);
                                           }
                                       }];
    expect(token2).toNot.beNil();
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test22ThatCustomDecoderWorksForImageDownload {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom decoder for SDWebImageDownloader not works"];
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    SDWebImageTestCoder *testDecoder = [[SDWebImageTestCoder alloc] init];
    [[SDImageCodersManager sharedManager] addCoder:testDecoder];
    NSURL * testImageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"png"];
    
    // Decoded result is JPEG
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [[UIImage alloc] initWithContentsOfFile:testJPEGImagePath];
    
    [downloader downloadImageWithURL:testImageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        NSData *data1 = [testJPEGImage sd_imageDataAsFormat:SDImageFormatPNG];
        NSData *data2 = [image sd_imageDataAsFormat:SDImageFormatPNG];
        if (![data1 isEqualToData:data2]) {
            XCTFail(@"The image data is not equal to cutom decoder, check -[SDWebImageTestDecoder decodedImageWithData:]");
        }
        [[SDImageCodersManager sharedManager] removeCoder:testDecoder];
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
    [downloader invalidateSessionAndCancel:YES];
}

- (void)test23ThatDownloadRequestModifierWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download request modifier not works"];
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    
    // Test conveniences modifier
    SDWebImageDownloaderRequestModifier *requestModifier = [[SDWebImageDownloaderRequestModifier alloc] initWithHeaders:@{@"Biz" : @"Bazz"}];
    NSURLRequest *testRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:kTestJPEGURL]];
    testRequest = [requestModifier modifiedRequestWithRequest:testRequest];
    expect(testRequest.allHTTPHeaderFields).equal(@{@"Biz" : @"Bazz"});
    
    requestModifier = [SDWebImageDownloaderRequestModifier requestModifierWithBlock:^NSURLRequest * _Nullable(NSURLRequest * _Nonnull request) {
        if ([request.URL.absoluteString isEqualToString:kTestPNGURL]) {
            // Test that return a modified request
            NSMutableURLRequest *mutableRequest = [request mutableCopy];
            [mutableRequest setValue:@"Bar" forHTTPHeaderField:@"Foo"];
            NSURLComponents *components = [NSURLComponents componentsWithURL:mutableRequest.URL resolvingAgainstBaseURL:NO];
            components.query = @"text=Hello+World";
            mutableRequest.URL = components.URL;
            return mutableRequest;
        } else if ([request.URL.absoluteString isEqualToString:kTestJPEGURL]) {
            // Test that return nil request will treat as error
            return nil;
        } else {
            return request;
        }
    }];
    downloader.requestModifier = requestModifier;
    
    __block BOOL firstCheck = NO;
    __block BOOL secondCheck = NO;
    
    [downloader downloadImageWithURL:[NSURL URLWithString:kTestJPEGURL] options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        // Except error
        expect(error).notTo.beNil();
        firstCheck = YES;
        if (firstCheck && secondCheck) {
            [expectation fulfill];
        }
    }];
    
    [downloader downloadImageWithURL:[NSURL URLWithString:kTestPNGURL] options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        // Expect not error
        expect(error).to.beNil();
        secondCheck = YES;
        if (firstCheck && secondCheck) {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test24ThatDownloadResponseModifierWorks {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download response modifier for webURL"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download response modifier invalid response"];
    
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    
    // Test conveniences modifier
    SDWebImageDownloaderResponseModifier *responseModifier = [[SDWebImageDownloaderResponseModifier alloc] initWithHeaders:@{@"Biz" : @"Bazz"}];
    NSURLResponse *testResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:kTestPNGURL] statusCode:404 HTTPVersion:@"HTTP/1.1" headerFields:nil];
    testResponse = [responseModifier modifiedResponseWithResponse:testResponse];
    expect(((NSHTTPURLResponse *)testResponse).allHeaderFields).equal(@{@"Biz" : @"Bazz"});
    expect(((NSHTTPURLResponse *)testResponse).statusCode).equal(200);
    
    // 1. Test webURL to response custom status code and header
    responseModifier = [SDWebImageDownloaderResponseModifier responseModifierWithBlock:^NSURLResponse * _Nullable(NSURLResponse * _Nonnull response) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSMutableDictionary *mutableHeaderFields = [httpResponse.allHeaderFields mutableCopy];
        mutableHeaderFields[@"Foo"] = @"Bar";
        NSHTTPURLResponse *modifiedResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:404 HTTPVersion:nil headerFields:[mutableHeaderFields copy]];
        return [modifiedResponse copy];
    }];
    downloader.responseModifier = responseModifier;
    
    __block SDWebImageDownloadToken *token;
    token = [downloader downloadImageWithURL:[NSURL URLWithString:kTestJPEGURL] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).notTo.beNil();
        expect(error.code).equal(SDWebImageErrorInvalidDownloadStatusCode);
        expect(error.userInfo[SDWebImageErrorDownloadStatusCodeKey]).equal(404);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)token.response;
        expect(httpResponse).notTo.beNil();
        expect(httpResponse.allHeaderFields[@"Foo"]).equal(@"Bar");
        [expectation1 fulfill];
    }];
    
    // 2. Test nil response will cancel the download
    responseModifier = [SDWebImageDownloaderResponseModifier responseModifierWithBlock:^NSURLResponse * _Nullable(NSURLResponse * _Nonnull response) {
        return nil;
    }];
    [downloader downloadImageWithURL:[NSURL URLWithString:kTestPNGURL] options:0 context:@{SDWebImageContextDownloadResponseModifier : responseModifier} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).notTo.beNil();
        expect(error.code).equal(SDWebImageErrorInvalidDownloadResponse);
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        [downloader invalidateSessionAndCancel:YES];
    }];
}

- (void)test25ThatDownloadDecryptorWorks {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download decryptor for fileURL"];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Download decryptor for webURL"];
    XCTestExpectation *expectation3 = [self expectationWithDescription:@"Download decryptor invalid data"];
    
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    downloader.decryptor = SDWebImageDownloaderDecryptor.base64Decryptor;
    
    // 1. Test fileURL with Base64 encoded data works
    NSData *PNGData = [NSData dataWithContentsOfFile:[self testPNGPath]];
    NSData *base64PNGData = [PNGData base64EncodedDataWithOptions:0];
    expect(base64PNGData).notTo.beNil();
    NSURL *base64FileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"TestBase64.png"]];
    [base64PNGData writeToURL:base64FileURL atomically:YES];
    [downloader downloadImageWithURL:base64FileURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        [expectation1 fulfill];
    }];
    
    // 2. Test webURL with Zip encoded data works
    SDWebImageDownloaderDecryptor *decryptor = [SDWebImageDownloaderDecryptor decryptorWithBlock:^NSData * _Nullable(NSData * _Nonnull data, NSURLResponse * _Nullable response) {
        if (@available(iOS 13, macOS 10.15, tvOS 13, *)) {
            return [data decompressedDataUsingAlgorithm:NSDataCompressionAlgorithmZlib error:nil];
        } else {
            NSMutableData *decodedData = [NSMutableData dataWithLength:10 * data.length];
            compression_decode_buffer((uint8_t *)decodedData.bytes, decodedData.length, data.bytes, data.length, nil, COMPRESSION_ZLIB);
            return [decodedData copy];
        }
    }];
    // Note this is not a Zip Archive, just PNG raw buffer data using zlib compression
    NSURL *zipURL = [NSURL URLWithString:@"https://github.com/SDWebImage/SDWebImage/files/3728087/SDWebImage_logo_small.png.zip"];
    
    [downloader downloadImageWithURL:zipURL options:0 context:@{SDWebImageContextDownloadDecryptor : decryptor} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        [expectation2 fulfill];
    }];
    
    // 3. Test nil data will mark download failed
    decryptor = [SDWebImageDownloaderDecryptor decryptorWithBlock:^NSData * _Nullable(NSData * _Nonnull data, NSURLResponse * _Nullable response) {
        return nil;
    }];
    [downloader downloadImageWithURL:[NSURL URLWithString:kTestJPEGURL] options:0 context:@{SDWebImageContextDownloadDecryptor : decryptor} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).notTo.beNil();
        expect(error.code).equal(SDWebImageErrorBadImageData);
        [expectation3 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        [downloader invalidateSessionAndCancel:YES];
    }];
}

- (void)test26DownloadURLSessionMetrics {
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Download URLSessionMetrics works"];
    
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    
    __block SDWebImageDownloadToken *token;
    token = [downloader downloadImageWithURL:[NSURL URLWithString:kTestJPEGURL] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).beNil();
        if (@available(iOS 10.0, tvOS 10.0, macOS 10.12, *)) {
            NSURLSessionTaskMetrics *metrics = token.metrics;
            expect(metrics).notTo.beNil();
            expect(metrics.redirectCount).equal(0);
            expect(metrics.transactionMetrics.count).equal(1);
            NSURLSessionTaskTransactionMetrics *metric = metrics.transactionMetrics.firstObject;
            // Metrcis Test
            expect(metric.fetchStartDate).notTo.beNil();
            expect(metric.connectStartDate).notTo.beNil();
            expect(metric.connectEndDate).notTo.beNil();
            expect(metric.networkProtocolName).equal(@"http/1.1");
            expect(metric.resourceFetchType).equal(NSURLSessionTaskMetricsResourceFetchTypeNetworkLoad);
            expect(metric.isProxyConnection).beFalsy();
            expect(metric.isReusedConnection).beFalsy();
        }
        [expectation1 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        [downloader invalidateSessionAndCancel:YES];
    }];
}

- (void)test27DownloadShouldCallbackWhenURLSessionRunning {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Downloader should callback when URLSessionTask running"];
    
    NSURL *url = [NSURL URLWithString: @"https://raw.githubusercontent.com/SDWebImage/SDWebImage/master/SDWebImage_logo.png"];
    NSString *key = [SDWebImageManager.sharedManager cacheKeyForURL:url];
    
    [SDImageCache.sharedImageCache removeImageForKey:key withCompletion:^{
        SDWebImageCombinedOperation *operation = [SDWebImageManager.sharedManager loadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            expect(error.domain).equal(SDWebImageErrorDomain);
            expect(error.code).equal(SDWebImageErrorCancelled);
            [expectation fulfill];
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [operation cancel];
        });
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test28ProgressiveDownloadShouldUseSameCoder  {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive download should use the same coder for each animated image"];
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    
    __block SDWebImageDownloadToken *token;
    __block id<SDImageCoder> progressiveCoder;
    token = [downloader downloadImageWithURL:[NSURL URLWithString:kTestGIFURL] options:SDWebImageDownloaderProgressiveLoad context:@{SDWebImageContextAnimatedImageClass : SDAnimatedImage.class} progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).beNil();
        expect([image isKindOfClass:SDAnimatedImage.class]).beTruthy();
        id<SDImageCoder> coder = ((SDAnimatedImage *)image).animatedCoder;
        if (!progressiveCoder) {
            progressiveCoder = coder;
        }
        expect(progressiveCoder).equal(coder);
        if (!finished) {
            progressiveCoder = coder;
        } else {
            [expectation fulfill];
        }
    }];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        [downloader invalidateSessionAndCancel:YES];
    }];
}

- (void)test29AcceptableStatusCodeAndContentType {
    SDWebImageDownloaderConfig *config1 = [[SDWebImageDownloaderConfig alloc] init];
    config1.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:1];
    SDWebImageDownloader *downloader1 = [[SDWebImageDownloader alloc] initWithConfig:config1];
    XCTestExpectation *expectation1 = [self expectationWithDescription:@"Acceptable status code should work"];
    
    SDWebImageDownloaderConfig *config2 = [[SDWebImageDownloaderConfig alloc] init];
    config2.acceptableContentTypes = [NSSet setWithArray:@[@"application/json"]];
    SDWebImageDownloader *downloader2 = [[SDWebImageDownloader alloc] initWithConfig:config2];
    XCTestExpectation *expectation2 = [self expectationWithDescription:@"Acceptable content type should work"];
    
    __block SDWebImageDownloadToken *token1;
    token1 = [downloader1 downloadImageWithURL:[NSURL URLWithString:kTestJPEGURL] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).notTo.beNil();
        expect(error.code).equal(SDWebImageErrorInvalidDownloadStatusCode);
        NSInteger statusCode = ((NSHTTPURLResponse *)token1.response).statusCode;
        expect(statusCode).equal(200);
        [expectation1 fulfill];
    }];
    
    __block SDWebImageDownloadToken *token2;
    token2 = [downloader2 downloadImageWithURL:[NSURL URLWithString:kTestJPEGURL] completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).notTo.beNil();
        expect(error.code).equal(SDWebImageErrorInvalidDownloadContentType);
        NSString *contentType = ((NSHTTPURLResponse *)token2.response).MIMEType;
        expect(contentType).equal(@"image/jpeg");
        [expectation2 fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeoutUsingHandler:^(NSError * _Nullable error) {
        [downloader1 invalidateSessionAndCancel:YES];
        [downloader2 invalidateSessionAndCancel:YES];
    }];
}

#pragma mark - SDWebImageLoader
- (void)test30CustomImageLoaderWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom image not works"];
    SDWebImageTestLoader *loader = [[SDWebImageTestLoader alloc] init];
    NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
    expect([loader canRequestImageForURL:imageURL]).beTruthy();
    NSError *imageError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    expect([loader shouldBlockFailedURLWithURL:imageURL error:imageError]).equal(NO);
    
    [loader requestImageWithURL:imageURL options:0 context:nil progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        expect(targetURL).notTo.beNil();
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test31ThatLoadersManagerWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Loaders manager not works"];
    SDWebImageTestLoader *loader = [[SDWebImageTestLoader alloc] init];
    SDImageLoadersManager *manager = [[SDImageLoadersManager alloc] init];
    [manager addLoader:loader];
    [manager removeLoader:loader];
    manager.loaders = @[SDWebImageDownloader.sharedDownloader, loader];
    NSURL *imageURL = [NSURL URLWithString:kTestJPEGURL];
    expect([manager canRequestImageForURL:imageURL]).beTruthy();
    NSError *imageError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    expect([manager shouldBlockFailedURLWithURL:imageURL error:imageError]).equal(NO);
    
    [manager requestImageWithURL:imageURL options:0 context:nil progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        expect(targetURL).notTo.beNil();
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(error).to.beNil();
        expect(image).notTo.beNil();
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
}

#pragma mark - Helper

- (NSString *)testPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"png"];
}

@end
