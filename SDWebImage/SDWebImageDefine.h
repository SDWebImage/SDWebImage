/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

typedef void(^SDWebImageNoParamsBlock)(void);
typedef NSString * SDWebImageContextOption NS_STRING_ENUM;
typedef NSDictionary<SDWebImageContextOption, id> SDWebImageContext;

#pragma mark - Image scale

/**
 Return the image scale from the specify key, supports file name and url key

 @param key The image cache key
 @return The scale factor for image
 */
FOUNDATION_EXPORT CGFloat SDImageScaleForKey(NSString * _Nullable key);

/**
 Scale the image with the scale factor from the specify key. If no need to scale, return the original image
 This only works for `UIImage`(UIKit) or `NSImage`(AppKit).

 @param key The image cache key
 @param image The image
 @return The scaled image
 */
FOUNDATION_EXPORT UIImage * _Nullable SDScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image);

#pragma mark - Context option

/**
 A Dispatch group to maintain setImageBlock and completionBlock. This is used for custom setImageBlock advanced usage, such like perform background task but need to guarantee the completion block is called after setImageBlock. (dispatch_group_t)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSetImageGroup;

/**
 A SDWebImageManager instance to control the image download and cache process using in UIImageView+WebCache category and likes. If not provided, use the shared manager (SDWebImageManager)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCustomManager;

/**
 A id<SDWebImageTransformer> instance which conforms SDWebImageTransformer protocol. It's used for image transform after the image load finished and store the transformed image to cache. If you provide one, it will ignore the `transformer` in manager and use provided one instead. (id<SDWebImageTransformer>)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCustomTransformer;

/**
 A Class object which the instance is a `UIImage/NSImage` subclass and adopt `SDAnimatedImage` protocol. We will call `initWithData:scale:` to create the instance (or `initWithAnimatedCoder:sclae` when using progressive download) . If the instance create failed, fallback to normal `UIImage/NSImage`.
 This can be used to improve animated images rendering performance (especially memory usage on big animated images) with `SDAnimatedImageView` (Class).
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextAnimatedImageClass;
