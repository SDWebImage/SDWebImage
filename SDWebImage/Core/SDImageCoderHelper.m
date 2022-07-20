/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCoderHelper.h"
#import "SDImageFrame.h"
#import "NSImage+Compatibility.h"
#import "NSData+ImageContentType.h"
#import "SDAnimatedImageRep.h"
#import "UIImage+ForceDecode.h"
#import "SDAssociatedObject.h"
#import "UIImage+Metadata.h"
#import "SDInternalMacros.h"
#import "SDGraphicsImageRenderer.h"
#import "SDInternalMacros.h"
#import <Accelerate/Accelerate.h>

static inline size_t SDByteAlign(size_t size, size_t alignment) {
    return ((size + (alignment - 1)) / alignment) * alignment;
}

#if SD_UIKIT
static inline UIImage *SDImageDecodeUIKit(UIImage *image) {
    // See: https://developer.apple.com/documentation/uikit/uiimage/3750834-imagebypreparingfordisplay
    // Need CGImage-based
    if (@available(iOS 15, tvOS 15, *)) {
        UIImage *decodedImage = [image imageByPreparingForDisplay];
        if (decodedImage) {
            SDImageCopyAssociatedObject(image, decodedImage);
            decodedImage.sd_isDecoded = YES;
            return decodedImage;
        }
    }
    return nil;
}

static inline UIImage *SDImageDecodeAndScaleDownUIKit(UIImage *image, CGSize destResolution) {
    // See: https://developer.apple.com/documentation/uikit/uiimage/3750835-imagebypreparingthumbnailofsize
    // Need CGImage-based
    if (@available(iOS 15, tvOS 15, *)) {
        // Calculate thumbnail point size
        CGFloat scale = image.scale ?: 1;
        CGSize thumbnailSize = CGSizeMake(destResolution.width / scale, destResolution.height / scale);
        UIImage *decodedImage = [image imageByPreparingThumbnailOfSize:thumbnailSize];
        if (decodedImage) {
            SDImageCopyAssociatedObject(image, decodedImage);
            decodedImage.sd_isDecoded = YES;
            return decodedImage;
        }
    }
    return nil;
}

static inline BOOL SDImageSupportsHardwareHEVCDecoder(void) {
    static dispatch_once_t onceToken;
    static BOOL supportsHardware = NO;
    dispatch_once(&onceToken, ^{
        SEL DeviceInfoSelector = SD_SEL_SPI(deviceInfoForKey:);
        NSString *HEVCDecoder8bitSupported = @"N8lZxRgC7lfdRS3dRLn+Ag";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([UIDevice.currentDevice respondsToSelector:DeviceInfoSelector] && [UIDevice.currentDevice performSelector:DeviceInfoSelector withObject:HEVCDecoder8bitSupported]) {
            supportsHardware = YES;
        }
#pragma clang diagnostic pop
    });
    return supportsHardware;
}
#endif

static SDImageCoderDecodeSolution kDefaultDecodeSolution = SDImageCoderDecodeSolutionAutomatic;

static const size_t kBytesPerPixel = 4;
static const size_t kBitsPerComponent = 8;

static const CGFloat kBytesPerMB = 1024.0f * 1024.0f;
/*
 * Defines the maximum size in MB of the decoded image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 60.
 * Suggested value for iPad2 and iPhone 4: 120.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 30.
 */
#if SD_MAC
static CGFloat kDestImageLimitBytes = 90.f * kBytesPerMB;
#elif SD_UIKIT
static CGFloat kDestImageLimitBytes = 60.f * kBytesPerMB;
#elif SD_WATCH
static CGFloat kDestImageLimitBytes = 30.f * kBytesPerMB;
#endif

static const CGFloat kDestSeemOverlap = 2.0f;   // the numbers of pixels to overlap the seems where tiles meet.

@implementation SDImageCoderHelper

+ (UIImage *)animatedImageWithFrames:(NSArray<SDImageFrame *> *)frames {
    NSUInteger frameCount = frames.count;
    if (frameCount == 0) {
        return nil;
    }
    
    UIImage *animatedImage;
    
#if SD_UIKIT || SD_WATCH
    NSUInteger durations[frameCount];
    for (size_t i = 0; i < frameCount; i++) {
        durations[i] = frames[i].duration * 1000;
    }
    NSUInteger const gcd = gcdArray(frameCount, durations);
    __block NSTimeInterval totalDuration = 0;
    NSMutableArray<UIImage *> *animatedImages = [NSMutableArray arrayWithCapacity:frameCount];
    [frames enumerateObjectsUsingBlock:^(SDImageFrame * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = frame.image;
        NSUInteger duration = frame.duration * 1000;
        totalDuration += frame.duration;
        NSUInteger repeatCount;
        if (gcd) {
            repeatCount = duration / gcd;
        } else {
            repeatCount = 1;
        }
        for (size_t i = 0; i < repeatCount; ++i) {
            [animatedImages addObject:image];
        }
    }];
    
    animatedImage = [UIImage animatedImageWithImages:animatedImages duration:totalDuration];
    
#else
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:SDImageFormatGIF];
    // Create an image destination. GIF does not support EXIF image orientation
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frameCount, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    
    for (size_t i = 0; i < frameCount; i++) {
        @autoreleasepool {
            SDImageFrame *frame = frames[i];
            NSTimeInterval frameDuration = frame.duration;
            CGImageRef frameImageRef = frame.image.CGImage;
            NSDictionary *frameProperties = @{(__bridge NSString *)kCGImagePropertyGIFDictionary : @{(__bridge NSString *)kCGImagePropertyGIFDelayTime : @(frameDuration)}};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        CFRelease(imageDestination);
        return nil;
    }
    CFRelease(imageDestination);
    CGFloat scale = MAX(frames.firstObject.image.scale, 1);
    
    SDAnimatedImageRep *imageRep = [[SDAnimatedImageRep alloc] initWithData:imageData];
    NSSize size = NSMakeSize(imageRep.pixelsWide / scale, imageRep.pixelsHigh / scale);
    imageRep.size = size;
    animatedImage = [[NSImage alloc] initWithSize:size];
    [animatedImage addRepresentation:imageRep];
#endif
    
    return animatedImage;
}

+ (NSArray<SDImageFrame *> *)framesFromAnimatedImage:(UIImage *)animatedImage {
    if (!animatedImage) {
        return nil;
    }
    
    NSMutableArray<SDImageFrame *> *frames = [NSMutableArray array];
    NSUInteger frameCount = 0;
    
#if SD_UIKIT || SD_WATCH
    NSArray<UIImage *> *animatedImages = animatedImage.images;
    frameCount = animatedImages.count;
    if (frameCount == 0) {
        return nil;
    }
    
    NSTimeInterval avgDuration = animatedImage.duration / frameCount;
    if (avgDuration == 0) {
        avgDuration = 0.1; // if it's a animated image but no duration, set it to default 100ms (this do not have that 10ms limit like GIF or WebP to allow custom coder provide the limit)
    }
    
    __block NSUInteger repeatCount = 1;
    __block UIImage *previousImage = animatedImages.firstObject;
    [animatedImages enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        // ignore first
        if (idx == 0) {
            return;
        }
        if ([image isEqual:previousImage]) {
            repeatCount++;
        } else {
            SDImageFrame *frame = [SDImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount];
            [frames addObject:frame];
            repeatCount = 1;
        }
        previousImage = image;
    }];
    // last one
    SDImageFrame *frame = [SDImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount];
    [frames addObject:frame];
    
#else
    
    NSRect imageRect = NSMakeRect(0, 0, animatedImage.size.width, animatedImage.size.height);
    NSImageRep *imageRep = [animatedImage bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (!bitmapImageRep) {
        return nil;
    }
    frameCount = [[bitmapImageRep valueForProperty:NSImageFrameCount] unsignedIntegerValue];
    if (frameCount == 0) {
        return nil;
    }
    CGFloat scale = animatedImage.scale;
    
    for (size_t i = 0; i < frameCount; i++) {
        @autoreleasepool {
            // NSBitmapImageRep need to manually change frame. "Good taste" API
            [bitmapImageRep setProperty:NSImageCurrentFrame withValue:@(i)];
            NSTimeInterval frameDuration = [[bitmapImageRep valueForProperty:NSImageCurrentFrameDuration] doubleValue];
            NSImage *frameImage = [[NSImage alloc] initWithCGImage:bitmapImageRep.CGImage scale:scale orientation:kCGImagePropertyOrientationUp];
            SDImageFrame *frame = [SDImageFrame frameWithImage:frameImage duration:frameDuration];
            [frames addObject:frame];
        }
    }
#endif
    
    return frames;
}

+ (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    });
    return colorSpace;
}

+ (BOOL)CGImageContainsAlpha:(CGImageRef)cgImage {
    if (!cgImage) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(cgImage);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

+ (CGImageRef)CGImageCreateDecoded:(CGImageRef)cgImage {
    return [self CGImageCreateDecoded:cgImage orientation:kCGImagePropertyOrientationUp];
}

+ (CGImageRef)CGImageCreateDecoded:(CGImageRef)cgImage orientation:(CGImagePropertyOrientation)orientation {
    if (!cgImage) {
        return NULL;
    }
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    if (width == 0 || height == 0) return NULL;
    size_t newWidth;
    size_t newHeight;
    switch (orientation) {
        case kCGImagePropertyOrientationLeft:
        case kCGImagePropertyOrientationLeftMirrored:
        case kCGImagePropertyOrientationRight:
        case kCGImagePropertyOrientationRightMirrored: {
            // These orientation should swap width & height
            newWidth = height;
            newHeight = width;
        }
            break;
        default: {
            newWidth = width;
            newHeight = height;
        }
            break;
    }
    
    BOOL hasAlpha = [self CGImageContainsAlpha:cgImage];
    // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
    // Check #3330 for more detail about why this bitmap is choosen.
    CGBitmapInfo bitmapInfo;
    if (hasAlpha) {
        // iPhone GPU prefer to use BGRA8888, see: https://forums.raywenderlich.com/t/why-mtlpixelformat-bgra8unorm/53489
        // BGRA8888
        bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
    } else {
        // BGR888 previously works on iOS 8~iOS 14, however, iOS 15+ will result a black image. FB9958017
        // RGB888
        bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    }
    CGContextRef context = CGBitmapContextCreate(NULL, newWidth, newHeight, 8, 0, [self colorSpaceGetDeviceRGB], bitmapInfo);
    if (!context) {
        return NULL;
    }
    
    // Apply transform
    CGAffineTransform transform = SDCGContextTransformFromOrientation(orientation, CGSizeMake(newWidth, newHeight));
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage); // The rect is bounding box of CGImage, don't swap width & height
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return newImageRef;
}

+ (CGImageRef)CGImageCreateScaled:(CGImageRef)cgImage size:(CGSize)size {
    if (!cgImage) {
        return NULL;
    }
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    if (width == size.width && height == size.height) {
        CGImageRetain(cgImage);
        return cgImage;
    }
    
    __block vImage_Buffer input_buffer = {}, output_buffer = {};
    @onExit {
        if (input_buffer.data) free(input_buffer.data);
        if (output_buffer.data) free(output_buffer.data);
    };
    BOOL hasAlpha = [self CGImageContainsAlpha:cgImage];
    // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
    // Check #3330 for more detail about why this bitmap is choosen.
    CGBitmapInfo bitmapInfo;
    if (hasAlpha) {
        // iPhone GPU prefer to use BGRA8888, see: https://forums.raywenderlich.com/t/why-mtlpixelformat-bgra8unorm/53489
        // BGRA8888
        bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
    } else {
        // BGR888 previously works on iOS 8~iOS 14, however, iOS 15+ will result a black image. FB9958017
        // RGB888
        bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
    }
    vImage_CGImageFormat format = (vImage_CGImageFormat) {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = bitmapInfo,
        .version = 0,
        .decode = NULL,
        .renderingIntent = CGImageGetRenderingIntent(cgImage)
    };
    
    vImage_Error a_ret = vImageBuffer_InitWithCGImage(&input_buffer, &format, NULL, cgImage, kvImageNoFlags);
    if (a_ret != kvImageNoError) return NULL;
    output_buffer.width = MAX(size.width, 0);
    output_buffer.height = MAX(size.height, 0);
    output_buffer.rowBytes = SDByteAlign(output_buffer.width * 4, 64);
    output_buffer.data = malloc(output_buffer.rowBytes * output_buffer.height);
    if (!output_buffer.data) return NULL;
    
    vImage_Error ret = vImageScale_ARGB8888(&input_buffer, &output_buffer, NULL, kvImageHighQualityResampling);
    if (ret != kvImageNoError) return NULL;
    
    CGImageRef outputImage = vImageCreateCGImageFromBuffer(&output_buffer, &format, NULL, NULL, kvImageNoFlags, &ret);
    if (ret != kvImageNoError) {
        CGImageRelease(outputImage);
        return NULL;
    }
    
    return outputImage;
}

+ (CGSize)scaledSizeWithImageSize:(CGSize)imageSize scaleSize:(CGSize)scaleSize preserveAspectRatio:(BOOL)preserveAspectRatio shouldScaleUp:(BOOL)shouldScaleUp {
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat resultWidth;
    CGFloat resultHeight;
    
    if (width <= 0 || height <= 0 || scaleSize.width <= 0 || scaleSize.height <= 0) {
        // Protect
        resultWidth = width;
        resultHeight = height;
    } else {
        // Scale to fit
        if (preserveAspectRatio) {
            CGFloat pixelRatio = width / height;
            CGFloat scaleRatio = scaleSize.width / scaleSize.height;
            if (pixelRatio > scaleRatio) {
                resultWidth = scaleSize.width;
                resultHeight = ceil(scaleSize.width / pixelRatio);
            } else {
                resultHeight = scaleSize.height;
                resultWidth = ceil(scaleSize.height * pixelRatio);
            }
        } else {
            // Stretch
            resultWidth = scaleSize.width;
            resultHeight = scaleSize.height;
        }
        if (!shouldScaleUp) {
            // Scale down only
            resultWidth = MIN(width, resultWidth);
            resultHeight = MIN(height, resultHeight);
        }
    }
    
    return CGSizeMake(resultWidth, resultHeight);
}

+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    if (![self shouldDecodeImage:image]) {
        return image;
    }
    
    UIImage *decodedImage;
#if SD_UIKIT
    SDImageCoderDecodeSolution decodeSolution = self.defaultDecodeSolution;
    if (decodeSolution == SDImageCoderDecodeSolutionAutomatic) {
        // See #3365, CMPhoto iOS 15 only supports JPEG/HEIF format, or it will print an error log :(
        SDImageFormat format = image.sd_imageFormat;
        if ((format == SDImageFormatHEIC || format == SDImageFormatHEIF) && SDImageSupportsHardwareHEVCDecoder()) {
            decodedImage = SDImageDecodeUIKit(image);
        } else if (format == SDImageFormatJPEG) {
            decodedImage = SDImageDecodeUIKit(image);
        }
    } else if (decodeSolution == SDImageCoderDecodeSolutionUIKit) {
        // Arbitrarily call CMPhoto
        decodedImage = SDImageDecodeUIKit(image);
    }
    if (decodedImage) {
        return decodedImage;
    }
#endif
    
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return image;
    }
    BOOL hasAlpha = [self CGImageContainsAlpha:imageRef];
    // Prefer to use new Image Renderer to re-draw image, instead of low-level CGBitmapContext and CGContextDrawImage
    // This can keep both OS compatible and don't fight with Apple's performance optimization
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.opaque = !hasAlpha;
    format.scale = image.scale;
    CGSize imageSize = image.size;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:imageSize format:format];
    decodedImage = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
            [image drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];
    }];
    SDImageCopyAssociatedObject(image, decodedImage);
    decodedImage.sd_isDecoded = YES;
    return decodedImage;
}

+ (UIImage *)decodedAndScaledDownImageWithImage:(UIImage *)image limitBytes:(NSUInteger)bytes {
    if (![self shouldDecodeImage:image]) {
        return image;
    }
    
    CGFloat destTotalPixels;
    CGFloat tileTotalPixels;
    if (bytes == 0) {
        bytes = [self defaultScaleDownLimitBytes];
    }
    bytes = MAX(bytes, kBytesPerPixel);
    destTotalPixels = bytes / kBytesPerPixel;
    tileTotalPixels = destTotalPixels / 3;
    
    CGImageRef sourceImageRef = image.CGImage;
    CGSize sourceResolution = CGSizeZero;
    sourceResolution.width = CGImageGetWidth(sourceImageRef);
    sourceResolution.height = CGImageGetHeight(sourceImageRef);
    
    if (![self shouldScaleDownImagePixelSize:sourceResolution limitBytes:bytes]) {
        return [self decodedImageWithImage:image];
    }
    
    CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    // Determine the scale ratio to apply to the input image
    // that results in an output image of the defined size.
    // see kDestImageSizeMB, and how it relates to destTotalPixels.
    CGFloat imageScale = sqrt(destTotalPixels / sourceTotalPixels);
    CGSize destResolution = CGSizeZero;
    destResolution.width = MAX(1, (int)(sourceResolution.width * imageScale));
    destResolution.height = MAX(1, (int)(sourceResolution.height * imageScale));
    
    UIImage *decodedImage;
#if SD_UIKIT
    SDImageCoderDecodeSolution decodeSolution = self.defaultDecodeSolution;
    if (decodeSolution == SDImageCoderDecodeSolutionAutomatic) {
        // See #3365, CMPhoto iOS 15 only supports JPEG/HEIF format, or it will print an error log :(
        SDImageFormat format = image.sd_imageFormat;
        if ((format == SDImageFormatHEIC || format == SDImageFormatHEIF) && SDImageSupportsHardwareHEVCDecoder()) {
            decodedImage = SDImageDecodeAndScaleDownUIKit(image, destResolution);
        } else if (format == SDImageFormatJPEG) {
            decodedImage = SDImageDecodeAndScaleDownUIKit(image, destResolution);
        }
    } else if (decodeSolution == SDImageCoderDecodeSolutionUIKit) {
        // Arbitrarily call CMPhoto
        decodedImage = SDImageDecodeAndScaleDownUIKit(image, destResolution);
    }
    if (decodedImage) {
        return decodedImage;
    }
#endif
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool {
        // device color space
        CGColorSpaceRef colorspaceRef = [self colorSpaceGetDeviceRGB];
        BOOL hasAlpha = [self CGImageContainsAlpha:sourceImageRef];
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Check #3330 for more detail about why this bitmap is choosen.
        CGBitmapInfo bitmapInfo;
        if (hasAlpha) {
            // iPhone GPU prefer to use BGRA8888, see: https://forums.raywenderlich.com/t/why-mtlpixelformat-bgra8unorm/53489
            // BGRA8888
            bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
        } else {
            // BGR888 previously works on iOS 8~iOS 14, however, iOS 15+ will result a black image. FB9958017
            // RGB888
            bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
        }
        CGContextRef destContext = CGBitmapContextCreate(NULL,
                                                         destResolution.width,
                                                         destResolution.height,
                                                         kBitsPerComponent,
                                                         0,
                                                         colorspaceRef,
                                                         bitmapInfo);
        
        if (destContext == NULL) {
            return image;
        }
        CGContextSetInterpolationQuality(destContext, kCGInterpolationHigh);
        
        // Now define the size of the rectangle to be used for the
        // incremental bits from the input image to the output image.
        // we use a source tile width equal to the width of the source
        // image due to the way that iOS retrieves image data from disk.
        // iOS must decode an image from disk in full width 'bands', even
        // if current graphics context is clipped to a subrect within that
        // band. Therefore we fully utilize all of the pixel data that results
        // from a decoding operation by anchoring our tile size to the full
        // width of the input image.
        CGRect sourceTile = CGRectZero;
        sourceTile.size.width = sourceResolution.width;
        // The source tile height is dynamic. Since we specified the size
        // of the source tile in MB, see how many rows of pixels high it
        // can be given the input image width.
        sourceTile.size.height = MAX(1, (int)(tileTotalPixels / sourceTile.size.width));
        sourceTile.origin.x = 0.0f;
        // The output tile is the same proportions as the input tile, but
        // scaled to image scale.
        CGRect destTile;
        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;
        // The source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the output image.
        float sourceSeemOverlap = (int)((kDestSeemOverlap/destResolution.height)*sourceResolution.height);
        CGImageRef sourceTileImageRef;
        // calculate the number of read/write operations required to assemble the
        // output image.
        int iterations = (int)( sourceResolution.height / sourceTile.size.height );
        // If tile height doesn't divide the image height evenly, add another iteration
        // to account for the remaining pixels.
        int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
        if(remainder) {
            iterations++;
        }
        // Add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
        float sourceTileHeightMinusOverlap = sourceTile.size.height;
        sourceTile.size.height += sourceSeemOverlap;
        destTile.size.height += kDestSeemOverlap;
        for( int y = 0; y < iterations; ++y ) {
            @autoreleasepool {
                sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
                destTile.origin.y = destResolution.height - (( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + kDestSeemOverlap);
                sourceTileImageRef = CGImageCreateWithImageInRect( sourceImageRef, sourceTile );
                if( y == iterations - 1 && remainder ) {
                    float dify = destTile.size.height;
                    destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
                    dify -= destTile.size.height;
                    destTile.origin.y = MIN(0, destTile.origin.y + dify);
                }
                CGContextDrawImage( destContext, destTile, sourceTileImageRef );
                CGImageRelease( sourceTileImageRef );
            }
        }
        
        CGImageRef destImageRef = CGBitmapContextCreateImage(destContext);
        CGContextRelease(destContext);
        if (destImageRef == NULL) {
            return image;
        }
#if SD_MAC
        decodedImage = [[UIImage alloc] initWithCGImage:destImageRef scale:image.scale orientation:kCGImagePropertyOrientationUp];
#else
        decodedImage = [[UIImage alloc] initWithCGImage:destImageRef scale:image.scale orientation:image.imageOrientation];
#endif
        CGImageRelease(destImageRef);
        SDImageCopyAssociatedObject(image, decodedImage);
        decodedImage.sd_isDecoded = YES;
        return decodedImage;
    }
}

+ (SDImageCoderDecodeSolution)defaultDecodeSolution {
    return kDefaultDecodeSolution;
}

+ (void)setDefaultDecodeSolution:(SDImageCoderDecodeSolution)defaultDecodeSolution {
    kDefaultDecodeSolution = defaultDecodeSolution;
}

+ (NSUInteger)defaultScaleDownLimitBytes {
    return kDestImageLimitBytes;
}

+ (void)setDefaultScaleDownLimitBytes:(NSUInteger)defaultScaleDownLimitBytes {
    if (defaultScaleDownLimitBytes < kBytesPerPixel) {
        return;
    }
    kDestImageLimitBytes = defaultScaleDownLimitBytes;
}

#if SD_UIKIT || SD_WATCH
// Convert an EXIF image orientation to an iOS one.
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(CGImagePropertyOrientation)exifOrientation {
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case kCGImagePropertyOrientationUp:
            imageOrientation = UIImageOrientationUp;
            break;
        case kCGImagePropertyOrientationDown:
            imageOrientation = UIImageOrientationDown;
            break;
        case kCGImagePropertyOrientationLeft:
            imageOrientation = UIImageOrientationLeft;
            break;
        case kCGImagePropertyOrientationRight:
            imageOrientation = UIImageOrientationRight;
            break;
        case kCGImagePropertyOrientationUpMirrored:
            imageOrientation = UIImageOrientationUpMirrored;
            break;
        case kCGImagePropertyOrientationDownMirrored:
            imageOrientation = UIImageOrientationDownMirrored;
            break;
        case kCGImagePropertyOrientationLeftMirrored:
            imageOrientation = UIImageOrientationLeftMirrored;
            break;
        case kCGImagePropertyOrientationRightMirrored:
            imageOrientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return imageOrientation;
}

// Convert an iOS orientation to an EXIF image orientation.
+ (CGImagePropertyOrientation)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation {
    CGImagePropertyOrientation exifOrientation = kCGImagePropertyOrientationUp;
    switch (imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = kCGImagePropertyOrientationUp;
            break;
        case UIImageOrientationDown:
            exifOrientation = kCGImagePropertyOrientationDown;
            break;
        case UIImageOrientationLeft:
            exifOrientation = kCGImagePropertyOrientationLeft;
            break;
        case UIImageOrientationRight:
            exifOrientation = kCGImagePropertyOrientationRight;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = kCGImagePropertyOrientationUpMirrored;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = kCGImagePropertyOrientationDownMirrored;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = kCGImagePropertyOrientationLeftMirrored;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = kCGImagePropertyOrientationRightMirrored;
            break;
        default:
            break;
    }
    return exifOrientation;
}
#endif

#pragma mark - Helper Function
+ (BOOL)shouldDecodeImage:(nullable UIImage *)image {
    // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
    if (image == nil) {
        return NO;
    }
    // Avoid extra decode
    if (image.sd_isDecoded) {
        return NO;
    }
    // do not decode animated images
    if (image.sd_isAnimated) {
        return NO;
    }
    // do not decode vector images
    if (image.sd_isVector) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)shouldScaleDownImagePixelSize:(CGSize)sourceResolution limitBytes:(NSUInteger)bytes {
    BOOL shouldScaleDown = YES;
    
    CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    if (sourceTotalPixels <= 0) {
        return NO;
    }
    CGFloat destTotalPixels;
    if (bytes == 0) {
        bytes = [self defaultScaleDownLimitBytes];
    }
    bytes = MAX(bytes, kBytesPerPixel);
    destTotalPixels = bytes / kBytesPerPixel;
    CGFloat imageScale = destTotalPixels / sourceTotalPixels;
    if (imageScale < 1) {
        shouldScaleDown = YES;
    } else {
        shouldScaleDown = NO;
    }
    
    return shouldScaleDown;
}

static inline CGAffineTransform SDCGContextTransformFromOrientation(CGImagePropertyOrientation orientation, CGSize size) {
    // Inspiration from @libfeihu
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (orientation) {
        case kCGImagePropertyOrientationDown:
        case kCGImagePropertyOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case kCGImagePropertyOrientationLeft:
        case kCGImagePropertyOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case kCGImagePropertyOrientationRight:
        case kCGImagePropertyOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case kCGImagePropertyOrientationUp:
        case kCGImagePropertyOrientationUpMirrored:
            break;
    }
    
    switch (orientation) {
        case kCGImagePropertyOrientationUpMirrored:
        case kCGImagePropertyOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case kCGImagePropertyOrientationLeftMirrored:
        case kCGImagePropertyOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case kCGImagePropertyOrientationUp:
        case kCGImagePropertyOrientationDown:
        case kCGImagePropertyOrientationLeft:
        case kCGImagePropertyOrientationRight:
            break;
    }
    
    return transform;
}

#if SD_UIKIT || SD_WATCH
static NSUInteger gcd(NSUInteger a, NSUInteger b) {
    NSUInteger c;
    while (a != 0) {
        c = a;
        a = b % a;
        b = c;
    }
    return b;
}

static NSUInteger gcdArray(size_t const count, NSUInteger const * const values) {
    if (count == 0) {
        return 0;
    }
    NSUInteger result = values[0];
    for (size_t i = 1; i < count; ++i) {
        result = gcd(values[i], result);
    }
    return result;
}
#endif

@end
