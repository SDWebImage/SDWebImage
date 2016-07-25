//
//  UIImageMultiFormatTests.m
//  SDWebImage Tests
//
//  Created by Bogdan Poplauschi on 18/07/14.
//
//

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <Expecta.h>

#import "UIImage+MultiFormat.h"


@interface UIImageMultiFormatTests : XCTestCase

@end


@implementation UIImageMultiFormatTests

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

- (void)testImageOrientationFromImageDataWithInvalidData {
    // sync download image
    SEL selector = @selector(sd_imageOrientationFromImageData:);
    
    UIImageOrientation orientation = [[UIImage class] performSelector:selector withObject:nil];
    expect(orientation).to.equal(UIImageOrientationUp);
}

@end
