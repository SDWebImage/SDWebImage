/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDImageIOAnimatedCoder.h"
#import "NSImage+Compatibility.h"
#import "UIImage+Metadata.h"
#import "NSData+ImageContentType.h"
#import "SDImageCoderHelper.h"
#import "SDAnimatedImageRep.h"
#import "UIImage+ForceDecode.h"
#import "SDInternalMacros.h"

#import <ImageIO/ImageIO.h>
#import <CoreServices/CoreServices.h>

#if SD_CHECK_CGIMAGE_RETAIN_SOURCE
#import <dlfcn.h>

// SPI to check thread safe during Example and Test
static CGImageSourceRef (*SDCGImageGetImageSource)(CGImageRef);
#endif

// Specify File Size for lossy format encoding, like JPEG
static NSString * kSDCGImageDestinationRequestedFileSize = @"kCGImageDestinationRequestedFileSize";
// Avoid ImageIO translate JFIF orientation to EXIF orientation which cause bug because returned CGImage already apply the orientation transform
static NSString * kSDCGImageSourceSkipMetadata = @"kCGImageSourceSkipMetadata";

// This strip the un-wanted CGImageProperty, like the internal CGImageSourceRef in iOS 15+
// However, CGImageCreateCopy still keep those CGImageProperty, not suit for our use case
static CGImageRef __nullable SDCGImageCreateMutableCopy(CGImageRef cg_nullable image, CGBitmapInfo bitmapInfo) {
    if (!image) return nil;
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(image);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(image);
    size_t bytesPerRow = CGImageGetBytesPerRow(image);
    CGColorSpaceRef space = CGImageGetColorSpace(image);
    CGDataProviderRef provider = CGImageGetDataProvider(image);
    const CGFloat *decode = CGImageGetDecode(image);
    bool shouldInterpolate = CGImageGetShouldInterpolate(image);
    CGColorRenderingIntent intent = CGImageGetRenderingIntent(image);
    CGImageRef newImage = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, space, bitmapInfo, provider, decode, shouldInterpolate, intent);
    return newImage;
}

static inline CGImageRef __nullable SDCGImageCreateCopy(CGImageRef cg_nullable image) {
    if (!image) return nil;
    return SDCGImageCreateMutableCopy(image, CGImageGetBitmapInfo(image));
}

static BOOL SDLoadOnePixelBitmapBuffer(CGImageRef imageRef, uint8_t *r, uint8_t *g, uint8_t *b, uint8_t *a) {
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    
    // Get pixels
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    if (!provider) {
        return NO;
    }
    CFDataRef data = CGDataProviderCopyData(provider);
    if (!data) {
        return NO;
    }
    
    CFRange range = CFRangeMake(0, 4); // one pixel
    if (CFDataGetLength(data) < range.location + range.length) {
        CFRelease(data);
        return NO;
    }
    uint8_t pixel[4] = {0};
    CFDataGetBytes(data, range, pixel);
    CFRelease(data);
    
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    switch (alphaInfo) {
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaFirst: {
            if (byteOrderNormal) {
                // ARGB8888
                *a = pixel[0];
                *r = pixel[1];
                *g = pixel[2];
                *b = pixel[3];
            } else {
                // BGRA8888
                *b = pixel[0];
                *g = pixel[1];
                *r = pixel[2];
                *a = pixel[3];
            }
        }
            break;
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaLast: {
            if (byteOrderNormal) {
                // RGBA8888
                *r = pixel[0];
                *g = pixel[1];
                *b = pixel[2];
                *a = pixel[3];
            } else {
                // ABGR8888
                *a = pixel[0];
                *b = pixel[1];
                *g = pixel[2];
                *r = pixel[3];
            }
        }
            break;
        case kCGImageAlphaNone: {
            if (byteOrderNormal) {
                // RGB
                *r = pixel[0];
                *g = pixel[1];
                *b = pixel[2];
            } else {
                // BGR
                *b = pixel[0];
                *g = pixel[1];
                *r = pixel[2];
            }
        }
            break;
        case kCGImageAlphaNoneSkipLast: {
            if (byteOrderNormal) {
                // RGBX
                *r = pixel[0];
                *g = pixel[1];
                *b = pixel[2];
            } else {
                // XBGR
                *b = pixel[1];
                *g = pixel[2];
                *r = pixel[3];
            }
        }
            break;
        case kCGImageAlphaNoneSkipFirst: {
            if (byteOrderNormal) {
                // XRGB
                *r = pixel[1];
                *g = pixel[2];
                *b = pixel[3];
            } else {
                // BGRX
                *b = pixel[0];
                *g = pixel[1];
                *r = pixel[2];
            }
        }
            break;
        case kCGImageAlphaOnly: {
            // A
            *a = pixel[0];
        }
            break;
        default:
            break;
    }
    
    return YES;
}

static CGImageRef SDImageIOPNGPluginBuggyCreateWorkaround(CGImageRef cgImage) CF_RETURNS_RETAINED {
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(cgImage);
    CGImageAlphaInfo alphaInfo = (bitmapInfo & kCGBitmapAlphaInfoMask);
    CGImageAlphaInfo newAlphaInfo = alphaInfo;
    if (alphaInfo == kCGImageAlphaLast) {
        newAlphaInfo = kCGImageAlphaPremultipliedLast;
    } else if (alphaInfo == kCGImageAlphaFirst) {
        newAlphaInfo = kCGImageAlphaPremultipliedFirst;
    }
    if (newAlphaInfo != alphaInfo) {
        CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
        CGBitmapInfo newBitmapInfo = newAlphaInfo | byteOrderInfo;
        if (SD_OPTIONS_CONTAINS(bitmapInfo, kCGBitmapFloatComponents)) {
            // Keep float components
            newBitmapInfo |= kCGBitmapFloatComponents;
        }
        // Create new CGImage with corrected alpha info...
        CGImageRef newCGImage = SDCGImageCreateMutableCopy(cgImage, newBitmapInfo);
        return newCGImage;
    } else {
        CGImageRetain(cgImage);
        return cgImage;
    }
}

static BOOL SDImageIOPNGPluginBuggyNeedWorkaround(void) {
    // See: #3605 FB13322459
    // ImageIO on iOS 17 (17.0~17.2), there is one serious problem on ImageIO PNG plugin. The decode result for indexed color PNG use the wrong CGImageAlphaInfo
    // The returned CGImageAlphaInfo is alpha last, but the actual bitmap data is premultiplied alpha last, which cause many runtime render bug.
    // So, we do a hack workaround:
    // 1. Decode a indexed color PNG in runtime
    // 2. If the bitmap is premultiplied alpha, then assume it's buggy
    // 3. If buggy, then all premultiplied `CGImageAlphaInfo` will assume to be non-premultiplied
    // :)
    
    if (@available(iOS 17, tvOS 17, macOS 14, watchOS 11, *)) {
        // Continue
    } else {
        return NO;
    }
    static BOOL isBuggy = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *base64String = @"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUyMjKlMgnVAAAAAXRSTlMyiDGJ5gAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=";
        NSData *onePixelIndexedPNGData = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)onePixelIndexedPNGData, nil);
        NSCParameterAssert(source);
        CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil);
        NSCParameterAssert(cgImage);
        uint8_t r, g, b, a = 0;
        BOOL success = SDLoadOnePixelBitmapBuffer(cgImage, &r, &g, &b, &a);
        if (!success) {
            isBuggy = NO; // Impossible...
        } else {
            if (r == 50 && g == 50 && b == 50 && a == 50) {
                // Correct value
                isBuggy = NO;
            } else {
#if DEBUG
                NSLog(@"Detected the current OS's ImageIO PNG Decoder is buggy on indexed color PNG. Perform workaround solution...");
                isBuggy = YES;
#endif
            }
        }
        CFRelease(source);
        CGImageRelease(cgImage);
    });
    
    return isBuggy;
}

@interface SDImageIOCoderFrame : NSObject

@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSTimeInterval duration; // Frame duration in seconds

@end

@implementation SDImageIOCoderFrame
@end

@implementation SDImageIOAnimatedCoder {
    size_t _width, _height;
    CGImageSourceRef _imageSource;
    BOOL _incremental;
    SD_LOCK_DECLARE(_lock); // Lock only apply for incremental animation decoding
    NSData *_imageData;
    CGFloat _scale;
    NSUInteger _loopCount;
    NSUInteger _frameCount;
    NSArray<SDImageIOCoderFrame *> *_frames;
    BOOL _finished;
    BOOL _preserveAspectRatio;
    CGSize _thumbnailSize;
    NSUInteger _limitBytes;
    BOOL _lazyDecode;
}

- (void)dealloc
{
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
#if SD_UIKIT
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    if (_imageSource) {
        for (size_t i = 0; i < _frameCount; i++) {
            CGImageSourceRemoveCacheAtIndex(_imageSource, i);
        }
    }
}

#pragma mark - Subclass Override

+ (SDImageFormat)imageFormat {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `SDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)imageUTType {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `SDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)dictionaryProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `SDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)unclampedDelayTimeProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `SDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)delayTimeProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `SDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSString *)loopCountProperty {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `SDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSUInteger)defaultLoopCount {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"For `SDImageIOAnimatedCoder` subclass, you must override %@ method", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark - Utils

+ (BOOL)canDecodeFromFormat:(SDImageFormat)format {
    static dispatch_once_t onceToken;
    static NSSet *imageUTTypeSet;
    dispatch_once(&onceToken, ^{
        NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
        imageUTTypeSet = [NSSet setWithArray:imageUTTypes];
    });
    CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:format];
    if ([imageUTTypeSet containsObject:(__bridge NSString *)(imageUTType)]) {
        // Can decode from target format
        return YES;
    }
    return NO;
}

+ (BOOL)canEncodeToFormat:(SDImageFormat)format {
    static dispatch_once_t onceToken;
    static NSSet *imageUTTypeSet;
    dispatch_once(&onceToken, ^{
        NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageDestinationCopyTypeIdentifiers();
        imageUTTypeSet = [NSSet setWithArray:imageUTTypes];
    });
    CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:format];
    if ([imageUTTypeSet containsObject:(__bridge NSString *)(imageUTType)]) {
        // Can encode to target format
        return YES;
    }
    return NO;
}

+ (NSUInteger)imageLoopCountWithSource:(CGImageSourceRef)source {
    NSUInteger loopCount = self.defaultLoopCount;
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, NULL);
    NSDictionary *containerProperties = imageProperties[self.dictionaryProperty];
    if (containerProperties) {
        NSNumber *containerLoopCount = containerProperties[self.loopCountProperty];
        if (containerLoopCount != nil) {
            loopCount = containerLoopCount.unsignedIntegerValue;
        }
    }
    return loopCount;
}

+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    NSTimeInterval frameDuration = 0.1;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
    if (!cfFrameProperties) {
        return frameDuration;
    }
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *containerProperties = frameProperties[self.dictionaryProperty];
    
    NSNumber *delayTimeUnclampedProp = containerProperties[self.unclampedDelayTimeProperty];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp doubleValue];
    } else {
        NSNumber *delayTimeProp = containerProperties[self.delayTimeProperty];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp doubleValue];
        }
    }
    
    // Many annoying ads specify a 0 duration to make an image flash as quickly as possible.
    // We follow Firefox's behavior and use a duration of 100 ms for any frames that specify
    // a duration of <= 10 ms. See <rdar://problem/7689300> and <http://webkit.org/b/36082>
    // for more information.
    
    if (frameDuration < 0.011) {
        frameDuration = 0.1;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

+ (UIImage *)createFrameAtIndex:(NSUInteger)index source:(CGImageSourceRef)source scale:(CGFloat)scale preserveAspectRatio:(BOOL)preserveAspectRatio thumbnailSize:(CGSize)thumbnailSize lazyDecode:(BOOL)lazyDecode animatedImage:(BOOL)animatedImage {
    // `animatedImage` means called from `SDAnimatedImageProvider.animatedImageFrameAtIndex`
    NSDictionary *options;
    if (animatedImage) {
        if (!lazyDecode) {
            options = @{
                // image decoding and caching should happen at image creation time.
                (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(YES),
            };
        } else {
            options = @{
                // image decoding will happen at rendering time
                (__bridge NSString *)kCGImageSourceShouldCacheImmediately : @(NO),
            };
        }
    }
    // Parse the image properties
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, (__bridge CFDictionaryRef)@{kSDCGImageSourceSkipMetadata : @(YES)});
    CGFloat pixelWidth = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
    CGFloat pixelHeight = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
    CGImagePropertyOrientation exifOrientation = (CGImagePropertyOrientation)[properties[(__bridge NSString *)kCGImagePropertyOrientation] unsignedIntegerValue];
    if (!exifOrientation) {
        exifOrientation = kCGImagePropertyOrientationUp;
    }

    NSMutableDictionary *decodingOptions;
    if (options) {
        decodingOptions = [NSMutableDictionary dictionaryWithDictionary:options];
    } else {
        decodingOptions = [NSMutableDictionary dictionary];
    }
    CGImageRef imageRef;
    BOOL createFullImage = thumbnailSize.width == 0 || thumbnailSize.height == 0 || pixelWidth == 0 || pixelHeight == 0 || (pixelWidth <= thumbnailSize.width && pixelHeight <= thumbnailSize.height);
    if (createFullImage) {
        imageRef = CGImageSourceCreateImageAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    } else {
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailWithTransform] = @(preserveAspectRatio);
        CGFloat maxPixelSize;
        if (preserveAspectRatio) {
            CGFloat pixelRatio = pixelWidth / pixelHeight;
            CGFloat thumbnailRatio = thumbnailSize.width / thumbnailSize.height;
            if (pixelRatio > thumbnailRatio) {
                maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.width / pixelRatio);
            } else {
                maxPixelSize = MAX(thumbnailSize.height, thumbnailSize.height * pixelRatio);
            }
        } else {
            maxPixelSize = MAX(thumbnailSize.width, thumbnailSize.height);
        }
        decodingOptions[(__bridge NSString *)kCGImageSourceThumbnailMaxPixelSize] = @(maxPixelSize);
        decodingOptions[(__bridge NSString *)kCGImageSourceCreateThumbnailFromImageAlways] = @(YES);
        imageRef = CGImageSourceCreateThumbnailAtIndex(source, index, (__bridge CFDictionaryRef)[decodingOptions copy]);
    }
    if (!imageRef) {
        return nil;
    }
    BOOL isDecoded = NO;
    // Thumbnail image post-process
    if (!createFullImage) {
        if (preserveAspectRatio) {
            // kCGImageSourceCreateThumbnailWithTransform will apply EXIF transform as well, we should not apply twice
            exifOrientation = kCGImagePropertyOrientationUp;
        } else {
            // `CGImageSourceCreateThumbnailAtIndex` take only pixel dimension, if not `preserveAspectRatio`, we should manual scale to the target size
            CGImageRef scaledImageRef = [SDImageCoderHelper CGImageCreateScaled:imageRef size:thumbnailSize];
            if (scaledImageRef) {
                CGImageRelease(imageRef);
                imageRef = scaledImageRef;
                isDecoded = YES;
            }
        }
    }
    // Check whether output CGImage is decoded
    if (!lazyDecode) {
        if (!isDecoded) {
            // Use CoreGraphics to trigger immediately decode
            CGImageRef decodedImageRef = [SDImageCoderHelper CGImageCreateDecoded:imageRef];
            if (decodedImageRef) {
                CGImageRelease(imageRef);
                imageRef = decodedImageRef;
                isDecoded = YES;
            }
        }
    } else if (animatedImage) {
        // iOS 15+, CGImageRef now retains CGImageSourceRef internally. To workaround its thread-safe issue, we have to strip CGImageSourceRef, using Force-Decode (or have to use SPI `CGImageSetImageSource`), See: https://github.com/SDWebImage/SDWebImage/issues/3273
        if (@available(iOS 15, tvOS 15, *)) {
            // User pass `lazyDecode == YES`, but we still have to strip the CGImageSourceRef
            // CGImageRef newImageRef = CGImageCreateCopy(imageRef); // This one does not strip the CGImageProperty
            CGImageRef newImageRef = SDCGImageCreateCopy(imageRef);
            if (newImageRef) {
                CGImageRelease(imageRef);
                imageRef = newImageRef;
            }
#if SD_CHECK_CGIMAGE_RETAIN_SOURCE
            // Assert here to check CGImageRef should not retain the CGImageSourceRef and has possible thread-safe issue (this is behavior on iOS 15+)
            // If assert hit, fire issue to https://github.com/SDWebImage/SDWebImage/issues and we update the condition for this behavior check
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                SDCGImageGetImageSource = dlsym(RTLD_DEFAULT, "CGImageGetImageSource");
            });
            if (SDCGImageGetImageSource) {
                NSCAssert(!SDCGImageGetImageSource(imageRef), @"Animated Coder created CGImageRef should not retain CGImageSourceRef, which may cause thread-safe issue without lock");
            }
#endif
        }
    }
    // :)
    CFStringRef uttype = CGImageSourceGetType(source);
    SDImageFormat imageFormat = [NSData sd_imageFormatFromUTType:uttype];
    if (imageFormat == SDImageFormatPNG && SDImageIOPNGPluginBuggyNeedWorkaround()) {
        CGImageRef newImageRef = SDImageIOPNGPluginBuggyCreateWorkaround(imageRef);
        CGImageRelease(imageRef);
        imageRef = newImageRef;
    }
    
#if SD_UIKIT || SD_WATCH
    UIImageOrientation imageOrientation = [SDImageCoderHelper imageOrientationFromEXIFOrientation:exifOrientation];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:exifOrientation];
#endif
    CGImageRelease(imageRef);
    image.sd_isDecoded = isDecoded;
    
    return image;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == self.class.imageFormat);
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    CGFloat scale = 1;
    NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
    if (scaleFactor != nil) {
        scale = MAX([scaleFactor doubleValue], 1);
    }
    
    CGSize thumbnailSize = CGSizeZero;
    NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
    if (thumbnailSizeValue != nil) {
#if SD_MAC
        thumbnailSize = thumbnailSizeValue.sizeValue;
#else
        thumbnailSize = thumbnailSizeValue.CGSizeValue;
#endif
    }
    
    BOOL preserveAspectRatio = YES;
    NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
    if (preserveAspectRatioValue != nil) {
        preserveAspectRatio = preserveAspectRatioValue.boolValue;
    }
    
    BOOL lazyDecode = YES; // Defaults YES for static image coder
    NSNumber *lazyDecodeValue = options[SDImageCoderDecodeUseLazyDecoding];
    if (lazyDecodeValue != nil) {
        lazyDecode = lazyDecodeValue.boolValue;
    }
    
    NSUInteger limitBytes = 0;
    NSNumber *limitBytesValue = options[SDImageCoderDecodeScaleDownLimitBytes];
    if (limitBytesValue != nil) {
        limitBytes = limitBytesValue.unsignedIntegerValue;
    }
    
#if SD_MAC
    // If don't use thumbnail, prefers the built-in generation of frames (GIF/APNG)
    // Which decode frames in time and reduce memory usage
    if (limitBytes == 0 && (thumbnailSize.width == 0 || thumbnailSize.height == 0)) {
        SDAnimatedImageRep *imageRep = [[SDAnimatedImageRep alloc] initWithData:data];
        if (imageRep) {
            NSSize size = NSMakeSize(imageRep.pixelsWide / scale, imageRep.pixelsHigh / scale);
            imageRep.size = size;
            NSImage *animatedImage = [[NSImage alloc] initWithSize:size];
            [animatedImage addRepresentation:imageRep];
            animatedImage.sd_imageFormat = self.class.imageFormat;
            return animatedImage;
        }
    }
#endif
    
    NSString *typeIdentifierHint = options[SDImageCoderDecodeTypeIdentifierHint];
    if (!typeIdentifierHint) {
        // Check file extension and convert to UTI, from: https://stackoverflow.com/questions/1506251/getting-an-uniform-type-identifier-for-a-given-extension
        NSString *fileExtensionHint = options[SDImageCoderDecodeFileExtensionHint];
        if (fileExtensionHint) {
            typeIdentifierHint = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
            // Ignore dynamic UTI
            if (UTTypeIsDynamic((__bridge CFStringRef)typeIdentifierHint)) {
                typeIdentifierHint = nil;
            }
        }
    } else if ([typeIdentifierHint isEqual:NSNull.null]) {
        // Hack if user don't want to imply file extension
        typeIdentifierHint = nil;
    }
    
    NSDictionary *creatingOptions = nil;
    if (typeIdentifierHint) {
        creatingOptions = @{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : typeIdentifierHint};
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)creatingOptions);
    if (!source) {
        // Try again without UTType hint, the call site from user may provide the wrong UTType
        source = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
    }
    if (!source) {
        return nil;
    }
    
    size_t frameCount = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    
    // Parse the image properties
    NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    size_t width = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
    size_t height = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
    // Scale down to limit bytes if need
    if (limitBytes > 0) {
        // Hack since ImageIO public API (not CGImageDecompressor/CMPhoto) always return back RGBA8888 CGImage
        CGSize imageSize = CGSizeMake(width, height);
        CGSize framePixelSize = [SDImageCoderHelper scaledSizeWithImageSize:imageSize limitBytes:limitBytes bytesPerPixel:4 frameCount:frameCount];
        // Override thumbnail size
        thumbnailSize = framePixelSize;
        preserveAspectRatio = YES;
    }
    
    BOOL decodeFirstFrame = [options[SDImageCoderDecodeFirstFrameOnly] boolValue];
    if (decodeFirstFrame || frameCount <= 1) {
        animatedImage = [self.class createFrameAtIndex:0 source:source scale:scale preserveAspectRatio:preserveAspectRatio thumbnailSize:thumbnailSize lazyDecode:lazyDecode animatedImage:NO];
    } else {
        NSMutableArray<SDImageFrame *> *frames = [NSMutableArray arrayWithCapacity:frameCount];
        
        for (size_t i = 0; i < frameCount; i++) {
            UIImage *image = [self.class createFrameAtIndex:i source:source scale:scale preserveAspectRatio:preserveAspectRatio thumbnailSize:thumbnailSize lazyDecode:lazyDecode animatedImage:NO];
            if (!image) {
                continue;
            }
            
            NSTimeInterval duration = [self.class frameDurationAtIndex:i source:source];
            
            SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = [self.class imageLoopCountWithSource:source];
        
        animatedImage = [SDImageCoderHelper animatedImageWithFrames:frames];
        animatedImage.sd_imageLoopCount = loopCount;
    }
    animatedImage.sd_imageFormat = self.class.imageFormat;
    CFRelease(source);
    
    return animatedImage;
}

#pragma mark - Progressive Decode

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == self.class.imageFormat);
}

- (instancetype)initIncrementalWithOptions:(nullable SDImageCoderOptions *)options {
    self = [super init];
    if (self) {
        NSString *imageUTType = self.class.imageUTType;
        _imageSource = CGImageSourceCreateIncremental((__bridge CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : imageUTType});
        _incremental = YES;
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        _scale = scale;
        CGSize thumbnailSize = CGSizeZero;
        NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
        if (thumbnailSizeValue != nil) {
    #if SD_MAC
            thumbnailSize = thumbnailSizeValue.sizeValue;
    #else
            thumbnailSize = thumbnailSizeValue.CGSizeValue;
    #endif
        }
        _thumbnailSize = thumbnailSize;
        BOOL preserveAspectRatio = YES;
        NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
        if (preserveAspectRatioValue != nil) {
            preserveAspectRatio = preserveAspectRatioValue.boolValue;
        }
        _preserveAspectRatio = preserveAspectRatio;
        NSUInteger limitBytes = 0;
        NSNumber *limitBytesValue = options[SDImageCoderDecodeScaleDownLimitBytes];
        if (limitBytesValue != nil) {
            limitBytes = limitBytesValue.unsignedIntegerValue;
        }
        _limitBytes = limitBytes;
        BOOL lazyDecode = NO; // Defaults NO for animated image coder
        NSNumber *lazyDecodeValue = options[SDImageCoderDecodeUseLazyDecoding];
        if (lazyDecodeValue != nil) {
            lazyDecode = lazyDecodeValue.boolValue;
        }
        _lazyDecode = lazyDecode;
        SD_LOCK_INIT(_lock);
#if SD_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    NSCParameterAssert(_incremental);
    if (_finished) {
        return;
    }
    _imageData = data;
    _finished = finished;
    
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);
    
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            CFRelease(properties);
        }
    }
    
    SD_LOCK(_lock);
    // For animated image progressive decoding because the frame count and duration may be changed.
    [self scanAndCheckFramesValidWithImageSource:_imageSource];
    SD_UNLOCK(_lock);
    
    // Scale down to limit bytes if need
    if (_limitBytes > 0) {
        // Hack since ImageIO public API (not CGImageDecompressor/CMPhoto) always return back RGBA8888 CGImage
        CGSize imageSize = CGSizeMake(_width, _height);
        CGSize framePixelSize = [SDImageCoderHelper scaledSizeWithImageSize:imageSize limitBytes:_limitBytes bytesPerPixel:4 frameCount:_frameCount];
        // Override thumbnail size
        _thumbnailSize = framePixelSize;
        _preserveAspectRatio = YES;
    }
}

- (UIImage *)incrementalDecodedImageWithOptions:(SDImageCoderOptions *)options {
    NSCParameterAssert(_incremental);
    UIImage *image;
    
    if (_width + _height > 0) {
        // Create the image
        CGFloat scale = _scale;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        image = [self.class createFrameAtIndex:0 source:_imageSource scale:scale preserveAspectRatio:_preserveAspectRatio thumbnailSize:_thumbnailSize lazyDecode:_lazyDecode animatedImage:NO];
        if (image) {
            image.sd_imageFormat = self.class.imageFormat;
        }
    }
    
    return image;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return (format == self.class.imageFormat);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(nullable SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    if (format != self.class.imageFormat) {
        return nil;
    }
    
    NSArray<SDImageFrame *> *frames = [SDImageCoderHelper framesFromAnimatedImage:image];
    if (!frames || frames.count == 0) {
        SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:0];
        frames = @[frame];
    }
    return [self encodedDataWithFrames:frames loopCount:image.sd_imageLoopCount format:format options:options];
}

- (NSData *)encodedDataWithFrames:(NSArray<SDImageFrame *> *)frames loopCount:(NSUInteger)loopCount format:(SDImageFormat)format options:(SDImageCoderOptions *)options {
    UIImage *image = frames.firstObject.image; // Primary image
    if (!image) {
        return nil;
    }
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        // Earily return, supports CGImage only
        return nil;
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:format];
    
    // Create an image destination. Animated Image does not support EXIF image orientation TODO
    // The `CGImageDestinationCreateWithData` will log a warning when count is 0, use 1 instead.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frames.count ?: 1, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
#if SD_UIKIT || SD_WATCH
    CGImagePropertyOrientation exifOrientation = [SDImageCoderHelper exifOrientationFromImageOrientation:image.imageOrientation];
#else
    CGImagePropertyOrientation exifOrientation = kCGImagePropertyOrientationUp;
#endif
    properties[(__bridge NSString *)kCGImagePropertyOrientation] = @(exifOrientation);
    // Encoding Options
    double compressionQuality = 1;
    if (options[SDImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[SDImageCoderEncodeCompressionQuality] doubleValue];
    }
    properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(compressionQuality);
    CGColorRef backgroundColor = [options[SDImageCoderEncodeBackgroundColor] CGColor];
    if (backgroundColor) {
        properties[(__bridge NSString *)kCGImageDestinationBackgroundColor] = (__bridge id)(backgroundColor);
    }
    CGSize maxPixelSize = CGSizeZero;
    NSValue *maxPixelSizeValue = options[SDImageCoderEncodeMaxPixelSize];
    if (maxPixelSizeValue != nil) {
#if SD_MAC
        maxPixelSize = maxPixelSizeValue.sizeValue;
#else
        maxPixelSize = maxPixelSizeValue.CGSizeValue;
#endif
    }
    CGFloat pixelWidth = (CGFloat)CGImageGetWidth(imageRef);
    CGFloat pixelHeight = (CGFloat)CGImageGetHeight(imageRef);
    CGFloat finalPixelSize = 0;
    BOOL encodeFullImage = maxPixelSize.width == 0 || maxPixelSize.height == 0 || pixelWidth == 0 || pixelHeight == 0 || (pixelWidth <= maxPixelSize.width && pixelHeight <= maxPixelSize.height);
    if (!encodeFullImage) {
        // Thumbnail Encoding
        CGFloat pixelRatio = pixelWidth / pixelHeight;
        CGFloat maxPixelSizeRatio = maxPixelSize.width / maxPixelSize.height;
        if (pixelRatio > maxPixelSizeRatio) {
            finalPixelSize = MAX(maxPixelSize.width, maxPixelSize.width / pixelRatio);
        } else {
            finalPixelSize = MAX(maxPixelSize.height, maxPixelSize.height * pixelRatio);
        }
        properties[(__bridge NSString *)kCGImageDestinationImageMaxPixelSize] = @(finalPixelSize);
    }
    NSUInteger maxFileSize = [options[SDImageCoderEncodeMaxFileSize] unsignedIntegerValue];
    if (maxFileSize > 0) {
        properties[kSDCGImageDestinationRequestedFileSize] = @(maxFileSize);
        // Remove the quality if we have file size limit
        properties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = nil;
    }
    BOOL embedThumbnail = NO;
    if (options[SDImageCoderEncodeEmbedThumbnail]) {
        embedThumbnail = [options[SDImageCoderEncodeEmbedThumbnail] boolValue];
    }
    properties[(__bridge NSString *)kCGImageDestinationEmbedThumbnail] = @(embedThumbnail);
    
    BOOL encodeFirstFrame = [options[SDImageCoderEncodeFirstFrameOnly] boolValue];
    if (encodeFirstFrame || frames.count <= 1) {
        // for static single images
        CGImageDestinationAddImage(imageDestination, imageRef, (__bridge CFDictionaryRef)properties);
    } else {
        // for animated images
        NSDictionary *containerProperties = @{
            self.class.dictionaryProperty: @{self.class.loopCountProperty : @(loopCount)}
        };
        // container level properties (applies for `CGImageDestinationSetProperties`, not individual frames)
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)containerProperties);
        
        for (size_t i = 0; i < frames.count; i++) {
            SDImageFrame *frame = frames[i];
            NSTimeInterval frameDuration = frame.duration;
            CGImageRef frameImageRef = frame.image.CGImage;
            properties[self.class.dictionaryProperty] = @{self.class.delayTimeProperty : @(frameDuration)};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)properties);
        }
    }
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

#pragma mark - SDAnimatedImageCoder
- (nullable instancetype)initWithAnimatedImageData:(nullable NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    self = [super init];
    if (self) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        if (!imageSource) {
            return nil;
        }
        BOOL framesValid = [self scanAndCheckFramesValidWithImageSource:imageSource];
        if (!framesValid) {
            CFRelease(imageSource);
            return nil;
        }
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = MAX([scaleFactor doubleValue], 1);
        }
        _scale = scale;
        CGSize thumbnailSize = CGSizeZero;
        NSValue *thumbnailSizeValue = options[SDImageCoderDecodeThumbnailPixelSize];
        if (thumbnailSizeValue != nil) {
    #if SD_MAC
            thumbnailSize = thumbnailSizeValue.sizeValue;
    #else
            thumbnailSize = thumbnailSizeValue.CGSizeValue;
    #endif
        }
        _thumbnailSize = thumbnailSize;
        BOOL preserveAspectRatio = YES;
        NSNumber *preserveAspectRatioValue = options[SDImageCoderDecodePreserveAspectRatio];
        if (preserveAspectRatioValue != nil) {
            preserveAspectRatio = preserveAspectRatioValue.boolValue;
        }
        _preserveAspectRatio = preserveAspectRatio;
        NSUInteger limitBytes = 0;
        NSNumber *limitBytesValue = options[SDImageCoderDecodeScaleDownLimitBytes];
        if (limitBytesValue != nil) {
            limitBytes = limitBytesValue.unsignedIntegerValue;
        }
        _limitBytes = limitBytes;
        // Parse the image properties
        NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        _width = [properties[(__bridge NSString *)kCGImagePropertyPixelWidth] doubleValue];
        _height = [properties[(__bridge NSString *)kCGImagePropertyPixelHeight] doubleValue];
        // Scale down to limit bytes if need
        if (_limitBytes > 0) {
            // Hack since ImageIO public API (not CGImageDecompressor/CMPhoto) always return back RGBA8888 CGImage
            CGSize imageSize = CGSizeMake(_width, _height);
            CGSize framePixelSize = [SDImageCoderHelper scaledSizeWithImageSize:imageSize limitBytes:_limitBytes bytesPerPixel:4 frameCount:_frameCount];
            // Override thumbnail size
            _thumbnailSize = framePixelSize;
            _preserveAspectRatio = YES;
        }
        BOOL lazyDecode = NO; // Defaults NO for animated image coder
        NSNumber *lazyDecodeValue = options[SDImageCoderDecodeUseLazyDecoding];
        if (lazyDecodeValue != nil) {
            lazyDecode = lazyDecodeValue.boolValue;
        }
        _lazyDecode = lazyDecode;
        _imageSource = imageSource;
        _imageData = data;
#if SD_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (BOOL)scanAndCheckFramesValidWithImageSource:(CGImageSourceRef)imageSource {
    if (!imageSource) {
        return NO;
    }
    NSUInteger frameCount = CGImageSourceGetCount(imageSource);
    NSUInteger loopCount = [self.class imageLoopCountWithSource:imageSource];
    _loopCount = loopCount;
    
    NSMutableArray<SDImageIOCoderFrame *> *frames = [NSMutableArray arrayWithCapacity:frameCount];
    for (size_t i = 0; i < frameCount; i++) {
        SDImageIOCoderFrame *frame = [[SDImageIOCoderFrame alloc] init];
        frame.index = i;
        frame.duration = [self.class frameDurationAtIndex:i source:imageSource];
        [frames addObject:frame];
    }
    if (frames.count != frameCount) {
        // frames not match, do not override current value
        return NO;
    }
    
    _frameCount = frameCount;
    _frames = [frames copy];
    
    return YES;
}

- (NSData *)animatedImageData {
    return _imageData;
}

- (NSUInteger)animatedImageLoopCount {
    return _loopCount;
}

- (NSUInteger)animatedImageFrameCount {
    return _frameCount;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    NSTimeInterval duration;
    // Incremental Animation decoding may update frames when new bytes available
    // Which should use lock to ensure frame count and frames match, ensure atomic logic
    if (_incremental) {
        SD_LOCK(_lock);
        if (index >= _frames.count) {
            SD_UNLOCK(_lock);
            return 0;
        }
        duration = _frames[index].duration;
        SD_UNLOCK(_lock);
    } else {
        if (index >= _frames.count) {
            return 0;
        }
        duration = _frames[index].duration;
    }
    return duration;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    UIImage *image;
    // Incremental Animation decoding may update frames when new bytes available
    // Which should use lock to ensure frame count and frames match, ensure atomic logic
    if (_incremental) {
        SD_LOCK(_lock);
        if (index >= _frames.count) {
            SD_UNLOCK(_lock);
            return nil;
        }
        image = [self safeAnimatedImageFrameAtIndex:index];
        SD_UNLOCK(_lock);
    } else {
        if (index >= _frames.count) {
            return nil;
        }
        image = [self safeAnimatedImageFrameAtIndex:index];
    }
    return image;
}

- (UIImage *)safeAnimatedImageFrameAtIndex:(NSUInteger)index {
    UIImage *image = [self.class createFrameAtIndex:index source:_imageSource scale:_scale preserveAspectRatio:_preserveAspectRatio thumbnailSize:_thumbnailSize lazyDecode:_lazyDecode animatedImage:YES];
    if (!image) {
        return nil;
    }
    image.sd_imageFormat = self.class.imageFormat;
    return image;
}

@end

