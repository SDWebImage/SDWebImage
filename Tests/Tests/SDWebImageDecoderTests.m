/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <SDWebImage/SDWebImageImageIOCoder.h>
#import <SDWebImage/SDWebImageWebPCoder.h>
#import <SDWebImage/UIImage+ForceDecode.h>

@interface SDWebImageDecoderTests : SDTestCase

@end

@implementation SDWebImageDecoderTests

- (void)test01ThatDecodedImageWithNilImageReturnsNil {
    expect([UIImage decodedImageWithImage:nil]).to.beNil();
}

- (void)test02ThatDecodedImageWithImageWorksWithARegularJPGImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test03ThatDecodedImageWithImageDoesNotDecodeAnimatedImages {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    UIImage *animatedImage = [UIImage animatedImageWithImages:@[image] duration:0];
    UIImage *decodedImage = [UIImage decodedImageWithImage:animatedImage];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).to.equal(animatedImage);
}

- (void)test04ThatDecodedImageWithImageDoesNotDecodeImagesWithAlpha {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).to.equal(image);
}

- (void)test05ThatDecodedImageWithImageWorksEvenWithMonochromeImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MonochromeTestImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test06ThatDecodeAndScaleDownImageWorks {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage decodedAndScaledDownImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).toNot.equal(image.size.width);
    expect(decodedImage.size.height).toNot.equal(image.size.height);
    expect(decodedImage.size.width * decodedImage.size.height).to.beLessThanOrEqualTo(60 * 1024 * 1024 / 4);    // how many pixels in 60 megs
}

- (void)test07ThatDecodeAndScaleDownImageDoesNotScaleSmallerImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage decodedAndScaledDownImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test08ImageOrientationFromImageDataWithInvalidData {
    // sync download image
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(sd_imageOrientationFromImageData:);
#pragma clang diagnostic pop
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    UIImageOrientation orientation = (UIImageOrientation)[[SDWebImageImageIOCoder class] performSelector:selector withObject:nil];
#pragma clang diagnostic pop
    expect(orientation).to.equal(UIImageOrientationUp);
}

- (void)test09ThatStaticWebPCoderWorks {
    NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"webp"];
    NSData *staticWebPData = [NSData dataWithContentsOfURL:staticWebPURL];
    UIImage *staticWebPImage = [[SDWebImageWebPCoder sharedCoder] decodedImageWithData:staticWebPData];
    expect(staticWebPImage).toNot.beNil();
    
    NSData *outputData = [[SDWebImageWebPCoder sharedCoder] encodedDataWithImage:staticWebPImage format:SDImageFormatWebP];
    expect(outputData).toNot.beNil();
}

- (void)test10ThatAnimatedWebPCoderWorks {
    NSURL *animatedWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"webp"];
    NSData *animatedWebPData = [NSData dataWithContentsOfURL:animatedWebPURL];
    UIImage *animatedWebPImage = [[SDWebImageWebPCoder sharedCoder] decodedImageWithData:animatedWebPData];
    expect(animatedWebPImage).toNot.beNil();
    expect(animatedWebPImage.images.count).to.beGreaterThan(0);
    CGSize imageSize = animatedWebPImage.size;
    CGFloat imageScale = animatedWebPImage.scale;
    [animatedWebPImage.images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        CGSize size = image.size;
        CGFloat scale = image.scale;
        expect(imageSize.width).to.equal(size.width);
        expect(imageSize.height).to.equal(size.height);
        expect(imageScale).to.equal(scale);
    }];
    
    NSData *outputData = [[SDWebImageWebPCoder sharedCoder] encodedDataWithImage:animatedWebPImage format:SDImageFormatWebP];
    expect(outputData).toNot.beNil();
}

@end
