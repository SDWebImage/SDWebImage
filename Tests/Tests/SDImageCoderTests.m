/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import "UIColor+SDHexString.h"

@interface SDWebImageDecoderTests : SDTestCase

@end

@implementation SDWebImageDecoderTests

- (void)test01ThatDecodedImageWithNilImageReturnsNil {
    expect([UIImage sd_decodedImageWithImage:nil]).to.beNil();
    expect([UIImage sd_decodedAndScaledDownImageWithImage:nil]).to.beNil();
}

- (void)test02ThatDecodedImageWithImageWorksWithARegularJPGImage {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test03ThatDecodedImageWithImageDoesNotDecodeAnimatedImages {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
#if SD_MAC
    UIImage *animatedImage = image;
#else
    UIImage *animatedImage = [UIImage animatedImageWithImages:@[image] duration:0];
#endif
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:animatedImage];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).to.equal(animatedImage);
}

- (void)test04ThatDecodedImageWithImageWorksWithAlphaImages {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
}

- (void)test05ThatDecodedImageWithImageWorksEvenWithMonochromeImage {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MonochromeTestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test06ThatDecodeAndScaleDownImageWorks {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedAndScaledDownImageWithImage:image limitBytes:(60 * 1024 * 1024)];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).toNot.equal(image.size.width);
    expect(decodedImage.size.height).toNot.equal(image.size.height);
    expect(decodedImage.size.width * decodedImage.size.height).to.beLessThanOrEqualTo(60 * 1024 * 1024 / 4);    // how many pixels in 60 megs
}

- (void)test07ThatDecodeAndScaleDownImageDoesNotScaleSmallerImage {
    // check when user use the larget bytes than image pixels byets, we do not scale up the image (defaults 60MB means 3965x3965 pixels)
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedAndScaledDownImageWithImage:image];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
}

- (void)test07ThatDecodeAndScaleDownImageScaleSmallerBytes {
    // Check when user provide too small bytes, we scale it down to 1x1, but not return the force decoded original size image
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIImage *decodedImage = [UIImage sd_decodedAndScaledDownImageWithImage:image limitBytes:1];
    expect(decodedImage).toNot.beNil();
    expect(decodedImage).toNot.equal(image);
    expect(decodedImage.size.width).to.equal(1);
    expect(decodedImage.size.height).to.equal(1);
}

- (void)test08ThatEncodeAlphaImageToJPGWithBackgroundColor {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"png"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    UIColor *backgroundColor = [UIColor blackColor];
    NSData *encodedData = [SDImageCodersManager.sharedManager encodedDataWithImage:image format:SDImageFormatJPEG options:@{SDImageCoderEncodeBackgroundColor : backgroundColor}];
    expect(encodedData).notTo.beNil();
    UIImage *decodedImage = [SDImageCodersManager.sharedManager decodedImageWithData:encodedData options:nil];
    expect(decodedImage).notTo.beNil();
    expect(decodedImage.size.width).to.equal(image.size.width);
    expect(decodedImage.size.height).to.equal(image.size.height);
    // Check background color, should not be white but the black color
    UIColor *testColor = [decodedImage sd_colorAtPoint:CGPointMake(1, 1)];
    expect(testColor.sd_hexString).equal(backgroundColor.sd_hexString);
}

- (void)test09ThatJPGImageEncodeWithMaxFileSize {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    // This large JPEG encoding size between (770KB ~ 2.23MB)
    NSUInteger limitFileSize = 1 * 1024 * 1024; // 1MB
    // 100 quality (biggest)
    NSData *maxEncodedData = [SDImageCodersManager.sharedManager encodedDataWithImage:image format:SDImageFormatJPEG options:nil];
    expect(maxEncodedData).notTo.beNil();
    expect(maxEncodedData.length).beGreaterThan(limitFileSize);
    // 0 quality (smallest)
    NSData *minEncodedData = [SDImageCodersManager.sharedManager encodedDataWithImage:image format:SDImageFormatJPEG options:@{SDImageCoderEncodeCompressionQuality : @(0)}];
    expect(minEncodedData).notTo.beNil();
    expect(minEncodedData.length).beLessThan(limitFileSize);
    NSData *limitEncodedData = [SDImageCodersManager.sharedManager encodedDataWithImage:image format:SDImageFormatJPEG options:@{SDImageCoderEncodeMaxFileSize : @(limitFileSize)}];
    expect(limitEncodedData).notTo.beNil();
    // So, if we limit the file size, the output data should in (770KB ~ 2.23MB)
    expect(limitEncodedData.length).beLessThan(maxEncodedData.length);
    expect(limitEncodedData.length).beGreaterThan(minEncodedData.length);
}

- (void)test10ThatAnimatedImageCacheImmediatelyWorks {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"png"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    
    // Check that animated image rendering should not use lazy decoding (performance related)
    CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent();
    SDImageAPNGCoder *coder = [[SDImageAPNGCoder alloc] initWithAnimatedImageData:testImageData options:@{SDImageCoderDecodeFirstFrameOnly : @(NO)}];
    UIImage *imageWithoutLazyDecoding = [coder animatedImageFrameAtIndex:0];
    CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime duration = end - begin;
    expect(imageWithoutLazyDecoding.sd_isDecoded).beTruthy();
    
    // Check that static image rendering should use lazy decoding
    CFAbsoluteTime begin2 = CFAbsoluteTimeGetCurrent();
    SDImageAPNGCoder *coder2 = SDImageAPNGCoder.sharedCoder;
    UIImage *imageWithLazyDecoding = [coder2 decodedImageWithData:testImageData options:@{SDImageCoderDecodeFirstFrameOnly : @(YES)}];
    CFAbsoluteTime end2 = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime duration2 = end2 - begin2;
    expect(imageWithLazyDecoding.sd_isDecoded).beFalsy();
    
    // lazy decoding need less time (10x)
    expect(duration2 * 10.0).beLessThan(duration);
}

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

- (void)test12ThatGIFWithoutLoopCountPlayOnce {
    // When GIF metadata does not contains any loop count information (`kCGImagePropertyGIFLoopCount`'s value nil)
    // The standard says it should just play once. See: http://www6.uniovi.es/gifanim/gifabout.htm
    // This behavior is different from other modern animated image format like APNG/WebP. Which will play infinitely
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestLoopCount" ofType:@"gif"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    UIImage *image = [SDImageGIFCoder.sharedCoder decodedImageWithData:testImageData options:nil];
    expect(image.sd_imageLoopCount).equal(1);
}

- (void)test13ThatHEICWorks {
    if (@available(iOS 11, tvOS 11, macOS 10.13, *)) {
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
    if (@available(iOS 11, tvOS 11, macOS 10.13, *)) {
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
    expect([manager canEncodeToFormat:SDImageFormatUndefined]).beTruthy(); // Image/IO will return YES for future format
    expect([manager encodedDataWithImage:nil format:SDImageFormatUndefined options:nil]).beNil();
}

- (void)test16ThatHEICAnimatedWorks {
    if (@available(iOS 13, tvOS 13, macOS 10.15, *)) {
        NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"heic"];
#if SD_UIKIT
        BOOL isAnimatedImage = YES;
        BOOL supportsEncoding = YES; // iPhone Simulator after Xcode 9.3 support HEIC encoding
#else
        BOOL isAnimatedImage = NO; // Travis-CI Mac env does not upgrade to macOS 10.15
        BOOL supportsEncoding = NO; // Travis-CI Mac env currently does not support HEIC encoding
#endif
        [self verifyCoder:[SDImageHEICCoder sharedCoder]
        withLocalImageURL:heicURL
         supportsEncoding:supportsEncoding
           encodingFormat:SDImageFormatHEIC
          isAnimatedImage:isAnimatedImage
            isVectorImage:NO];
    }
}

- (void)test17ThatPDFWorks {
    NSURL *pdfURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"pdf"];
    [self verifyCoder:[SDImageIOCoder sharedCoder]
    withLocalImageURL:pdfURL
     supportsEncoding:NO
       encodingFormat:SDImageFormatUndefined
      isAnimatedImage:NO
        isVectorImage:YES];
}

- (void)test18ThatStaticWebPWorks {
    if (@available(iOS 14, tvOS 14, macOS 11, *)) {
        NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageStatic" withExtension:@"webp"];
        [self verifyCoder:[SDImageAWebPCoder sharedCoder]
        withLocalImageURL:staticWebPURL
         supportsEncoding:NO // Currently (iOS 14.0) seems no encoding support
           encodingFormat:SDImageFormatWebP
          isAnimatedImage:NO
            isVectorImage:NO];
    }
}

- (void)test19ThatAnimatedWebPWorks {
    if (@available(iOS 14, tvOS 14, macOS 11, *)) {
        NSURL *staticWebPURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"webp"];
        [self verifyCoder:[SDImageAWebPCoder sharedCoder]
        withLocalImageURL:staticWebPURL
         supportsEncoding:NO // Currently (iOS 14.0) seems no encoding support
           encodingFormat:SDImageFormatWebP
          isAnimatedImage:YES
            isVectorImage:NO];
    }
}

- (void)test20ThatImageIOAnimatedCoderAbstractClass {
    SDImageIOAnimatedCoder *coder = [[SDImageIOAnimatedCoder alloc] init];
    @try {
        [coder canEncodeToFormat:SDImageFormatPNG];
        XCTFail("Should throw exception");
    } @catch (NSException *exception) {
        expect(exception);
    }
}

- (void)test21ThatEmbedThumbnailHEICWorks {
    if (@available(iOS 11, tvOS 11, macOS 10.13, *)) {
        // The input HEIC does not contains any embed thumbnail
        NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"heic"];
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)heicURL, nil);
        expect(source).notTo.beNil();
        NSArray *thumbnailImages = [self thumbnailImagesFromImageSource:source];
        expect(thumbnailImages.count).equal(0);
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, 0, nil);
#if SD_UIKIT
        UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation: UIImageOrientationUp];
#else
        UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:1 orientation:kCGImagePropertyOrientationUp];
#endif
        CGImageRelease(imageRef);
        // Encode with embed thumbnail
        NSData *encodedData = [SDImageIOCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatHEIC options:@{SDImageCoderEncodeEmbedThumbnail : @(YES)}];
        
        // The new HEIC contains one embed thumbnail
        CGImageSourceRef source2 = CGImageSourceCreateWithData((__bridge CFDataRef)encodedData, nil);
        expect(source2).notTo.beNil();
        NSArray *thumbnailImages2 = [self thumbnailImagesFromImageSource:source2];
        expect(thumbnailImages2.count).equal(1);
        
        // Currently ImageIO has no control to custom embed thumbnail pixel size, just check the behavior :)
        NSDictionary *thumbnailImageInfo = thumbnailImages2.firstObject;
        NSUInteger thumbnailWidth = [thumbnailImageInfo[(__bridge NSString *)kCGImagePropertyWidth] unsignedIntegerValue];
        NSUInteger thumbnailHeight = [thumbnailImageInfo[(__bridge NSString *)kCGImagePropertyHeight] unsignedIntegerValue];
        expect(thumbnailWidth).equal(320);
        expect(thumbnailHeight).equal(212);
    }
}

#pragma mark - Utils

- (void)verifyCoder:(id<SDImageCoder>)coder
withLocalImageURL:(NSURL *)imageUrl
 supportsEncoding:(BOOL)supportsEncoding
  isAnimatedImage:(BOOL)isAnimated {
    [self verifyCoder:coder withLocalImageURL:imageUrl supportsEncoding:supportsEncoding encodingFormat:SDImageFormatUndefined isAnimatedImage:isAnimated isVectorImage:NO];
}

- (void)verifyCoder:(id<SDImageCoder>)coder
  withLocalImageURL:(NSURL *)imageUrl
   supportsEncoding:(BOOL)supportsEncoding
     encodingFormat:(SDImageFormat)encodingFormat
    isAnimatedImage:(BOOL)isAnimated
      isVectorImage:(BOOL)isVector {
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
    
    // 3 - check thumbnail decoding
    CGFloat pixelWidth = inputImage.size.width;
    CGFloat pixelHeight = inputImage.size.height;
    expect(pixelWidth).beGreaterThan(0);
    expect(pixelHeight).beGreaterThan(0);
    // check vector format supports thumbnail with screen size
    if (isVector) {
#if SD_UIKIT
        CGFloat maxScreenSize = MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
#else
        CGFloat maxScreenSize = MAX(NSScreen.mainScreen.frame.size.width, NSScreen.mainScreen.frame.size.height);
#endif
        expect(pixelWidth).equal(maxScreenSize);
        expect(pixelHeight).equal(maxScreenSize);
    }
    
    // check thumbnail with scratch
    CGFloat thumbnailWidth = 50;
    CGFloat thumbnailHeight = 50;
    UIImage *thumbImage = [coder decodedImageWithData:inputImageData options:@{
        SDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        SDImageCoderDecodePreserveAspectRatio : @(NO)
    }];
    expect(thumbImage).toNot.beNil();
    expect(thumbImage.size).equal(CGSizeMake(thumbnailWidth, thumbnailHeight));
    // check thumbnail with aspect ratio limit
    thumbImage = [coder decodedImageWithData:inputImageData options:@{
        SDImageCoderDecodeThumbnailPixelSize : @(CGSizeMake(thumbnailWidth, thumbnailHeight)),
        SDImageCoderDecodePreserveAspectRatio : @(YES)
    }];
    expect(thumbImage).toNot.beNil();
    CGFloat ratio = pixelWidth / pixelHeight;
    CGFloat thumbnailRatio = thumbnailWidth / thumbnailHeight;
    CGSize thumbnailPixelSize;
    if (ratio > thumbnailRatio) {
        thumbnailPixelSize = CGSizeMake(thumbnailWidth, round(thumbnailWidth / ratio));
    } else {
        thumbnailPixelSize = CGSizeMake(round(thumbnailHeight * ratio), thumbnailHeight);
    }
    // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
    expect(ABS(thumbImage.size.width - thumbnailPixelSize.width)).beLessThanOrEqualTo(1);
    expect(ABS(thumbImage.size.height - thumbnailPixelSize.height)).beLessThanOrEqualTo(1);
    
    
    if (supportsEncoding) {
        // 4 - check if we can encode to the original format
        if (encodingFormat == SDImageFormatUndefined) {
            encodingFormat = inputImageFormat;
        }
        expect([coder canEncodeToFormat:encodingFormat]).to.beTruthy();
        
        // 5 - encode from UIImage to NSData using the inputImageFormat and check it
        NSData *outputImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:nil];
        expect(outputImageData).toNot.beNil();
        UIImage *outputImage = [coder decodedImageWithData:outputImageData options:nil];
        expect(outputImage.size).to.equal(inputImage.size);
        expect(outputImage.scale).to.equal(inputImage.scale);
#if SD_UIKIT
        expect(outputImage.images.count).to.equal(inputImage.images.count);
#endif
        
        // check max pixel size encoding with scratch
        CGFloat maxWidth = 50;
        CGFloat maxHeight = 50;
        CGFloat maxRatio = maxWidth / maxHeight;
        CGSize maxPixelSize;
        if (ratio > maxRatio) {
            maxPixelSize = CGSizeMake(maxWidth, round(maxWidth / ratio));
        } else {
            maxPixelSize = CGSizeMake(round(maxHeight * ratio), maxHeight);
        }
        NSData *outputMaxImageData = [coder encodedDataWithImage:inputImage format:encodingFormat options:@{SDImageCoderEncodeMaxPixelSize : @(CGSizeMake(maxWidth, maxHeight))}];
        UIImage *outputMaxImage = [coder decodedImageWithData:outputMaxImageData options:nil];
        // Image/IO's thumbnail API does not always use round to preserve precision, we check ABS <= 1
        expect(ABS(outputMaxImage.size.width - maxPixelSize.width)).beLessThanOrEqualTo(1);
        expect(ABS(outputMaxImage.size.height - maxPixelSize.height)).beLessThanOrEqualTo(1);
#if SD_UIKIT
        expect(outputMaxImage.images.count).to.equal(inputImage.images.count);
#endif
    }
}

- (NSArray *)thumbnailImagesFromImageSource:(CGImageSourceRef)source API_AVAILABLE(ios(11.0), tvos(11.0), macos(13.0)) {
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
    NSDictionary *fileProperties = properties[(__bridge NSString *)kCGImagePropertyFileContentsDictionary];
    NSArray *imagesProperties = fileProperties[(__bridge NSString *)kCGImagePropertyImages];
    NSDictionary *imageProperties = imagesProperties.firstObject;
    NSArray *thumbnailImages = imageProperties[(__bridge NSString *)kCGImagePropertyThumbnailImages];
    
    return thumbnailImages;
}

@end
