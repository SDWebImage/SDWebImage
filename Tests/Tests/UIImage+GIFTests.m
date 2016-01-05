//
//  UIImage+GIFTests.m
//  SDWebImage Tests
//
//  Created by Tyler Hedrick on 1/5/16.
//
//

#import <XCTest/XCTest.h>
#import <ImageIO/ImageIO.h>

#import "UIImage+GIF.h"

@interface UIImage_GIFTests : XCTestCase

@end

@implementation UIImage_GIFTests

- (void)testMalformedGIFDataDoesNotCrash {
  NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
  NSString *testBundlePath = [testBundle pathForResource:@"corrupt" ofType:@"gif"];
  NSData *data = [NSData dataWithContentsOfFile:testBundlePath];

  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
  size_t count = CGImageSourceGetCount(source);
  XCTAssertEqual(count, 2);
  CFRelease(source);

  XCTAssertNoThrow([UIImage sd_animatedGIFWithData:data]);
  UIImage *image = [UIImage sd_animatedGIFWithData:data];
  XCTAssertEqual(image.images.count, 1);
}

@end
