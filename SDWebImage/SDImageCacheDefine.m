/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCacheDefine.h"
#import "SDWebImageCodersManager.h"
#import "SDWebImageCoderHelper.h"
#import "SDAnimatedImage.h"
#import "UIImage+WebCache.h"

UIImage * _Nullable SDWebImageCacheDecodeImageData(NSData * _Nonnull imageData, NSString * _Nonnull cacheKey, SDWebImageOptions options, SDWebImageContext * _Nullable context) {
    UIImage *image;
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
        image = [[SDWebImageCodersManager sharedManager] decodedImageWithData:imageData options:@{SDWebImageCoderDecodeFirstFrameOnly : @(decodeFirstFrame), SDWebImageCoderDecodeScaleFactor : @(scale)}];
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
                image = [SDWebImageCoderHelper decodedAndScaledDownImageWithImage:image limitBytes:0];
            } else {
                image = [SDWebImageCoderHelper decodedImageWithImage:image];
            }
        }
    }
    
    return image;
}
