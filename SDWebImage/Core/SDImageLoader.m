/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageLoader.h"
#import "SDWebImageCacheKeyFilter.h"
#import "SDImageCodersManager.h"
#import "SDImageCoderHelper.h"
#import "SDAnimatedImage.h"
#import "UIImage+Metadata.h"
#import "SDInternalMacros.h"
#import "SDImageCacheDefine.h"
#import "objc/runtime.h"

SDWebImageContextOption const SDWebImageContextLoaderCachedImage = @"loaderCachedImage";

static void * SDImageLoaderProgressiveCoderKey = &SDImageLoaderProgressiveCoderKey;

id<SDProgressiveImageCoder> SDImageLoaderGetProgressiveCoder(id<SDWebImageOperation> operation) {
    NSCParameterAssert(operation);
    return objc_getAssociatedObject(operation, SDImageLoaderProgressiveCoderKey);
}

void SDImageLoaderSetProgressiveCoder(id<SDWebImageOperation> operation, id<SDProgressiveImageCoder> progressiveCoder) {
    NSCParameterAssert(operation);
    objc_setAssociatedObject(operation, SDImageLoaderProgressiveCoderKey, progressiveCoder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

UIImage * _Nullable SDImageLoaderDecodeImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, SDWebImageOptions options, SDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(imageURL);
    
    UIImage *image;
    id<SDWebImageCacheKeyFilter> cacheKeyFilter = context[SDWebImageContextCacheKeyFilter];
    NSString *cacheKey;
    if (cacheKeyFilter) {
        cacheKey = [cacheKeyFilter cacheKeyForURL:imageURL];
    } else {
        cacheKey = imageURL.absoluteString;
    }
    SDImageCoderOptions *coderOptions = SDGetDecodeOptionsFromContext(context, options, cacheKey);
    BOOL decodeFirstFrame = SD_OPTIONS_CONTAINS(options, SDWebImageDecodeFirstFrameOnly);
    CGFloat scale = [coderOptions[SDImageCoderDecodeScaleFactor] doubleValue];
    
    // Grab the image coder
    id<SDImageCoder> imageCoder;
    if ([context[SDWebImageContextImageCoder] conformsToProtocol:@protocol(SDImageCoder)]) {
        imageCoder = context[SDWebImageContextImageCoder];
    } else {
        imageCoder = [SDImageCodersManager sharedManager];
    }
    
    if (!decodeFirstFrame) {
        // check whether we should use `SDAnimatedImage`
        Class animatedImageClass = context[SDWebImageContextAnimatedImageClass];
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
        BOOL shouldDecode = !SD_OPTIONS_CONTAINS(options, SDWebImageAvoidDecodeImage);
        if ([image.class conformsToProtocol:@protocol(SDAnimatedImage)]) {
            // `SDAnimatedImage` do not decode
            shouldDecode = NO;
        } else if (image.sd_isAnimated) {
            // animated image do not decode
            shouldDecode = NO;
        }
        
        if (shouldDecode) {
            image = [SDImageCoderHelper decodedImageWithImage:image];
        }
        // assign the decode options, to let manager check whether to re-decode if needed
        image.sd_decodeOptions = coderOptions;
    }
    
    return image;
}

UIImage * _Nullable SDImageLoaderDecodeProgressiveImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, BOOL finished,  id<SDWebImageOperation> _Nonnull operation, SDWebImageOptions options, SDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(imageURL);
    NSCParameterAssert(operation);
    
    UIImage *image;
    id<SDWebImageCacheKeyFilter> cacheKeyFilter = context[SDWebImageContextCacheKeyFilter];
    NSString *cacheKey;
    if (cacheKeyFilter) {
        cacheKey = [cacheKeyFilter cacheKeyForURL:imageURL];
    } else {
        cacheKey = imageURL.absoluteString;
    }
    SDImageCoderOptions *coderOptions = SDGetDecodeOptionsFromContext(context, options, cacheKey);
    BOOL decodeFirstFrame = SD_OPTIONS_CONTAINS(options, SDWebImageDecodeFirstFrameOnly);
    CGFloat scale = [coderOptions[SDImageCoderDecodeScaleFactor] doubleValue];
    
    // Grab the progressive image coder
    id<SDProgressiveImageCoder> progressiveCoder = SDImageLoaderGetProgressiveCoder(operation);
    if (!progressiveCoder) {
        id<SDProgressiveImageCoder> imageCoder = context[SDWebImageContextImageCoder];
        // Check the progressive coder if provided
        if ([imageCoder conformsToProtocol:@protocol(SDProgressiveImageCoder)]) {
            progressiveCoder = [[[imageCoder class] alloc] initIncrementalWithOptions:coderOptions];
        } else {
            // We need to create a new instance for progressive decoding to avoid conflicts
            for (id<SDImageCoder> coder in [SDImageCodersManager sharedManager].coders.reverseObjectEnumerator) {
                if ([coder conformsToProtocol:@protocol(SDProgressiveImageCoder)] &&
                    [((id<SDProgressiveImageCoder>)coder) canIncrementalDecodeFromData:imageData]) {
                    progressiveCoder = [[[coder class] alloc] initIncrementalWithOptions:coderOptions];
                    break;
                }
            }
        }
        SDImageLoaderSetProgressiveCoder(operation, progressiveCoder);
    }
    // If we can't find any progressive coder, disable progressive download
    if (!progressiveCoder) {
        return nil;
    }
    
    [progressiveCoder updateIncrementalData:imageData finished:finished];
    if (!decodeFirstFrame) {
        // check whether we should use `SDAnimatedImage`
        Class animatedImageClass = context[SDWebImageContextAnimatedImageClass];
        if ([animatedImageClass isSubclassOfClass:[UIImage class]] && [animatedImageClass conformsToProtocol:@protocol(SDAnimatedImage)] && [progressiveCoder conformsToProtocol:@protocol(SDAnimatedImageCoder)]) {
            image = [[animatedImageClass alloc] initWithAnimatedCoder:(id<SDAnimatedImageCoder>)progressiveCoder scale:scale];
            if (image) {
                // Progressive decoding does not preload frames
            } else {
                // Check image class matching
                if (options & SDWebImageMatchAnimatedImageClass) {
                    return nil;
                }
            }
        }
    }
    if (!image) {
        image = [progressiveCoder incrementalDecodedImageWithOptions:coderOptions];
    }
    if (image) {
        BOOL shouldDecode = !SD_OPTIONS_CONTAINS(options, SDWebImageAvoidDecodeImage);
        if ([image.class conformsToProtocol:@protocol(SDAnimatedImage)]) {
            // `SDAnimatedImage` do not decode
            shouldDecode = NO;
        } else if (image.sd_isAnimated) {
            // animated image do not decode
            shouldDecode = NO;
        }
        if (shouldDecode) {
            image = [SDImageCoderHelper decodedImageWithImage:image];
        }
        // mark the image as progressive (completed one are not mark as progressive)
        image.sd_isIncremental = !finished;
        // assign the decode options, to let manager check whether to re-decode if needed
        image.sd_decodeOptions = coderOptions;
    }
    
    return image;
}
