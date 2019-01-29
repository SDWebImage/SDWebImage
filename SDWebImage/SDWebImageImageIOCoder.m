/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageImageIOCoder.h"
#import "SDWebImageCoderHelper.h"
#import "NSImage+WebCache.h"
#import <ImageIO/ImageIO.h>
#import "NSData+ImageContentType.h"
#import "UIImage+MultiFormat.h"

#if SD_UIKIT || SD_WATCH
static const size_t kBytesPerPixel = 4;
static const size_t kBitsPerComponent = 8;

/*
 * Defines the maximum size in MB of the decoded image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 60.
 * Suggested value for iPad2 and iPhone 4: 120.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 30.
 */
static const CGFloat kDestImageSizeMB = 60.0f;

/*
 * Defines the maximum size in MB of a tile used to decode image when the flag `SDWebImageScaleDownLargeImages` is set
 * Suggested value for iPad1 and iPhone 3GS: 20.
 * Suggested value for iPad2 and iPhone 4: 40.
 * Suggested value for iPhone 3G and iPod 2 and earlier devices: 10.
 */
static const CGFloat kSourceImageTileSizeMB = 20.0f;

static const CGFloat kBytesPerMB = 1024.0f * 1024.0f;
static const CGFloat kPixelsPerMB = kBytesPerMB / kBytesPerPixel;
static const CGFloat kDestTotalPixels = kDestImageSizeMB * kPixelsPerMB;
static const CGFloat kTileTotalPixels = kSourceImageTileSizeMB * kPixelsPerMB;

static const CGFloat kDestSeemOverlap = 2.0f;   // the numbers of pixels to overlap the seems where tiles meet.
#endif

@implementation SDWebImageImageIOCoder {
        size_t _width, _height;
#if SD_UIKIT || SD_WATCH
        UIImageOrientation _orientation;
#endif
        CGImageSourceRef _imageSource;
}

- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
}

+ (instancetype)sharedCoder {
    static SDWebImageImageIOCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDWebImageImageIOCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    switch ([NSData sd_imageFormatForImageData:data]) {
        case SDImageFormatWebP:
            // Do not support WebP decoding
            return NO;
        case SDImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [[self class] canDecodeFromHEICFormat];
        case SDImageFormatHEIF:
            // Check HEIF decoding compatibility
            return [[self class] canDecodeFromHEIFFormat];
        default:
            return YES;
    }
}

- (BOOL)canIncrementallyDecodeFromData:(NSData *)data {
    switch ([NSData sd_imageFormatForImageData:data]) {
        case SDImageFormatWebP:
            // Do not support WebP progressive decoding
            return NO;
        case SDImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [[self class] canDecodeFromHEICFormat];
        case SDImageFormatHEIF:
            // Check HEIF decoding compatibility
            return [[self class] canDecodeFromHEIFFormat];
        default:
            return YES;
    }
}

- (UIImage *)decodedImageWithData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    UIImage *image = [[UIImage alloc] initWithData:data];
    image.sd_imageFormat = [NSData sd_imageFormatForImageData:data];
    
    return image;
}

- (UIImage *)incrementallyDecodedImageWithData:(NSData *)data finished:(BOOL)finished {
    if (!_imageSource) {
        _imageSource = CGImageSourceCreateIncremental(NULL);
    }
    UIImage *image;
    
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);
    
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            NSInteger orientationValue = 1;
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
            CFRelease(properties);
            
            // When we draw to Core Graphics, we lose orientation information,
            // which means the image below born of initWithCGIImage will be
            // oriented incorrectly sometimes. (Unlike the image born of initWithData
            // in didCompleteWithError.) So save it here and pass it on later.
#if SD_UIKIT || SD_WATCH
            _orientation = [SDWebImageCoderHelper imageOrientationFromEXIFOrientation:orientationValue];
#endif
        }
    }
    
    if (_width + _height > 0) {
        // Create the image
        CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        
        if (partialImageRef) {
#if SD_UIKIT || SD_WATCH
            image = [[UIImage alloc] initWithCGImage:partialImageRef scale:1 orientation:_orientation];
#elif SD_MAC
            image = [[UIImage alloc] initWithCGImage:partialImageRef size:NSZeroSize];
#endif
            CGImageRelease(partialImageRef);
            image.sd_imageFormat = [NSData sd_imageFormatForImageData:data];
        }
    }
    
    if (finished) {
        if (_imageSource) {
            CFRelease(_imageSource);
            _imageSource = NULL;
        }
    }
    
    return image;
}

- (UIImage *)decompressedImageWithImage:(UIImage *)image
                                   data:(NSData *__autoreleasing  _Nullable *)data
                                options:(nullable NSDictionary<NSString*, NSObject*>*)optionsDict {
#if SD_MAC
    return image;
#endif
#if SD_UIKIT || SD_WATCH
    BOOL shouldScaleDown = NO;
    if (optionsDict != nil) {
        NSNumber *scaleDownLargeImagesOption = nil;
        if ([optionsDict[SDWebImageCoderScaleDownLargeImagesKey] isKindOfClass:[NSNumber class]]) {
            scaleDownLargeImagesOption = (NSNumber *)optionsDict[SDWebImageCoderScaleDownLargeImagesKey];
        }
        if (scaleDownLargeImagesOption != nil) {
            shouldScaleDown = [scaleDownLargeImagesOption boolValue];
        }
    }
    if (!shouldScaleDown) {
        return [self sd_decompressedImageWithImage:image];
    } else {
        UIImage *scaledDownImage = [self sd_decompressedAndScaledDownImageWithImage:image];
        if (scaledDownImage && !CGSizeEqualToSize(scaledDownImage.size, image.size)) {
            // if the image is scaled down, need to modify the data pointer as well
            SDImageFormat format = [NSData sd_imageFormatForImageData:*data];
            NSData *imageData = [self encodedDataWithImage:scaledDownImage format:format];
            if (imageData) {
                *data = imageData;
            }
        }
        return scaledDownImage;
    }
#endif
}

#if SD_UIKIT || SD_WATCH
- (nullable UIImage *)sd_decompressedImageWithImage:(nullable UIImage *)image {
    if (![[self class] shouldDecodeImage:image]) {
        return image;
    }
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool{
        
        CGImageRef imageRef = image.CGImage;
        // device color space
        CGColorSpaceRef colorspaceRef = SDCGColorSpaceGetDeviceRGB();
        BOOL hasAlpha = SDCGImageRefContainsAlpha(imageRef);
        // iOS display alpha info (BRGA8888/BGRX8888)
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     kBitsPerComponent,
                                                     0,
                                                     colorspaceRef,
                                                     bitmapInfo);
        if (context == NULL) {
            return image;
        }
        
        // Draw the image into the context and retrieve the new bitmap image without alpha
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithoutAlpha = [[UIImage alloc] initWithCGImage:imageRefWithoutAlpha scale:image.scale orientation:image.imageOrientation];
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        
        return imageWithoutAlpha;
    }
}

- (nullable UIImage *)sd_decompressedAndScaledDownImageWithImage:(nullable UIImage *)image {
    if (![[self class] shouldDecodeImage:image]) {
        return image;
    }
    
    if (![[self class] shouldScaleDownImage:image]) {
        return [self sd_decompressedImageWithImage:image];
    }
    
    CGContextRef destContext;
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool {
        CGImageRef sourceImageRef = image.CGImage;
        
        CGSize sourceResolution = CGSizeZero;
        sourceResolution.width = CGImageGetWidth(sourceImageRef);
        sourceResolution.height = CGImageGetHeight(sourceImageRef);
        CGFloat sourceTotalPixels = sourceResolution.width * sourceResolution.height;
        // Determine the scale ratio to apply to the input image
        // that results in an output image of the defined size.
        // see kDestImageSizeMB, and how it relates to destTotalPixels.
        CGFloat imageScale = sqrt(kDestTotalPixels / sourceTotalPixels);
        CGSize destResolution = CGSizeZero;
        destResolution.width = (int)(sourceResolution.width * imageScale);
        destResolution.height = (int)(sourceResolution.height * imageScale);
        
        // device color space
        CGColorSpaceRef colorspaceRef = SDCGColorSpaceGetDeviceRGB();
        BOOL hasAlpha = SDCGImageRefContainsAlpha(sourceImageRef);
        // iOS display alpha info (BGRA8888/BGRX8888)
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        destContext = CGBitmapContextCreate(NULL,
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
        // incremental blits from the input image to the output image.
        // we use a source tile width equal to the width of the source
        // image due to the way that iOS retrieves image data from disk.
        // iOS must decode an image from disk in full width 'bands', even
        // if current graphics context is clipped to a subrect within that
        // band. Therefore we fully utilize all of the pixel data that results
        // from a decoding opertion by achnoring our tile size to the full
        // width of the input image.
        CGRect sourceTile = CGRectZero;
        sourceTile.size.width = sourceResolution.width;
        // The source tile height is dynamic. Since we specified the size
        // of the source tile in MB, see how many rows of pixels high it
        // can be given the input image width.
        sourceTile.size.height = (int)(kTileTotalPixels / sourceTile.size.width );
        sourceTile.origin.x = 0.0f;
        // The output tile is the same proportions as the input tile, but
        // scaled to image scale.
        CGRect destTile;
        destTile.size.width = destResolution.width;
        destTile.size.height = sourceTile.size.height * imageScale;
        destTile.origin.x = 0.0f;
        // The source seem overlap is proportionate to the destination seem overlap.
        // this is the amount of pixels to overlap each tile as we assemble the ouput image.
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
                    destTile.origin.y += dify;
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
        UIImage *destImage = [[UIImage alloc] initWithCGImage:destImageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(destImageRef);
        if (destImage == nil) {
            return image;
        }
        return destImage;
    }
}
#endif

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    switch (format) {
        case SDImageFormatWebP:
            // Do not support WebP encoding
            return NO;
        case SDImageFormatHEIC:
            // Check HEIC encoding compatibility
            return [[self class] canEncodeToHEICFormat];
        case SDImageFormatHEIF:
            // Check HEIF encoding compatibility
            return [[self class] canEncodeToHEIFFormat];
        default:
            return YES;
    }
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format {
    if (!image) {
        return nil;
    }
    
    if (format == SDImageFormatUndefined) {
        BOOL hasAlpha = SDCGImageRefContainsAlpha(image.CGImage);
        if (hasAlpha) {
            format = SDImageFormatPNG;
        } else {
            format = SDImageFormatJPEG;
        }
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:format];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
#if SD_UIKIT || SD_WATCH
    NSInteger exifOrientation = [SDWebImageCoderHelper exifOrientationFromImageOrientation:image.imageOrientation];
    [properties setValue:@(exifOrientation) forKey:(__bridge NSString *)kCGImagePropertyOrientation];
#endif
    
    // Add your image to the destination.
    CGImageDestinationAddImage(imageDestination, image.CGImage, (__bridge CFDictionaryRef)properties);
    
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

#pragma mark - Helper
+ (BOOL)shouldDecodeImage:(nullable UIImage *)image {
    // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
    if (image == nil) {
        return NO;
    }
    
    // do not decode animated images
    if (image.images != nil) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)canDecodeFromHEICFormat {
    static BOOL canDecode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:SDImageFormatHEIC];
        NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
        if ([imageUTTypes containsObject:(__bridge NSString *)(imageUTType)]) {
            canDecode = YES;
        }
    });
    return canDecode;
}

+ (BOOL)canDecodeFromHEIFFormat {
    static BOOL canDecode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:SDImageFormatHEIF];
        NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
        if ([imageUTTypes containsObject:(__bridge NSString *)(imageUTType)]) {
            canDecode = YES;
        }
    });
    return canDecode;
}

+ (BOOL)canEncodeToHEICFormat {
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableData *imageData = [NSMutableData data];
        CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:SDImageFormatHEIC];
        
        // Create an image destination.
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
        if (!imageDestination) {
            // Can't encode to HEIC
            canEncode = NO;
        } else {
            // Can encode to HEIC
            CFRelease(imageDestination);
            canEncode = YES;
        }
    });
    return canEncode;
}

+ (BOOL)canEncodeToHEIFFormat {
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableData *imageData = [NSMutableData data];
        CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:SDImageFormatHEIF];
        
        // Create an image destination.
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
        if (!imageDestination) {
            // Can't encode to HEIF
            canEncode = NO;
        } else {
            // Can encode to HEIF
            CFRelease(imageDestination);
            canEncode = YES;
        }
    });
    return canEncode;
}

#if SD_UIKIT || SD_WATCH
+ (BOOL)shouldScaleDownImage:(nonnull UIImage *)image {
    BOOL shouldScaleDown = YES;
    
    CGImageRef sourceImageRef = image.CGImage;
    CGSize sourceResolution = CGSizeZero;
    sourceResolution.width = CGImageGetWidth(sourceImageRef);
    sourceResolution.height = CGImageGetHeight(sourceImageRef);
    float sourceTotalPixels = sourceResolution.width * sourceResolution.height;
    float imageScale = kDestTotalPixels / sourceTotalPixels;
    if (imageScale < 1) {
        shouldScaleDown = YES;
    } else {
        shouldScaleDown = NO;
    }
    
    return shouldScaleDown;
}
#endif

@end
