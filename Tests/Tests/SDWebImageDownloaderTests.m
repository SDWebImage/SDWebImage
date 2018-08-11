/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <SDWebImage/SDWebImageDownloader.h>
#import <SDWebImage/SDWebImageDownloaderOperation.h>
#import <SDWebImage/SDWebImageCodersManager.h>
#import "SDWebImageTestDecoder.h"

/**
 *  Category for SDWebImageDownloader so we can access the operationClass
 */
@interface SDWebImageDownloader ()
@property (assign, nonatomic, nullable) Class operationClass;
@property (strong, nonatomic, nonnull) NSOperationQueue *downloadQueue;

- (NSOperation<SDWebImageDownloaderOperationInterface> *)createDownloaderOperationWithUrl:(nullable NSURL *)url options:(SDWebImageDownloaderOptions)options;

@end

/**
 *  A class that fits the NSOperation+SDWebImageDownloaderOperationInterface requirement so we can test
 */
@interface CustomDownloaderOperation : NSOperation<SDWebImageDownloaderOperationInterface>

@property (nonatomic, assign) BOOL shouldDecompressImages;
@property (nonatomic, strong, nullable) NSURLCredential *credential;

@end

@implementation CustomDownloaderOperation

- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)req inSession:(nullable NSURLSession *)ses options:(SDWebImageDownloaderOptions)opt {
    if ((self = [super init])) { }
    return self;
}

- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock {
    return nil;
}

- (BOOL)cancel:(id)token {
    return YES;
}

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
    expect([[SDWebImageDownloader sharedDownloader] valueForHTTPHeaderField:@"Accept"]).to.match(@"image/\\*");
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
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
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
    NSInteger initialValue = [SDWebImageDownloader sharedDownloader].maxConcurrentDownloads;
    
    [[SDWebImageDownloader sharedDownloader] setMaxConcurrentDownloads:3];
    expect([SDWebImageDownloader sharedDownloader].maxConcurrentDownloads).to.equal(3);
    
    [[SDWebImageDownloader sharedDownloader] setMaxConcurrentDownloads:initialValue];
}

- (void)test06ThatUsingACustomDownloaderOperationWorks {
    // we try to set a usual NSOperation as operation class. Should not work
    [[SDWebImageDownloader sharedDownloader] setOperationClass:[NSOperation class]];
    expect([SDWebImageDownloader sharedDownloader].operationClass).to.equal([SDWebImageDownloaderOperation class]);
    
    // setting an NSOperation subclass that conforms to SDWebImageDownloaderOperationInterface - should work
    [[SDWebImageDownloader sharedDownloader] setOperationClass:[CustomDownloaderOperation class]];
    expect([SDWebImageDownloader sharedDownloader].operationClass).to.equal([CustomDownloaderOperation class]);
    
    // back to the original value
    [[SDWebImageDownloader sharedDownloader] setOperationClass:nil];
    expect([SDWebImageDownloader sharedDownloader].operationClass).to.equal([SDWebImageDownloaderOperation class]);
}

- (void)test07ThatDownloadImageWithNilURLCallsCompletionWithNils {
    expect([[SDWebImageDownloader sharedDownloader] createDownloaderOperationWithUrl:nil options:0]).toNot.beNil();
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Completion is called with nils"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:nil options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        expect(image).to.beNil();
        expect(data).to.beNil();
        expect(error).to.beNil();
        [expectation fulfill];
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test08ThatAHTTPAuthDownloadWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"HTTP Auth download"];
    [SDWebImageDownloader sharedDownloader].username = @"httpwatch";
    [SDWebImageDownloader sharedDownloader].password = @"httpwatch01";
    NSURL *imageURL = [NSURL URLWithString:@"http://www.httpwatch.com/httpgallery/authentication/authenticatedimage/default.aspx?0.35786508303135633"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
    [SDWebImageDownloader sharedDownloader].username = nil;
    [SDWebImageDownloader sharedDownloader].password = nil;
}

- (void)test09ThatProgressiveJPEGWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive JPEG download"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderProgressiveDownload progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
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
    
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    SDWebImageDownloadToken *token = [[SDWebImageDownloader sharedDownloader]
                                      downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                          XCTFail(@"Should not get here");
                                      }];
    expect([SDWebImageDownloader sharedDownloader].currentDownloadCount).to.equal(1);
    
    [[SDWebImageDownloader sharedDownloader] cancel:token];
    
    // doesn't cancel immediately - since it uses dispatch async
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kMinDelayNanosecond), dispatch_get_main_queue(), ^{
        expect([SDWebImageDownloader sharedDownloader].currentDownloadCount).to.equal(0);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test12ThatWeCanUseAnotherSessionForEachDownloadOperation {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Owned session"];
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:imageURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
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
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
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

- (void)test15ThatWEBPWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"WEBP"];
    NSURL *imageURL = [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        if (image && data && !error && finished) {
            [expectation fulfill];
        } else {
            XCTFail(@"Something went wrong");
        }
    }];
    [self waitForExpectationsWithCommonTimeout];
}

- (void)test16ThatProgressiveWebPWorks {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Progressive WebP download"];
    NSURL *imageURL = [NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp"];
    [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:imageURL options:SDWebImageDownloaderProgressiveDownload progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
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
    
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    
    SDWebImageDownloadToken *token1 = [[SDWebImageDownloader sharedDownloader]
                                       downloadImageWithURL:imageURL
                                       options:0
                                       progress:nil
                                       completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                           XCTFail(@"Shouldn't have completed here.");
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
    
    [[SDWebImageDownloader sharedDownloader] cancel:token1];
    
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
    
    NSURL *imageURL = [NSURL URLWithString:kTestJpegURL];
    
    SDWebImageDownloadToken *token1 = [[SDWebImageDownloader sharedDownloader]
                                       downloadImageWithURL:imageURL
                                       options:0
                                       progress:nil
                                       completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                           XCTFail(@"Shouldn't have completed here.");
                                       }];
    expect(token1).toNot.beNil();
    
    [[SDWebImageDownloader sharedDownloader] cancel:token1];
    
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

- (void)test22ThatCustomDecoderWorksForImageDownload {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Custom decoder for SDWebImageDownloader not works"];
    SDWebImageDownloader *downloader = [[SDWebImageDownloader alloc] init];
    SDWebImageTestDecoder *testDecoder = [[SDWebImageTestDecoder alloc] init];
    [[SDWebImageCodersManager sharedInstance] addCoder:testDecoder];
    NSURL * testImageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"png"];
    
    // Decoded result is JPEG
    NSString *testJPEGImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *testJPEGImage = [UIImage imageWithContentsOfFile:testJPEGImagePath];
    
    [downloader downloadImageWithURL:testImageURL options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        NSData *data1 = UIImagePNGRepresentation(testJPEGImage);
        NSData *data2 = UIImagePNGRepresentation(image);
        if (![data1 isEqualToData:data2]) {
            XCTFail(@"The image data is not equal to cutom decoder, check -[SDWebImageTestDecoder decodedImageWithData:]");
        }
        NSString *str1 = @"TestDecompress";
        NSString *str2 = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (![str1 isEqualToString:str2]) {
            XCTFail(@"The image data is not modified by the custom decoder, check -[SDWebImageTestDecoder decompressedImageWithImage:data:options:]");
        }
        [[SDWebImageCodersManager sharedInstance] removeCoder:testDecoder];
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithCommonTimeout];
    [downloader invalidateSessionAndCancel:YES];
}

@end

