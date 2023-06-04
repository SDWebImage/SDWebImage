/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDefine.h"
#import "UIImage+Metadata.h"
#import "NSImage+Compatibility.h"
#import "SDAnimatedImage.h"
#import "SDAssociatedObject.h"

#pragma mark - Image scale

static inline NSArray<NSNumber *> * _Nonnull SDImageScaleFactors(void) {
    return @[@2, @3];
}

inline CGFloat SDImageScaleFactorForKey(NSString * _Nullable key) {
    CGFloat scale = 1;
    if (!key) {
        return scale;
    }
    // Check if target OS support scale
#if SD_WATCH
    if ([[WKInterfaceDevice currentDevice] respondsToSelector:@selector(screenScale)])
#elif SD_UIKIT
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
#elif SD_MAC
    NSScreen *mainScreen = nil;
    if (@available(macOS 10.12, *)) {
        mainScreen = [NSScreen mainScreen];
    } else {
        mainScreen = [NSScreen screens].firstObject;
    }
    if ([mainScreen respondsToSelector:@selector(backingScaleFactor)])
#endif
    {
        // a@2x.png -> 8
        if (key.length >= 8) {
            // Fast check
            BOOL isURL = [key hasPrefix:@"http://"] || [key hasPrefix:@"https://"];
            for (NSNumber *scaleFactor in SDImageScaleFactors()) {
                // @2x. for file name and normal url
                NSString *fileScale = [NSString stringWithFormat:@"@%@x.", scaleFactor];
                if ([key containsString:fileScale]) {
                    scale = scaleFactor.doubleValue;
                    return scale;
                }
                if (isURL) {
                    // %402x. for url encode
                    NSString *urlScale = [NSString stringWithFormat:@"%%40%@x.", scaleFactor];
                    if ([key containsString:urlScale]) {
                        scale = scaleFactor.doubleValue;
                        return scale;
                    }
                }
            }
        }
    }
    return scale;
}

inline UIImage * _Nullable SDScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image) {
    if (!image) {
        return nil;
    }
    CGFloat scale = SDImageScaleFactorForKey(key);
    return SDScaledImageForScaleFactor(scale, image);
}

inline UIImage * _Nullable SDScaledImageForScaleFactor(CGFloat scale, UIImage * _Nullable image) {
    if (!image) {
        return nil;
    }
    if (scale <= 1) {
        return image;
    }
    if (scale == image.scale) {
        return image;
    }
    UIImage *scaledImage;
    // Check SDAnimatedImage support for shortcut
    if ([image.class conformsToProtocol:@protocol(SDAnimatedImage)]) {
        if ([image respondsToSelector:@selector(animatedCoder)]) {
            id<SDAnimatedImageCoder> coder = [(id<SDAnimatedImage>)image animatedCoder];
            if (coder) {
                scaledImage = [[image.class alloc] initWithAnimatedCoder:coder scale:scale];
            }
        } else {
            // Some class impl does not support `animatedCoder`, keep for compatibility
            NSData *data = [(id<SDAnimatedImage>)image animatedImageData];
            if (data) {
                scaledImage = [[image.class alloc] initWithData:data scale:scale];
            }
        }
        if (scaledImage) {
            return scaledImage;
        }
    }
    if (image.sd_isAnimated) {
        UIImage *animatedImage;
#if SD_UIKIT || SD_WATCH
        // `UIAnimatedImage` images share the same size and scale.
        NSArray<UIImage *> *images = image.images;
        NSMutableArray<UIImage *> *scaledImages = [NSMutableArray arrayWithCapacity:images.count];
        
        for (UIImage *tempImage in images) {
            UIImage *tempScaledImage = [[UIImage alloc] initWithCGImage:tempImage.CGImage scale:scale orientation:tempImage.imageOrientation];
            [scaledImages addObject:tempScaledImage];
        }
        
        animatedImage = [UIImage animatedImageWithImages:scaledImages duration:image.duration];
        animatedImage.sd_imageLoopCount = image.sd_imageLoopCount;
#else
        // Animated GIF for `NSImage` need to grab `NSBitmapImageRep`;
        NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
        NSImageRep *imageRep = [image bestRepresentationForRect:imageRect context:nil hints:nil];
        NSBitmapImageRep *bitmapImageRep;
        if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
            bitmapImageRep = (NSBitmapImageRep *)imageRep;
        }
        if (bitmapImageRep) {
            NSSize size = NSMakeSize(image.size.width / scale, image.size.height / scale);
            animatedImage = [[NSImage alloc] initWithSize:size];
            bitmapImageRep.size = size;
            [animatedImage addRepresentation:bitmapImageRep];
        }
#endif
        scaledImage = animatedImage;
    } else {
#if SD_UIKIT || SD_WATCH
        scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
#else
        scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
    }
    SDImageCopyAssociatedObject(image, scaledImage);
    
    return scaledImage;
}

#pragma mark - Context option

SDWebImageContextOption const SDWebImageContextSetImageOperationKey = @"setImageOperationKey";
SDWebImageContextOption const SDWebImageContextCustomManager = @"customManager";
SDWebImageContextOption const SDWebImageContextCallbackQueue = @"callbackQueue";
SDWebImageContextOption const SDWebImageContextImageCache = @"imageCache";
SDWebImageContextOption const SDWebImageContextImageLoader = @"imageLoader";
SDWebImageContextOption const SDWebImageContextImageCoder = @"imageCoder";
SDWebImageContextOption const SDWebImageContextImageTransformer = @"imageTransformer";
SDWebImageContextOption const SDWebImageContextImageDecodeOptions = @"imageDecodeOptions";
SDWebImageContextOption const SDWebImageContextImageScaleFactor = @"imageScaleFactor";
SDWebImageContextOption const SDWebImageContextImagePreserveAspectRatio = @"imagePreserveAspectRatio";
SDWebImageContextOption const SDWebImageContextImageThumbnailPixelSize = @"imageThumbnailPixelSize";
SDWebImageContextOption const SDWebImageContextImageTypeIdentifierHint = @"imageTypeIdentifierHint";
SDWebImageContextOption const SDWebImageContextImageScaleDownLimitBytes = @"imageScaleDownLimitBytes";
SDWebImageContextOption const SDWebImageContextImageEncodeOptions = @"imageEncodeOptions";
SDWebImageContextOption const SDWebImageContextQueryCacheType = @"queryCacheType";
SDWebImageContextOption const SDWebImageContextStoreCacheType = @"storeCacheType";
SDWebImageContextOption const SDWebImageContextOriginalQueryCacheType = @"originalQueryCacheType";
SDWebImageContextOption const SDWebImageContextOriginalStoreCacheType = @"originalStoreCacheType";
SDWebImageContextOption const SDWebImageContextOriginalImageCache = @"originalImageCache";
SDWebImageContextOption const SDWebImageContextAnimatedImageClass = @"animatedImageClass";
SDWebImageContextOption const SDWebImageContextDownloadRequestModifier = @"downloadRequestModifier";
SDWebImageContextOption const SDWebImageContextDownloadResponseModifier = @"downloadResponseModifier";
SDWebImageContextOption const SDWebImageContextDownloadDecryptor = @"downloadDecryptor";
SDWebImageContextOption const SDWebImageContextCacheKeyFilter = @"cacheKeyFilter";
SDWebImageContextOption const SDWebImageContextCacheSerializer = @"cacheSerializer";
