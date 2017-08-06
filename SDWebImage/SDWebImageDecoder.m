/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) james <https://github.com/mystcolor>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDecoder.h"
#import "NSData+ImageContentType.h"
#import <ImageIO/ImageIO.h>
#ifdef SD_WEBP
#if __has_include(<webp/decode.h>)
#import <webp/decode.h>
#else
#import "webp/decode.h"
#endif
#endif

@interface SDWebImageDecoder ()

@property (assign, nonatomic) SDWebImageDecoderType type;

@end

@implementation SDWebImageDecoder {
    size_t _width, _height;
#if SD_UIKIT || SD_WATCH
    UIImageOrientation _orientation;
#endif
    CGImageSourceRef _imageSource;
#ifdef SD_WEBP
    WebPIDecoder *_idec;
#endif
}

- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
#ifdef SD_WEBP
    if (_idec) {
        WebPIDelete(_idec);
        _idec = NULL;
    }
#endif
}

- (instancetype)initWithType:(SDWebImageDecoderType)type {
    self = [super init];
    if (self) {
        self.type = type;
    }
    
    return self;
}

- (UIImage *)incrementalDecodedImageWithUpdateData:(NSData *)updateData finished:(BOOL)finished {
    if (!updateData) {
        return nil;
    }
    
    UIImage *image;
    NSData *imageData = [updateData copy];
    // check image format until it recognize the format
    if (self.type == SDWebImageDecoderTypeAuto) {
        SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:imageData];
        if (imageFormat == SDImageFormatUndefined) {
            return nil;
        } else if (imageFormat == SDWebImageDecoderTypeWebP) {
            self.type = SDWebImageDecoderTypeWebP;
        } else {
            self.type = SDWebImageDecoderTypeImageIO;
        }
    }
    
    if (self.type == SDWebImageDecoderTypeWebP) {
#ifdef SD_WEBP
        image = [self incrementalWebPDecodedImageWithData:imageData finished:finished];
#endif
    } else {
        image = [self incrementalImageIODecodedImageWithData:imageData finished:finished];
    }
    
    return image;
}

- (UIImage *)incrementalImageIODecodedImageWithData:(NSData *)imageData finished:(BOOL)finished {
    UIImage *image;
    
    if (!_imageSource) {
        _imageSource = CGImageSourceCreateIncremental(NULL);
    }
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)imageData, finished);
    
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            NSInteger orientationValue = -1;
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
            _orientation = [[self class] orientationFromPropertyValue:(orientationValue == -1 ? 1 : orientationValue)];
#endif
        }
    }
    
    if (_width + _height > 0) {
        // Create the image
        CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        
#if SD_UIKIT || SD_WATCH
        // Workaround for iOS anamorphic image
        if (partialImageRef) {
            const size_t partialHeight = CGImageGetHeight(partialImageRef);
            CGColorSpaceRef colorSpace = SDCGColorSpaceGetDeviceRGB();
            CGContextRef bmContext = CGBitmapContextCreate(NULL, _width, _height, 8, _width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
            if (bmContext) {
                CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = _width, .size.height = partialHeight}, partialImageRef);
                CGImageRelease(partialImageRef);
                partialImageRef = CGBitmapContextCreateImage(bmContext);
                CGContextRelease(bmContext);
            }
            else {
                CGImageRelease(partialImageRef);
                partialImageRef = nil;
            }
        }
#endif
        
        if (partialImageRef) {
#if SD_UIKIT || SD_WATCH
            image = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:_orientation];
#elif SD_MAC
            image = [[UIImage alloc] initWithCGImage:partialImageRef size:NSZeroSize];
#endif
            CGImageRelease(partialImageRef);
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

#ifdef SD_WEBP
- (UIImage *)incrementalWebPDecodedImageWithData:(NSData *)imageData finished:(BOOL)finished {
    UIImage *image;
    
    if (!_idec) {
        // Progressive images need transparent, so always use premultiplied RGBA
        _idec = WebPINewRGB(MODE_rgbA, NULL, 0, 0);
        if (!_idec) {
            return nil;
        }
    }
    
    VP8StatusCode status = WebPIUpdate(_idec, imageData.bytes, imageData.length);
    if (status != VP8_STATUS_OK && status != VP8_STATUS_SUSPENDED) {
        return nil;
    }
    
    uint8_t *rgba = WebPIDecGetRGB(_idec, NULL, (int *)&_width, (int *)&_height, NULL);
    
    if (_width + _height > 0) {
        // Construct a UIImage from the decoded RGBA value array
        CGDataProviderRef provider =
        CGDataProviderCreateWithData(NULL, rgba, 0, NULL);
        CGColorSpaceRef colorSpaceRef = SDCGColorSpaceGetDeviceRGB();
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        size_t components = 4;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        CGImageRef imageRef = CGImageCreate(_width, _height, 8, components * 8, components * _width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
        
        CGDataProviderRelease(provider);
        
        if (!imageRef) {
            return nil;
        }
        
        CGContextRef canvas = CGBitmapContextCreate(NULL, _width, _height, 8, 0, SDCGColorSpaceGetDeviceRGB(), bitmapInfo);
        if (!canvas) {
            CGImageRelease(imageRef);
            return nil;
        }
        
        CGContextDrawImage(canvas, CGRectMake(0, 0, _width, _height), imageRef);
        CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
        CGImageRelease(imageRef);
        if (!newImageRef) {
            CGContextRelease(canvas);
            return nil;
        }
        
#if SD_UIKIT || SD_WATCH
        image = [[UIImage alloc] initWithCGImage:newImageRef];
#else
        image = [[UIImage alloc] initWithCGImage:newImageRef size:NSZeroSize];
#endif
        CGImageRelease(newImageRef);
        CGContextRelease(canvas);
    }
    
    if (finished) {
        if (_idec) {
            WebPIDelete(_idec);
            _idec = NULL;
        }
    }
    
    return image;
}
#endif

static CGColorSpaceRef _Nonnull SDCGColorSpaceGetDeviceRGB(void) {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

#if SD_UIKIT || SD_WATCH
+ (UIImageOrientation)orientationFromPropertyValue:(NSInteger)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}
#endif

@end

@implementation UIImage (ForceDecode)

#if SD_UIKIT || SD_WATCH
static const size_t kBytesPerPixel = 4;
static const size_t kBitsPerComponent = 8;

+ (nullable UIImage *)decodedImageWithImage:(nullable UIImage *)image {
    if (![UIImage shouldDecodeImage:image]) {
        return image;
    }
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool{
        
        CGImageRef imageRef = image.CGImage;
        CGColorSpaceRef colorspaceRef = [UIImage colorSpaceForImageRef:imageRef];
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        size_t bytesPerRow = kBytesPerPixel * width;

        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     kBitsPerComponent,
                                                     bytesPerRow,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
        if (context == NULL) {
            return image;
        }
        
        // Draw the image into the context and retrieve the new bitmap image without alpha
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithoutAlpha = [UIImage imageWithCGImage:imageRefWithoutAlpha
                                                         scale:image.scale
                                                   orientation:image.imageOrientation];
        
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        
        return imageWithoutAlpha;
    }
}

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

+ (nullable UIImage *)decodedAndScaledDownImageWithImage:(nullable UIImage *)image {
    if (![UIImage shouldDecodeImage:image]) {
        return image;
    }
    
    if (![UIImage shouldScaleDownImage:image]) {
        return [UIImage decodedImageWithImage:image];
    }
    
    CGContextRef destContext;
    
    // autorelease the bitmap context and all vars to help system to free memory when there are memory warning.
    // on iOS7, do not forget to call [[SDImageCache sharedImageCache] clearMemory];
    @autoreleasepool {
        CGImageRef sourceImageRef = image.CGImage;
        
        CGSize sourceResolution = CGSizeZero;
        sourceResolution.width = CGImageGetWidth(sourceImageRef);
        sourceResolution.height = CGImageGetHeight(sourceImageRef);
        float sourceTotalPixels = sourceResolution.width * sourceResolution.height;
        // Determine the scale ratio to apply to the input image
        // that results in an output image of the defined size.
        // see kDestImageSizeMB, and how it relates to destTotalPixels.
        float imageScale = kDestTotalPixels / sourceTotalPixels;
        CGSize destResolution = CGSizeZero;
        destResolution.width = (int)(sourceResolution.width*imageScale);
        destResolution.height = (int)(sourceResolution.height*imageScale);
        
        // current color space
        CGColorSpaceRef colorspaceRef = [UIImage colorSpaceForImageRef:sourceImageRef];
        
        size_t bytesPerRow = kBytesPerPixel * destResolution.width;
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        destContext = CGBitmapContextCreate(NULL,
                                            destResolution.width,
                                            destResolution.height,
                                            kBitsPerComponent,
                                            bytesPerRow,
                                            colorspaceRef,
                                            kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
        
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
        UIImage *destImage = [UIImage imageWithCGImage:destImageRef scale:image.scale orientation:image.imageOrientation];
        CGImageRelease(destImageRef);
        if (destImage == nil) {
            return image;
        }
        return destImage;
    }
}

+ (BOOL)shouldDecodeImage:(nullable UIImage *)image {
    // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
    if (image == nil) {
        return NO;
    }

    // do not decode animated images
    if (image.images != nil) {
        return NO;
    }
    
    CGImageRef imageRef = image.CGImage;
    
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    BOOL anyAlpha = (alpha == kCGImageAlphaFirst ||
                     alpha == kCGImageAlphaLast ||
                     alpha == kCGImageAlphaPremultipliedFirst ||
                     alpha == kCGImageAlphaPremultipliedLast);
    // do not decode images with alpha
    if (anyAlpha) {
        return NO;
    }
    
    return YES;
}

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

+ (CGColorSpaceRef)colorSpaceForImageRef:(CGImageRef)imageRef {
    // current
    CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
    CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
    
    BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                  imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                  imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                  imageColorSpaceModel == kCGColorSpaceModelIndexed);
    if (unsupportedColorSpace) {
        colorspaceRef = SDCGColorSpaceGetDeviceRGB();
    }
    return colorspaceRef;
}
#elif SD_MAC
+ (nullable UIImage *)decodedImageWithImage:(nullable UIImage *)image {
    return image;
}

+ (nullable UIImage *)decodedAndScaledDownImageWithImage:(nullable UIImage *)image {
    return image;
}
#endif

@end
