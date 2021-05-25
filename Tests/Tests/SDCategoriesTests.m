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
    expect(CFStringCompare(kUTTypeImage, type, 0)).equal(kCFCompareEqualTo);
    expect([NSData sd_imageFormatFromUTType:kUTTypeImage]).equal(SDImageFormatUndefined);
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
    // Test image decode PNG
    expect([UIImage sd_imageWithData:data scale:1 firstFrameOnly:YES]).notTo.beNil();
    // Test image encode JPEG with compressionQuality
    NSData *jpegData1 = [image sd_imageDataAsFormat:SDImageFormatJPEG compressionQuality:1];
    NSData *jpegData2 = [image sd_imageDataAsFormat:SDImageFormatJPEG compressionQuality:0.5];
    expect(jpegData1).notTo.beNil();
    expect(jpegData2).notTo.beNil();
    expect(jpegData1.length).notTo.equal(jpegData2.length);
}

- (void)test03UIImageGIFCategory {
    // Test invalid image data
    UIImage *image = [UIImage sd_imageWithGIFData:nil];
    expect(image).to.beNil();
    // Test valid image data
    NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
    image = [UIImage sd_imageWithGIFData:data];
    expect(image).notTo.beNil();
    expect(image.sd_isAnimated).beTruthy();
    expect(image.sd_imageFrameCount).equal(5);
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
