/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#if SD_UIKIT
#import <MobileCoreServices/MobileCoreServices.h>
#endif

@interface SDCategoriesTests : SDTestCase

@end

@implementation SDCategoriesTests

- (void)test01NSDataImageContentTypeCategory {
    // Test invalid image data
    SDImageFormat format = [NSData sd_imageFormatForImageData:nil];
    expect(format == SDImageFormatUndefined);
    
    // Test invalid format
    CFStringRef type = [NSData sd_UTTypeFromImageFormat:SDImageFormatUndefined];
    expect(CFStringCompare(kUTTypePNG, type, 0)).equal(kCFCompareEqualTo);
}

- (void)test02UIImageMultiFormatCategory {
    // Test invalid image data
    UIImage *image = [UIImage sd_imageWithData:nil];
    expect(image).to.beNil();
    // Test image encode
    image = [[UIImage alloc] initWithContentsOfFile:[self testJPEGPath]];
    NSData *data = [image sd_imageData];
    expect(data).notTo.beNil();
    // Test image encode PNG
    data = [image sd_imageDataAsFormat:SDImageFormatPNG];
    expect(data).notTo.beNil();
}

- (void)test03UIImageGIFCategory {
    // Test invalid image data
    UIImage *image = [UIImage sd_imageWithGIFData:nil];
    expect(image).to.beNil();
    // Test valid image data
    NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
    image = [UIImage sd_imageWithGIFData:data];
    expect(image).notTo.beNil();
}

#pragma mark - Helper

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"gif"];
}

@end
