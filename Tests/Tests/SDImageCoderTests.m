/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"

@interface SDWebImageDecoderTests : SDTestCase

@end

@implementation SDWebImageDecoderTests

- (void)test01ThatDecodedImageWithNilImageReturnsNil {
    expect([UIImage sd_decodedImageWithImage:nil]).to.beNil();
    expect([UIImage sd_decodedAndScaledDownImageWithImage:nil]).to.beNil();
}

#if SD_UIKIT
- (void)test02ThatDecodedImageWithImageWorksWithARegularJPGImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test03ThatDecodedImageWithImageDoesNotDecodeAnimatedImages {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *animatedImage = [UIImage animatedImageWithImages:@[image] duration:0];
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:animatedImage];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).to.equal(animatedImage);
}

- (void)test04ThatDecodedImageWithImageWorksWithAlphaImages {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
}

- (void)test05ThatDecodedImageWithImageWorksEvenWithMonochromeImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MonochromeTestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test06ThatDecodeAndScaleDownImageWorks {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedAndScaledDownImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).toNot.equal(image.size.width);
    expect(decodedImage.size.height).toNot.equal(image.size.height);
    expect(decodedImage.size.width * decodedImage.size.height).to.beLessThanOrEqualTo(60 * 1024 * 1024 / 4);    // how many pixels in 60 megs
}

- (void)test07ThatDecodeAndScaleDownImageDoesNotScaleSmallerImage {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedAndScaledDownImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}
#endif

- (void)test11ThatAPNGPCoderWorks {
    NSURL *APNGURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"apng"];
    [self verifyCoder:[SDImageAPNGCoder sharedCoder]
    withLocalImageURL:APNGURL
     supportsEncoding:YES
      isAnimatedImage:YES];
}

- (void)test12ThatGIFCoderWorks {
    NSURL *gifURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"gif"];
    [self verifyCoder:[SDImageGIFCoder sharedCoder]
    withLocalImageURL:gifURL
     supportsEncoding:YES
      isAnimatedImage:YES];
}

- (void)test13ThatHEICWorks {
    if (@available(iOS 11, macOS 10.13, *)) {
        NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"heic"];
#if SD_UIKIT
        BOOL supportsEncoding = YES; // iPhone Simulator after Xcode 9.3 support HEIC encoding
#else
        BOOL supportsEncoding = NO; // Travis-CI Mac env currently does not support HEIC encoding
#endif
        [self verifyCoder:[SDImageIOCoder sharedCoder]
        withLocalImageURL:heicURL
         supportsEncoding:supportsEncoding
          isAnimatedImage:NO];
    }
}

- (void)test14ThatHEIFWorks {
    if (@available(iOS 11, macOS 10.13, *)) {
        NSURL *heifURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"heif"];
        [self verifyCoder:[SDImageIOCoder sharedCoder]
        withLocalImageURL:heifURL
         supportsEncoding:NO
          isAnimatedImage:NO];
    }
}

- (void)test15ThatCodersManagerWorks {
    SDImageCodersManager *manager = [[SDImageCodersManager alloc] init];
    manager.coders = @[SDImageIOCoder.sharedCoder];
    expect([manager canDecodeFromData:nil]).beTruthy(); // Image/IO will return YES for future format
    expect([manager decodedImageWithData:nil options:nil]).beNil();
    expect([manager canEncodeToFormat:SDImageFormatWebP]).beFalsy();
    expect([manager encodedDataWithImage:nil format:SDImageFormatUndefined options:nil]).beNil();
}

- (void)verifyCoder:(id<SDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
    isAnimatedImage:(BOOL)isAnimated {
    NSData *inputImageData = [NSData dataWithContentsOfURL:imageUrl];
    expect(inputImageData).toNot.beNil();
    SDImageFormat inputImageFormat = [NSData sd_imageFormatForImageData:inputImageData];
    expect(inputImageFormat).toNot.equal(SDImageFormatUndefined);
    
    // 1 - check if we can decode - should be true
    expect([coder canDecodeFromData:inputImageData]).to.beTruthy();
    
    // 2 - decode from NSData to UIImage and check it
    UIImage *inputImage = [coder decodedImageWithData:inputImageData options:nil];
    expect(inputImage).toNot.beNil();
    
    if (isAnimated) {
        // 2a - check images count > 0 (only for animated images)
        expect(inputImage.sd_isAnimated).to.beTruthy();
        
        // 2b - check image size and scale for each frameImage (only for animated images)
#if SD_UIKIT
        CGSize imageSize = inputImage.size;
        CGFloat imageScale = inputImage.scale;
        [inputImage.images enumerateObjectsUsingBlock:^(UIImage * frameImage, NSUInteger idx, BOOL * stop) {
            expect(imageSize).to.equal(frameImage.size);
            expect(imageScale).to.equal(frameImage.scale);
        }];
#endif
    }
    
    if (supportsEncoding) {
        // 3 - check if we can encode to the original format
        expect([coder canEncodeToFormat:inputImageFormat]).to.beTruthy();
        
        // 4 - encode from UIImage to NSData using the inputImageFormat and check it
        NSData *outputImageData = [coder encodedDataWithImage:inputImage format:inputImageFormat options:nil];
        expect(outputImageData).toNot.beNil();
        UIImage *outputImage = [coder decodedImageWithData:outputImageData options:nil];
        expect(outputImage.size).to.equal(inputImage.size);
        expect(outputImage.scale).to.equal(inputImage.scale);
#if SD_UIKIT
        expect(outputImage.images.count).to.equal(inputImage.images.count);
#endif
    }
}

@end
