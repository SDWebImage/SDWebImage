/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCacheDefine.h"
#import "SDImageCodersManager.h"
#import "SDImageCoderHelper.h"
#import "SDAnimatedImage.h"
#import "UIImage+Metadata.h"
#import "SDInternalMacros.h"

#import <CoreServices/CoreServices.h>

SDImageCoderOptions * _Nonnull SDGetDecodeOptionsFromContext(SDWebImageContext * _Nullable context, SDWebImageOptions options, NSString * _Nonnull cacheKey) {
    BOOL decodeFirstFrame = SD_OPTIONS_CONTAINS(options, SDWebImageDecodeFirstFrameOnly);
    NSNumber *scaleValue = context[SDWebImageContextImageScaleFactor];
    CGFloat scale = scaleValue.doubleValue >= 1 ? scaleValue.doubleValue : SDImageScaleFactorForKey(cacheKey); // Use cache key to detect scale
    NSNumber *preserveAspectRatioValue = context[SDWebImageContextImagePreserveAspectRatio];
    NSValue *thumbnailSizeValue;
    BOOL shouldScaleDown = SD_OPTIONS_CONTAINS(options, SDWebImageScaleDownLargeImages);
    NSNumber *scaleDownLimitBytesValue = context[SDWebImageContextImageScaleDownLimitBytes];
    if (scaleDownLimitBytesValue == nil && shouldScaleDown) {
        // Use the default limit bytes
        scaleDownLimitBytesValue = @(SDImageCoderHelper.defaultScaleDownLimitBytes);
    }
    if (context[SDWebImageContextImageThumbnailPixelSize]) {
        thumbnailSizeValue = context[SDWebImageContextImageThumbnailPixelSize];
    }
    NSString *typeIdentifierHint = context[SDWebImageContextImageTypeIdentifierHint];
    NSString *fileExtensionHint;
    if (!typeIdentifierHint) {
        // UTI has high priority
        fileExtensionHint = cacheKey.pathExtension; // without dot
        if (fileExtensionHint.length == 0) {
            // Ignore file extension which is empty
            fileExtensionHint = nil;
        }
    }
    
    // First check if user provided decode options
    SDImageCoderMutableOptions *mutableCoderOptions;
    if (context[SDWebImageContextImageDecodeOptions] != nil) {
        mutableCoderOptions = [NSMutableDictionary dictionaryWithDictionary:context[SDWebImageContextImageDecodeOptions]];
    } else {
        mutableCoderOptions = [NSMutableDictionary dictionaryWithCapacity:6];
    }
    
    // Override individual options
    mutableCoderOptions[SDImageCoderDecodeFirstFrameOnly] = @(decodeFirstFrame);
    mutableCoderOptions[SDImageCoderDecodeScaleFactor] = @(scale);
    mutableCoderOptions[SDImageCoderDecodePreserveAspectRatio] = preserveAspectRatioValue;
    mutableCoderOptions[SDImageCoderDecodeThumbnailPixelSize] = thumbnailSizeValue;
    mutableCoderOptions[SDImageCoderDecodeTypeIdentifierHint] = typeIdentifierHint;
    mutableCoderOptions[SDImageCoderDecodeFileExtensionHint] = fileExtensionHint;
    mutableCoderOptions[SDImageCoderDecodeScaleDownLimitBytes] = scaleDownLimitBytesValue;
    
    return [mutableCoderOptions copy];
}

void SDSetDecodeOptionsToContext(SDWebImageMutableContext * _Nonnull mutableContext, SDWebImageOptions * _Nonnull mutableOptions, SDImageCoderOptions * _Nonnull decodeOptions) {
    if ([decodeOptions[SDImageCoderDecodeFirstFrameOnly] boolValue]) {
        *mutableOptions |= SDWebImageDecodeFirstFrameOnly;
    } else {
        *mutableOptions &= ~SDWebImageDecodeFirstFrameOnly;
    }
    
    mutableContext[SDWebImageContextImageScaleFactor] = decodeOptions[SDImageCoderDecodeScaleFactor];
    mutableContext[SDWebImageContextImagePreserveAspectRatio] = decodeOptions[SDImageCoderDecodePreserveAspectRatio];
    mutableContext[SDWebImageContextImageThumbnailPixelSize] = decodeOptions[SDImageCoderDecodeThumbnailPixelSize];
    mutableContext[SDWebImageContextImageScaleDownLimitBytes] = decodeOptions[SDImageCoderDecodeScaleDownLimitBytes];
    
    NSString *typeIdentifierHint = decodeOptions[SDImageCoderDecodeTypeIdentifierHint];
    if (!typeIdentifierHint) {
        NSString *fileExtensionHint = decodeOptions[SDImageCoderDecodeFileExtensionHint];
        if (fileExtensionHint) {
            typeIdentifierHint = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtensionHint, kUTTypeImage);
            // Ignore dynamic UTI
            if (UTTypeIsDynamic((__bridge CFStringRef)typeIdentifierHint)) {
                typeIdentifierHint = nil;
            }
        }
    }
    mutableContext[SDWebImageContextImageTypeIdentifierHint] = typeIdentifierHint;
}

UIImage * _Nullable SDImageCacheDecodeImageData(NSData * _Nonnull imageData, NSString * _Nonnull cacheKey, SDWebImageOptions options, SDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(cacheKey);
    UIImage *image;
    SDImageCoderOptions *coderOptions = SDGetDecodeOptionsFromContext(context, options, cacheKey);
    BOOL decodeFirstFrame = SD_OPTIONS_CONTAINS(options, SDWebImageDecodeFirstFrameOnly);
    CGFloat scale = [coderOptions[SDImageCoderDecodeScaleFactor] doubleValue];
    
    // Grab the image coder
    id<SDImageCoder> imageCoder = context[SDWebImageContextImageCoder];
    if (!imageCoder) {
        imageCoder = [SDImageCodersManager sharedManager];
    }
    
    if (!decodeFirstFrame) {
        Class animatedImageClass = context[SDWebImageContextAnimatedImageClass];
        // check whether we should use `SDAnimatedImage`
        if ([animatedImageClass isSubclassOfClass:[UIImage class]] && [animatedImageClass conformsToProtocol:@protocol(SDAnimatedImage)]) {
            image = [[animatedImageClass alloc] initWithData:imageData scale:scale options:coderOptions];
            if (image) {
                // Preload frames if supported
                if (options & SDWebImagePreloadAllFrames && [image respondsToSelector:@selector(preloadAllFrames)]) {
                    [((id<SDAnimatedImage>)image) preloadAllFrames];
                }
            } else {
                // Check image class matching
                if (options & SDWebImageMatchAnimatedImageClass) {
                    return nil;
                }
            }
        }
    }
    if (!image) {
        image = [imageCoder decodedImageWithData:imageData options:coderOptions];
    }
    if (image) {
        SDImageForceDecodePolicy policy = SDImageForceDecodePolicyAutomatic;
        NSNumber *polivyValue = context[SDWebImageContextImageForceDecodePolicy];
        if (polivyValue != nil) {
            policy = polivyValue.unsignedIntegerValue;
        }
        // TODO: Deprecated, remove in SD 6.0...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (SD_OPTIONS_CONTAINS(options, SDWebImageAvoidDecodeImage)) {
            policy = SDImageForceDecodePolicyNever;
        }
#pragma clang diagnostic pop
        image = [SDImageCoderHelper decodedImageWithImage:image policy:policy];
        // assign the decode options, to let manager check whether to re-decode if needed
        image.sd_decodeOptions = coderOptions;
    }
    
    return image;
}
