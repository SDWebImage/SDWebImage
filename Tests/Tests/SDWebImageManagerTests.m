//
//  SDWebImageManagerTests.m
//  SDWebImage Tests
//
//  Created by Bogdan Poplauschi on 20/06/14.
//
//

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <XCTestAsync/XCTestAsync.h>
#import <Expecta.h>

#import "SDWebImageManager.h"

static int64_t kAsyncTestTimeout = 5;


@interface SDWebImageManagerTests : XCTestCase

@end

@implementation SDWebImageManagerTests

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

- (void)testThatDownloadInvokesCompletionBlockWithCorrectParamsAsync {
    NSURL *originalImageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.jpg?20120509154705"];
    
    [[SDWebImageManager sharedManager] downloadImageWithURL:originalImageURL options:SDWebImageRefreshCached progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        expect(image).toNot.beNil();
        expect(error).to.beNil();
        expect(originalImageURL).to.equal(imageURL);
        
        XCAsyncSuccess();
    }];
    
    XCAsyncFailAfter(kAsyncTestTimeout, @"Download image timed out");
}

- (void)testThatDownloadWithIncorrectURLInvokesCompletionBlockWithAnErrorAsync {
    NSURL *originalImageURL = [NSURL URLWithString:@"http://static2.dmcdn.net/static/video/656/177/44771656:jpeg_preview_small.png"];
    
    [[SDWebImageManager sharedManager] downloadImageWithURL:originalImageURL options:SDWebImageRefreshCached progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        expect(image).to.beNil();
        expect(error).toNot.beNil();
        expect(originalImageURL).to.equal(imageURL);
        
        XCAsyncSuccess();
    }];
    
    XCAsyncFailAfter(kAsyncTestTimeout, @"Download image timed out");
}

@end
