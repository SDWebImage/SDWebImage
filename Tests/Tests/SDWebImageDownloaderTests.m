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
            XCTFail(@"Something went wrong");
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
            XCTFail(@"Something went wrong");
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
            XCTFail(@"Something went wrong");
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
            XCTFail(@"Something went wrong");
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
    
    NSURL *imageURL = [NSURL URLWithString:@"http://via.placeholder.com/1100x1100.png"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL completed:nil];
    expect([SDWebImageDownloader sharedDownloader].currentDownloadCount).to.equal(1);
    
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
            XCTFail(@"Something went wrong");
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
            XCTFail(@"Something went wrong");
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
            XCTFail(@"Something went wrong");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test17ThatMinimumProgressIntervalWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Minimum progress interval"];
    SDWebImageDownloaderConfig *config = SDWebImageDownloaderConfig.defaultDownloaderConfig;
    config.minimumProgressInterval = 0.51; // This will make the progress only callback twice (once is 51%, another is 100%)
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] initWithConfig:config];
    NSURL *imageURL = [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    __block NSUInteger allProgressCount = 0; // All progress (including operation start / first HTTP response, etc)
    __block NSUInteger validProgressCount = 0; // Only progress from `URLSession:dataTask:didReceiveData:`
    [downloader downloadImageWithURL:imageURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
        allProgressCount++;
        if (expectedSize <= 0 || receivedSize <= 0) {
            // ignore the progress callback until we receive data
            return;
        }
        validProgressCount++;
    } completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (allProgressCount > 2 && validProgressCount == 2) {
            [expectation fulfill];
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
            XCTFail(@"Something went wrong");
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
            XCTFail(@"Something went wrong");
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
                                               XCTFail(@"Something went wrong");
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
                                               XCTFail(@"Something went wrong");
                                           }
                                       }];
    expect(token2).toNot.beNil();
    
    [self waitForExpectationsWithCommonTimeout];
}

#if SD_UIKIT
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
        NSData *data1 = UIImagePNGRepresentation(testJPEGImage);
        NSData *data2 = UIImagePNGRepresentation(image);
        if (![data1 isEqualToData:data2]) {
            XCTFail(@"The image data is not equal to cutom decoder, check -[SDWebImageTestDecoder decodedImageWithData:]");
        }
        [[SDImageCodersManager sharedManager] removeCoder:testDecoder];
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
    [downloader invalidateSessionAndCancel:YES];
}
#endif

- (void)test23ThatDownloadRequestModifierWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Download request modifier not works"];
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    SDWebImageDownloaderRequestModifier *requestModifier = [SDWebImageDownloaderRequestModifier requestModifierWithBlock:^NSURLRequest * _Nullable(NSURLRequest * _Nonnull request) {
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

@end
