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

-(void)test07ThatDecodeAndScaleDownAlwaysCompleteRendering {
    // Check that when the height of the image used is not evenly divisible by the height of the tile, the output image can also be rendered completely.
    
    // Check that when the height of the image used will led to loss of precision. the output image can also be rendered completely,
    
    UIColor *imageColor = UIColor.blackColor;
    CGSize imageSize = CGSizeMake(1029, 1029);
    CGRect imageRect = CGRectMake(0, 0, imageSize.width, imageSize.height);
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = 1;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:imageSize format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetFillColorWithColor(context, [imageColor CGColor]);
        CGContextFillRect(context, imageRect);
    }];
    
    UIImage *decodedImage = [UIImage sd_decodedAndScaledDownImageWithImage:image limitBytes:1 * 1024 * 1024];
    UIColor *testColor1 = [decodedImage sd_colorAtPoint:CGPointMake(0, decodedImage.size.height - 1)];
    UIColor *testColor2 = [decodedImage sd_colorAtPoint:CGPointMake(0, decodedImage.size.height - 9)];
    expect(testColor1.sd_hexString).equal(imageColor.sd_hexString);
    expect(testColor2.sd_hexString).equal(imageColor.sd_hexString);
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
    NSData *minEncodedData = [SDImageCodersManager.sharedManager encodedDataWithImage:image format:SDImageFormatJPEG options:@{SDImageCoderEncodeCompressionQuality : @(0.01)}]; // Seems 0 has some bugs in old macOS
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
#if SD_MAC
        BOOL supportsEncoding = !SDTestCase.isCI; // GitHub Action Mac env currently does not support HEIC encoding
#else
        BOOL supportsEncoding = YES; // GitHub Action Mac env with simulator, supported from 20240707.1
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
        BOOL supportsEncoding = NO; // public.heif UTI alwsays return false, use public.heic
        [self verifyCoder:[SDImageIOCoder sharedCoder]
        withLocalImageURL:heifURL
         supportsEncoding:supportsEncoding
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
        NSURL *heicURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImageAnimated" withExtension:@"heics"];
        BOOL supportsEncoding = !SDTestCase.isCI; // GitHub Action Mac env currently does not support HEICS animated encoding (but HEIC supported, I don't know why)
        // See: #3227
        BOOL isAnimatedImage = YES;
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

#if !SD_TV
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
#endif

#if !SD_TV
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
#endif

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
#if SD_MAC
    BOOL supportsEncoding = !SDTestCase.isCI; // GitHub Action Mac env currently does not support HEIC encoding
#else
    BOOL supportsEncoding = YES; // GitHub Action Mac env with simulator, supported from 20240707.1
#endif
    if (!supportsEncoding) {
        return;
    }
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

- (void)test22ThatThumbnailDecodeCalculation {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    CGSize thumbnailSize = CGSizeMake(400, 300);
    UIImage *image = [SDImageIOCoder.sharedCoder decodedImageWithData:testImageData options:@{
        SDImageCoderDecodePreserveAspectRatio: @(YES),
        SDImageCoderDecodeThumbnailPixelSize: @(thumbnailSize)}];
    CGSize imageSize = image.size;
    expect(imageSize.width).equal(400);
    expect(imageSize.height).equal(263);
    // `CGImageSourceCreateThumbnailAtIndex` should always produce non-lazy CGImage
    CGImageRef cgImage = image.CGImage;
    expect([SDImageCoderHelper CGImageIsLazy:cgImage]).beFalsy();
    expect(image.sd_isDecoded).beTruthy();
}

- (void)test23ThatThumbnailEncodeCalculation {
    NSString *testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImageLarge" ofType:@"jpg"];
    NSData *testImageData = [NSData dataWithContentsOfFile:testImagePath];
    UIImage *image = [SDImageIOCoder.sharedCoder decodedImageWithData:testImageData options:nil];
    expect(image.size).equal(CGSizeMake(5250, 3450));
    // `CGImageSourceCreateImageAtIndex` should always produce lazy CGImage
    CGImageRef cgImage = image.CGImage;
    expect([SDImageCoderHelper CGImageIsLazy:cgImage]).beTruthy();
    expect(image.sd_isDecoded).beFalsy();
    CGSize thumbnailSize = CGSizeMake(4000, 4000); // 3450 < 4000 < 5250
    NSData *encodedData = [SDImageIOCoder.sharedCoder encodedDataWithImage:image format:SDImageFormatJPEG options:@{
            SDImageCoderEncodeMaxPixelSize: @(thumbnailSize)
    }];
    UIImage *encodedImage = [UIImage sd_imageWithData:encodedData];
    expect(encodedImage.size).equal(CGSizeMake(4000, 2629));
}

- (void)test24ThatScaleSizeCalculation {
    // preserveAspectRatio true
    CGSize size1 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:YES shouldScaleUp:NO];
    expect(size1).equal(CGSizeMake(75, 150));
    CGSize size2 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:YES shouldScaleUp:YES];
    expect(size2).equal(CGSizeMake(75, 150));
    CGSize size3 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(300, 300) preserveAspectRatio:YES shouldScaleUp:NO];
    expect(size3).equal(CGSizeMake(100, 200));
    CGSize size4 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(300, 300) preserveAspectRatio:YES shouldScaleUp:YES];
    expect(size4).equal(CGSizeMake(150, 300));
    
    // preserveAspectRatio false
    CGSize size5 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:NO shouldScaleUp:NO];
    expect(size5).equal(CGSizeMake(100, 150));
    CGSize size6 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(100, 200) scaleSize:CGSizeMake(150, 150) preserveAspectRatio:NO shouldScaleUp:YES];
    expect(size6).equal(CGSizeMake(150, 150));
    
    // 0 value
    CGSize size7 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(0, 0) scaleSize:CGSizeMake(999, 999) preserveAspectRatio:NO shouldScaleUp:NO];
    expect(size7).equal(CGSizeMake(0, 0));
    CGSize size8 = [SDImageCoderHelper scaledSizeWithImageSize:CGSizeMake(999, 999) scaleSize:CGSizeMake(0, 0) preserveAspectRatio:NO shouldScaleUp:NO];
    expect(size8).equal(CGSizeMake(999, 999));
}

- (void)test25ThatBMPWorks {
    NSURL *bmpURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"bmp"];
    [self verifyCoder:[SDImageIOCoder sharedCoder]
    withLocalImageURL:bmpURL
     supportsEncoding:YES
       encodingFormat:SDImageFormatBMP
      isAnimatedImage:NO
        isVectorImage:NO];
}

- (void)test26ThatRawImageTypeHintWorks {
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"nef"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    // 1. Test without hint will use TIFF's IFD#0, which size should always be 160x120, see: http://lclevy.free.fr/nef/
    UIImage *image1 = [SDImageIOCoder.sharedCoder decodedImageWithData:data options:nil];
    expect(image1.size).equal(CGSizeMake(160, 120));
    expect(image1.sd_imageFormat).equal(SDImageFormatTIFF);
    
#if SD_MAC || SD_IOS
    // 2. Test with NEF file extension should be NEF
    UIImage *image2 = [SDImageIOCoder.sharedCoder decodedImageWithData:data options:@{SDImageCoderDecodeFileExtensionHint : @"nef"}];
    expect(image2.size).equal(CGSizeMake(3008, 2000));
    expect(image2.sd_imageFormat).equal(SDImageFormatRAW);
    
    // 3. Test with UTType hint should be NEF
    UIImage *image3 = [SDImageIOCoder.sharedCoder decodedImageWithData:data options:@{SDImageCoderDecodeTypeIdentifierHint : @"com.nikon.raw-image"}];
    expect(image3.size).equal(CGSizeMake(3008, 2000));
    expect(image3.sd_imageFormat).equal(SDImageFormatRAW);
#endif
}

- (void)test27ThatEncodeWithFramesWorks {
    // Mock
    NSMutableArray<SDImageFrame *> *frames = [NSMutableArray array];
    NSUInteger frameCount = 5;
    for (size_t i = 0; i < frameCount; i++) {
        CGSize size = CGSizeMake(100, 100);
        SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:size];
        UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
            CGContextSetRGBFillColor(context, 1.0 / i, 0.0, 0.0, 1.0);
            CGContextSetRGBStrokeColor(context, 1.0 / i, 0.0, 0.0, 1.0);
            CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
        }];
        SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:0.1];
        [frames addObject:frame];
    }
    
    // Test old API
    UIImage *animatedImage = [SDImageCoderHelper animatedImageWithFrames:frames];
    NSData *data = [SDImageGIFCoder.sharedCoder encodedDataWithImage:animatedImage format:SDImageFormatGIF options:nil];
    expect(data).notTo.beNil();

#if SD_MAC
    // Test implementation use SDAnimatedImageRep
    SDAnimatedImageRep *rep = (SDAnimatedImageRep *)animatedImage.representations.firstObject;
    expect([rep isKindOfClass:SDAnimatedImageRep.class]);
    expect(rep.animatedImageData).equal(data);
    expect(rep.animatedImageFormat).equal(SDImageFormatGIF);
#endif
    
    // Test new API
    NSData *data2 = [SDImageGIFCoder.sharedCoder encodedDataWithFrames:frames loopCount:0 format:SDImageFormatGIF options:nil];
    expect(data2).notTo.beNil();
}

- (void)test28ThatNotTriggerCACopyImage {
    // 10 * 8 pixels, RGBA8888
    size_t width = 10;
    size_t height = 8;
    size_t bitsPerComponent = 8;
    size_t components = 4;
    size_t bitsPerPixel = bitsPerComponent * components;
    size_t bytesPerRow = SDByteAlign(bitsPerPixel / 8 * width, [SDImageCoderHelper preferredPixelFormat:YES].alignment);
    size_t size = bytesPerRow * height;
    uint8_t bitmap[size];
    for (size_t i = 0; i < size; i++) {
        bitmap[i] = 255;
    }
    CGColorSpaceRef colorspace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    CGBitmapInfo bitmapInfo = [SDImageCoderHelper preferredPixelFormat:YES].bitmapInfo;
    CFDataRef data = CFDataCreate(NULL, bitmap, size);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CFRelease(data);
    BOOL shouldInterpolate = YES;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, shouldInterpolate, intent);
    CGDataProviderRelease(provider);
    XCTAssert(cgImage);
    BOOL result = [SDImageCoderHelper CGImageIsHardwareSupported:cgImage];
    // Since it's 32 bytes aligned, return true
    XCTAssertTrue(result);
    // Let's force-decode to check again
#if SD_MAC
    UIImage *image = [[UIImage alloc] initWithCGImage:cgImage scale:1 orientation:kCGImagePropertyOrientationUp];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:cgImage scale:1 orientation:UIImageOrientationUp];
#endif
    CGImageRelease(cgImage);
    UIImage *newImage = [SDImageCoderHelper decodedImageWithImage:image policy:SDImageForceDecodePolicyAutomatic];
    // Check policy works, since it's supported by CA hardware, which return the input image object, using pointer compare
    XCTAssertTrue(image == newImage);
    BOOL newResult = [SDImageCoderHelper CGImageIsHardwareSupported:newImage.CGImage];
    XCTAssertTrue(newResult);
}

- (void)test28ThatDoTriggerCACopyImage {
    // 10 * 8 pixels, RGBA8888
    size_t width = 10;
    size_t height = 8;
    size_t bitsPerComponent = 8;
    size_t components = 4;
    size_t bitsPerPixel = bitsPerComponent * components;
    size_t bytesPerRow = bitsPerPixel / 8 * width;
    size_t size = bytesPerRow * height;
    uint8_t bitmap[size];
    for (size_t i = 0; i < size; i++) {
        bitmap[i] = 255;
    }
    CGColorSpaceRef colorspace = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    CGBitmapInfo bitmapInfo = [SDImageCoderHelper preferredPixelFormat:YES].bitmapInfo;
    CFDataRef data = CFDataCreate(NULL, bitmap, size);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CFRelease(data);
    BOOL shouldInterpolate = YES;
    CGColorRenderingIntent intent = kCGRenderingIntentDefault;
    CGImageRef cgImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, provider, NULL, shouldInterpolate, intent);
    CGDataProviderRelease(provider);
    XCTAssert(cgImage);
    BOOL result = [SDImageCoderHelper CGImageIsHardwareSupported:cgImage];
    // Since it's not 32 bytes aligned, return false
    XCTAssertFalse(result);
    // Let's force-decode to check again
#if SD_MAC
    UIImage *image = [[UIImage alloc] initWithCGImage:cgImage scale:1 orientation:kCGImagePropertyOrientationUp];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:cgImage scale:1 orientation:UIImageOrientationUp];
#endif
    CGImageRelease(cgImage);
    UIImage *newImage = [SDImageCoderHelper decodedImageWithImage:image policy:SDImageForceDecodePolicyAutomatic];
    // Check policy works, since it's not supported by CA hardware, which return the different image object
    XCTAssertFalse(image == newImage);
    BOOL newResult = [SDImageCoderHelper CGImageIsHardwareSupported:newImage.CGImage];
    XCTAssertTrue(newResult);
}

- (void)test29ThatJFIFDecodeOrientationShouldNotApplyTwice {
    // I don't think this is SDWebImage's issue, it's Apple's ImgeIO Bug, but user complain about this: #3594
    // In W3C standard, JFIF should always be orientation up, and should not contains EXIF orientation
    // But some bad image editing tool will generate this kind of image :(
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestJFIF" withExtension:@"jpg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    UIImage *image = [SDImageIOCoder.sharedCoder decodedImageWithData:data options:nil];
    expect(image.sd_imageFormat).equal(SDImageFormatJPEG);
#if SD_UIKIT
    UIImageOrientation orientation = image.imageOrientation;
    expect(orientation).equal(UIImageOrientationDown);
#endif
    
    UIImage *systemImage = [[UIImage alloc] initWithData:data];
#if SD_UIKIT
    orientation = systemImage.imageOrientation;
    if (@available(iOS 18.0, tvOS 18.0, watchOS 11.0, *)) {
        // Apple fix/hack this kind of JFIF on iOS 18
        expect(orientation).equal(UIImageOrientationUp);
    } else {
        expect(orientation).equal(UIImageOrientationDown);
    }
#endif
    
    // Check bitmap color equal, between our usage of ImageIO decoder and Apple system API behavior
    // So, this means, if Apple has bugs, we have bugs too, it's not our fault :)
    UIColor *testColor1 = [image sd_colorAtPoint:CGPointMake(1, 1)];
    UIColor *testColor2 = [systemImage sd_colorAtPoint:CGPointMake(1, 1)];
    CGFloat r1, g1, b1, a1;
    CGFloat r2, g2, b2, a2;
    [testColor1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [testColor2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    expect(r1).beCloseToWithin(r2, 0.01);
    expect(g1).beCloseToWithin(g2, 0.01);
    expect(b1).beCloseToWithin(b2, 0.01);
    expect(a1).beCloseToWithin(a2, 0.01);
    
    // Manual test again for Apple's API
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, nil);
    NSUInteger exifOrientation = [properties[(__bridge NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    CFRelease(source);
    expect(exifOrientation).equal(kCGImagePropertyOrientationDown);
}

- (void)test30ThatImageIOPNGPluginBuggyWorkaround {
    // See: #3634
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"IndexedPNG" withExtension:@"png"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    UIImage *decodedImage = [SDImageIOCoder.sharedCoder decodedImageWithData:data options:nil];
    UIColor *testColor1 = [decodedImage sd_colorAtPoint:CGPointMake(100, 1)];
    CGFloat r1, g1, b1, a1;
    [testColor1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    expect(r1).beCloseToWithin(0.60, 0.01);
    expect(g1).beCloseToWithin(0.91, 0.01);
    expect(b1).beCloseToWithin(0.91, 0.01);
    expect(a1).beCloseToWithin(0.20, 0.01);
    
    // RGBA 16 bits PNG should not workaround
    url = [[NSBundle bundleForClass:[self class]] URLForResource:@"RGBA16PNG" withExtension:@"png"];
    data = [NSData dataWithContentsOfURL:url];
    decodedImage = [SDImageIOCoder.sharedCoder decodedImageWithData:data options:nil];
    testColor1 = [decodedImage sd_colorAtPoint:CGPointMake(100, 1)];
    [testColor1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    expect(r1).beCloseToWithin(0.60, 0.01);
    expect(g1).beCloseToWithin(0.60, 0.01);
    expect(b1).beCloseToWithin(0.33, 0.01);
    expect(a1).beCloseToWithin(0.33, 0.01);
}

- (void)test31ThatSVGShouldUseNativeImageClass {
    NSURL *url = [[NSBundle bundleForClass:[self class]] URLForResource:@"TestImage" withExtension:@"svg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    SDAnimatedImage *animatedImage = [SDAnimatedImage imageWithData:data];
    expect(animatedImage).beNil();
    UIImage *image = [UIImage sd_imageWithData:data];
    Class SVGCoderClass = NSClassFromString(@"SDImageSVGCoder");
    if (SVGCoderClass && [SVGCoderClass sharedCoder]) {
        expect(image).notTo.beNil();
        // Vector version
        expect(image.sd_isVector).beTruthy();
    } else {
        // Platform does not support SVG
        expect(image).beNil();
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
    // check vector format should use 72 DPI
    if (isVector) {
        CGRect boxRect = [self boxRectFromPDFData:inputImageData];
        expect(boxRect.size.width).beGreaterThan(0);
        expect(boxRect.size.height).beGreaterThan(0);
        // Since 72 DPI is 1:1 from inch size to pixel size
        expect(boxRect.size.width).equal(pixelWidth);
        expect(boxRect.size.height).equal(pixelHeight);
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
        expect(outputImage.sd_imageLoopCount).to.equal(inputImage.sd_imageLoopCount);
        
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
        expect(outputMaxImage.sd_imageLoopCount).to.equal(inputImage.sd_imageLoopCount);
    }
}

- (NSArray *)thumbnailImagesFromImageSource:(CGImageSourceRef)source API_AVAILABLE(ios(11.0), tvos(11.0), macos(10.13)) {
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
    NSDictionary *fileProperties = properties[(__bridge NSString *)kCGImagePropertyFileContentsDictionary];
    NSArray *imagesProperties = fileProperties[(__bridge NSString *)kCGImagePropertyImages];
    NSDictionary *imageProperties = imagesProperties.firstObject;
    NSArray *thumbnailImages = imageProperties[(__bridge NSString *)kCGImagePropertyThumbnailImages];
    
    return thumbnailImages;
}

#pragma mark - Utils
- (CGRect)boxRectFromPDFData:(nonnull NSData *)data {
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    if (!provider) {
        return CGRectZero;
    }
    CGPDFDocumentRef document = CGPDFDocumentCreateWithProvider(provider);
    CGDataProviderRelease(provider);
    if (!document) {
        return CGRectZero;
    }
    
    // `CGPDFDocumentGetPage` page number is 1-indexed.
    CGPDFPageRef page = CGPDFDocumentGetPage(document, 1);
    if (!page) {
        CGPDFDocumentRelease(document);
        return CGRectZero;
    }
    
    CGRect boxRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
    CGPDFDocumentRelease(document);
    
    return boxRect;
}

@end
