/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <SDWebImage/NSData+ImageContentType.h>
#if SD_UIKIT
#import <MobileCoreServices/MobileCoreServices.h>
#endif
#import <SDWebImage/UIImage+MultiFormat.h>
#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/UIImage+WebP.h>
#import <SDWebImage/UIImage+Transform.h>
#import <CoreImage/CoreImage.h>

@interface SDCategoriesTests : SDTestCase

@property (nonatomic, strong) UIImage *testImage;

@end

@implementation SDCategoriesTests

- (void)test01NSDataImageContentTypeCategory {
    // Test invalid image data
    SDImageFormat format = [NSData sd_imageFormatForImageData:nil];
    expect(format == SDImageFormatUndefined);
    
    // Test invalid format
    CFStringRef type = [NSData sd_UTTypeFromSDImageFormat:SDImageFormatUndefined];
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
    UIImage *image = [UIImage sd_animatedGIFWithData:nil];
    expect(image).to.beNil();
    // Test valid image data
    NSData *data = [NSData dataWithContentsOfFile:[self testGIFPath]];
    image = [UIImage sd_animatedGIFWithData:data];
    expect(image).notTo.beNil();
}

- (void)test04UIImageWebPCategory {
    // Test invalid image data
    UIImage *image = [UIImage sd_imageWithWebPData:nil];
    expect(image).to.beNil();
    // Test valid image data
    NSData *data = [NSData dataWithContentsOfFile:[self testWebPPath]];
    image = [UIImage sd_imageWithWebPData:data];
    expect(image).notTo.beNil();
}

// UIImage+Transform test is hard to write because it's more about visual effect. Current it's tied to the `TestImage.png`, please keep that image or write new test with new image
- (void)test05UIImageTransformResize {
    CGSize size = CGSizeMake(200, 100);
    UIImage *resizedImage = [self.testImage sd_resizedImageWithSize:size scaleMode:SDImageScaleModeFill];
    expect(CGSizeEqualToSize(resizedImage.size, size)).beTruthy();
}

- (void)test06UIImageTransformCrop {
    CGRect rect = CGRectMake(50, 50, 200, 200);
    UIImage *croppedImage = [self.testImage sd_croppedImageWithRect:rect];
    expect(CGSizeEqualToSize(croppedImage.size, CGSizeMake(200, 200))).beTruthy();
    UIColor *startColor = [croppedImage sd_colorAtPoint:CGPointZero];
    expect([startColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]).beTruthy();
}

- (void)test07UIImageTransformRoundedCorner {
    CGFloat radius = 50;
#if SD_UIKIT
    SDRectCorner corners = UIRectCornerAllCorners;
#else
    SDRectCorner corners = SDRectCornerAllCorners;
#endif
    CGFloat borderWidth = 1;
    UIColor *borderCoder = [UIColor blackColor];
    UIImage *roundedCornerImage = [self.testImage sd_roundedCornerImageWithRadius:radius corners:corners borderWidth:borderWidth borderColor:borderCoder];
    expect(CGSizeEqualToSize(roundedCornerImage.size, CGSizeMake(300, 300))).beTruthy();
    UIColor *startColor = [roundedCornerImage sd_colorAtPoint:CGPointZero];
    expect([startColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]).beTruthy();
    // Check the left center pixel, should be border :)
    UIColor *checkBorderColor = [roundedCornerImage sd_colorAtPoint:CGPointMake(1, 150)];
    expect([checkBorderColor.sd_hexString isEqualToString:borderCoder.sd_hexString]).beTruthy();
}

- (void)test08UIImageTransformRotate {
    CGFloat angle = M_PI_4;
    UIImage *rotatedImage = [self.testImage sd_rotatedImageWithAngle:angle fitSize:NO];
    // Not fit size and no change
    expect(CGSizeEqualToSize(rotatedImage.size, self.testImage.size)).beTruthy();
    // Fit size, may change size
    rotatedImage = [self.testImage sd_rotatedImageWithAngle:angle fitSize:YES];
    CGSize rotatedSize = CGSizeMake(floor(300 * 1.414), floor(300 * 1.414)); // 45º, square length * sqrt(2)
    expect(CGSizeEqualToSize(rotatedImage.size, rotatedSize)).beTruthy();
    rotatedImage = [self.testImage sd_rotatedImageWithAngle:angle fitSize:NO];
}

- (void)test09UIImageTransformFlip {
    BOOL horizontal = YES;
    BOOL vertical = YES;
    UIImage *flippedImage = [self.testImage sd_flippedImageWithHorizontal:horizontal vertical:vertical];
    expect(CGSizeEqualToSize(flippedImage.size, self.testImage.size)).beTruthy();
}

- (void)test10UIImageTransformTint {
    UIColor *tintColor = [UIColor blackColor];
    UIImage *tintedImage = [self.testImage sd_tintedImageWithColor:tintColor];
    expect(CGSizeEqualToSize(tintedImage.size, self.testImage.size)).beTruthy();
    // Check center color, should keep clear
    UIColor *centerColor = [tintedImage sd_colorAtPoint:CGPointMake(150, 150)];
    expect([centerColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]);
    // Check left color, should be tinted
    UIColor *leftColor = [tintedImage sd_colorAtPoint:CGPointMake(80, 150)];
    expect([leftColor.sd_hexString isEqualToString:tintColor.sd_hexString]);
}

- (void)test11UIImageTransformBlur {
    CGFloat radius = 50;
    UIImage *blurredImage = [self.testImage sd_blurredImageWithRadius:radius];
    expect(CGSizeEqualToSize(blurredImage.size, self.testImage.size)).beTruthy();
    // Check left color, should be blurred
    UIColor *leftColor = [blurredImage sd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output
    UIColor *expectedColor = [UIColor colorWithRed:0.431373 green:0.101961 blue:0.0901961 alpha:0.729412];
    expect([leftColor.sd_hexString isEqualToString:expectedColor.sd_hexString]);
}

- (void)test12UIImageTransformFilter {
    // Invert color filter
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    UIImage *filteredImage = [self.testImage sd_filteredImageWithFilter:filter];
    expect(CGSizeEqualToSize(filteredImage.size, self.testImage.size)).beTruthy();
    // Check left color, should be inverted
    UIColor *leftColor = [filteredImage sd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output
    UIColor *expectedColor = [UIColor colorWithRed:0.85098 green:0.992157 blue:0.992157 alpha:1];
    expect([leftColor.sd_hexString isEqualToString:expectedColor.sd_hexString]);
}

#pragma mark - Helper

- (UIImage *)testImage {
    if (!_testImage) {
        _testImage = [[UIImage alloc] initWithContentsOfFile:[self testPNGPath]];
    }
    return _testImage;
}

- (NSString *)testJPEGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"jpg"];
}

- (NSString *)testGIFPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"gif"];
}

- (NSString *)testWebPPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImageStatic" ofType:@"webp"];
}

- (NSString *)testPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"png"];
}

@end
