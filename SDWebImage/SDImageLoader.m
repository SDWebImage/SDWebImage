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
#import "objc/runtime.h"

static void * SDImageLoaderProgressiveCoderKey = &SDImageLoaderProgressiveCoderKey;

UIImage * _Nullable SDImageLoaderDecodeImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, SDWebImageOptions options, SDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(imageURL);
    
    UIImage *image;
    id<SDWebImageCacheKeyFilter> cacheKeyFilter = [context valueForKey:SDWebImageContextCacheKeyFilter];
    NSString *cacheKey;
    if (cacheKeyFilter) {
        cacheKey = [cacheKeyFilter cacheKeyForURL:imageURL];
    } else {
        cacheKey = imageURL.absoluteString;
    }
    BOOL decodeFirstFrame = options & SDWebImageDecodeFirstFrameOnly;
    NSNumber *scaleValue = [context valueForKey:SDWebImageContextImageScaleFactor];
    CGFloat scale = scaleValue.doubleValue >= 1 ? scaleValue.doubleValue : SDImageScaleFactorForKey(cacheKey);
    if (scale < 1) {
        scale = 1;
    }
    if (!decodeFirstFrame) {
        // check whether we should use `SDAnimatedImage`
        if ([context valueForKey:SDWebImageContextAnimatedImageClass]) {
            Class animatedImageClass = [context valueForKey:SDWebImageContextAnimatedImageClass];
            if ([animatedImageClass isSubclassOfClass:[UIImage class]] && [animatedImageClass conformsToProtocol:@protocol(SDAnimatedImage)]) {
                image = [[animatedImageClass alloc] initWithData:imageData scale:scale];
                if (options & SDWebImagePreloadAllFrames && [image respondsToSelector:@selector(preloadAllFrames)]) {
                    [((id<SDAnimatedImage>)image) preloadAllFrames];
                }
            }
        }
    }
    if (!image) {
        SDImageCoderOptions *options = @{SDImageCoderDecodeFirstFrameOnly : @(decodeFirstFrame), SDImageCoderDecodeScaleFactor : @(scale)};
        if (context) {
            SDImageCoderMutableOptions *mutableOptions = [options mutableCopy];
            [mutableOptions setValue:context forKey:SDImageCoderWebImageContext];
            options = [mutableOptions copy];
        }
        image = [[SDImageCodersManager sharedManager] decodedImageWithData:imageData options:options];
    }
    if (image) {
        BOOL shouldDecode = (options & SDWebImageAvoidDecodeImage) == 0;
        if ([image conformsToProtocol:@protocol(SDAnimatedImage)]) {
            // `SDAnimatedImage` do not decode
            shouldDecode = NO;
        } else if (image.sd_isAnimated) {
            // animated image do not decode
            shouldDecode = NO;
        }
        
        if (shouldDecode) {
            BOOL shouldScaleDown = options & SDWebImageScaleDownLargeImages;
            if (shouldScaleDown) {
                image = [SDImageCoderHelper decodedAndScaledDownImageWithImage:image limitBytes:0];
            } else {
                image = [SDImageCoderHelper decodedImageWithImage:image];
            }
        }
    }
    
    return image;
}

UIImage * _Nullable SDImageLoaderDecodeProgressiveImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, BOOL finished,  id<SDWebImageOperation> _Nonnull operation, SDWebImageOptions options, SDWebImageContext * _Nullable context) {
    NSCParameterAssert(imageData);
    NSCParameterAssert(imageURL);
    NSCParameterAssert(operation);
    
    UIImage *image;
    id<SDWebImageCacheKeyFilter> cacheKeyFilter = [context valueForKey:SDWebImageContextCacheKeyFilter];
    NSString *cacheKey;
    if (cacheKeyFilter) {
        cacheKey = [cacheKeyFilter cacheKeyForURL:imageURL];
    } else {
        cacheKey = imageURL.absoluteString;
    }
    BOOL decodeFirstFrame = options & SDWebImageDecodeFirstFrameOnly;
    NSNumber *scaleValue = [context valueForKey:SDWebImageContextImageScaleFactor];
    CGFloat scale = scaleValue.doubleValue >= 1 ? scaleValue.doubleValue : SDImageScaleFactorForKey(cacheKey);
    if (scale < 1) {
        scale = 1;
    }
    id<SDProgressiveImageCoder> progressiveCoder = objc_getAssociatedObject(operation, SDImageLoaderProgressiveCoderKey);
    if (!progressiveCoder) {
        // We need to create a new instance for progressive decoding to avoid conflicts
        for (id<SDImageCoder>coder in [SDImageCodersManager sharedManager].coders.reverseObjectEnumerator) {
            if ([coder conformsToProtocol:@protocol(SDProgressiveImageCoder)] &&
                [((id<SDProgressiveImageCoder>)coder) canIncrementalDecodeFromData:imageData]) {
                progressiveCoder = [[[coder class] alloc] initIncrementalWithOptions:@{SDImageCoderDecodeScaleFactor : @(scale)}];
                break;
            }
        }
        objc_setAssociatedObject(operation, SDImageLoaderProgressiveCoderKey, progressiveCoder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // If we can't find any progressive coder, disable progressive download
    if (!progressiveCoder) {
        return nil;
    }
    
    [progressiveCoder updateIncrementalData:imageData finished:finished];
    if (!decodeFirstFrame) {
        // check whether we should use `SDAnimatedImage`
        if ([context valueForKey:SDWebImageContextAnimatedImageClass]) {
            Class animatedImageClass = [context valueForKey:SDWebImageContextAnimatedImageClass];
            if ([animatedImageClass isSubclassOfClass:[UIImage class]] && [animatedImageClass conformsToProtocol:@protocol(SDAnimatedImage)] && [progressiveCoder conformsToProtocol:@protocol(SDAnimatedImageCoder)]) {
                image = [[animatedImageClass alloc] initWithAnimatedCoder:(id<SDAnimatedImageCoder>)progressiveCoder scale:scale];
            }
        }
    }
    if (!image) {
        SDImageCoderOptions *options = @{SDImageCoderDecodeFirstFrameOnly : @(decodeFirstFrame), SDImageCoderDecodeScaleFactor : @(scale)};
        if (context) {
            SDImageCoderMutableOptions *mutableOptions = [options mutableCopy];
            [mutableOptions setValue:context forKey:SDImageCoderWebImageContext];
            options = [mutableOptions copy];
        }
        image = [progressiveCoder incrementalDecodedImageWithOptions:options];
    }
    if (image) {
        BOOL shouldDecode = (options & SDWebImageAvoidDecodeImage) == 0;
        if ([image conformsToProtocol:@protocol(SDAnimatedImage)]) {
            // `SDAnimatedImage` do not decode
            shouldDecode = NO;
        } else if (image.sd_isAnimated) {
            // animated image do not decode
            shouldDecode = NO;
        }
        if (shouldDecode) {
            image = [SDImageCoderHelper decodedImageWithImage:image];
        }
        // mark the image as progressive (completionBlock one are not mark as progressive)
        image.sd_isIncremental = YES;
    }
    
    return image;
}

SDWebImageContextOption const SDWebImageContextLoaderCachedImage = @"loaderCachedImage";
