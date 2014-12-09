//
//  SDImageCacheTests.m
//  SDWebImage Tests
//
//  Created by Bogdan Poplauschi on 20/06/14.
//
//

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <Expecta.h>

#import "SDImageCache.h"


@interface SDImageCacheTests : XCTestCase

@end

@implementation SDImageCacheTests

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

- (void)testSharedImageCache {
    SDImageCache *sharedImageCache = [SDImageCache sharedImageCache];
    
    expect(sharedImageCache).toNot.beNil();
}

@end
