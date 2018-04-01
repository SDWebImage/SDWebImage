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
typedef NSMutableDictionary<SDWebImageContextOption, id> SDWebImageMutableContext;

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

#pragma mark - WebCache Options

typedef NS_OPTIONS(NSUInteger, SDWebImageOptions) {
    /**
     * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
     * This flag disable this blacklisting.
     */
    SDWebImageRetryFailed = 1 << 0,
    
    /**
     * By default, image downloads are started during UI interactions, this flags disable this feature,
     * leading to delayed download on UIScrollView deceleration for instance.
     */
    SDWebImageLowPriority = 1 << 1,
    
    /**
     * This flag disables on-disk caching after the download finished, only cache in memory
     */
    SDWebImageCacheMemoryOnly = 1 << 2,
    
    /**
     * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
     * By default, the image is only displayed once completely downloaded.
     */
    SDWebImageProgressiveDownload = 1 << 3,
    
    /**
     * Even if the image is cached, respect the HTTP response cache control, and refresh the image from remote location if needed.
     * The disk caching will be handled by NSURLCache instead of SDWebImage leading to slight performance degradation.
     * This option helps deal with images changing behind the same request URL, e.g. Facebook graph api profile pics.
     * If a cached image is refreshed, the completion block is called once with the cached image and again with the final image.
     *
     * Use this flag only if you can't make your URLs static with embedded cache busting parameter.
     */
    SDWebImageRefreshCached = 1 << 4,
    
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    SDWebImageContinueInBackground = 1 << 5,
    
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    SDWebImageHandleCookies = 1 << 6,
    
    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    SDWebImageAllowInvalidSSLCertificates = 1 << 7,
    
    /**
     * By default, images are loaded in the order in which they were queued. This flag moves them to
     * the front of the queue.
     */
    SDWebImageHighPriority = 1 << 8,
    
    /**
     * By default, placeholder images are loaded while the image is loading. This flag will delay the loading
     * of the placeholder image until after the image has finished loading.
     */
    SDWebImageDelayPlaceholder = 1 << 9,
    
    /**
     * We usually don't apply transform on animated images as most transformers could not manage animated images.
     * Use this flag to transform them anyway.
     */
    SDWebImageTransformAnimatedImage = 1 << 10,
    
    /**
     * By default, image is added to the imageView after download. But in some cases, we want to
     * have the hand before setting the image (apply a filter or add it with cross-fade animation for instance)
     * Use this flag if you want to manually set the image in the completion when success
     */
    SDWebImageAvoidAutoSetImage = 1 << 11,
    
    /**
     * By default, images are decoded respecting their original size. On iOS, this flag will scale down the
     * images to a size compatible with the constrained memory of devices.
     * If `SDWebImageProgressiveDownload` flag is set the scale down is deactivated.
     */
    SDWebImageScaleDownLargeImages = 1 << 12,
    
    /**
     * By default, we do not query disk data when the image is cached in memory. This mask can force to query disk data at the same time.
     * This flag is recommend to be used with `SDWebImageQueryDiskSync` to ensure the image is loaded in the same runloop.
     */
    SDWebImageQueryDataWhenInMemory = 1 << 13,
    
    /**
     * By default, we query the memory cache synchronously, disk cache asynchronously. This mask can force to query disk cache synchronously to ensure that image is loaded in the same runloop.
     * This flag can avoid flashing during cell reuse if you disable memory cache or in some other cases.
     */
    SDWebImageQueryDiskSync = 1 << 14,
    
    /**
     * By default, when the cache missed, the image is download from the network. This flag can prevent network to load from cache only.
     */
    SDWebImageFromCacheOnly = 1 << 15,
    
    /**
     * By default, when you use `SDWebImageTransition` to do some view transition after the image load finished, this transition is only applied for image download from the network. This mask can force to apply view transition for memory and disk cache as well.
     */
    SDWebImageForceTransition = 1 << 16,
    
    /**
     * By default, we decode the animated image. This flag can force decode the first frame only and produece the static image.
     */
    SDWebImageDecodeFirstFrameOnly = 1 << 17,
    
    /**
     * By default, for `SDAnimatedImage`, we decode the animated image frame during rendering to reduce memory usage. However, you can specify to preload all frames into memory to reduce CPU usage when the animated image is shared by lots of imageViews.
     * This will actually trigger `preloadAllAnimatedImageFrames` in the background queue(Disk Cache & Download only).
     */
    SDWebImagePreloadAllFrames = 1 << 18
};


#pragma mark - Context Options

/**
 A String to be used as the operation key for view category to store the image load operation. This is used for view instance which supports different image loading process. If nil, will use the class name as operation key. (NSString *)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSetImageOperationKey;

/**
 A Dispatch group to maintain setImageBlock and completionBlock for view category. This is used for custom setImageBlock advanced usage, such like perform background task but need to guarantee the completion block is called after setImageBlock. (dispatch_group_t)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSetImageGroup;

/**
 A SDWebImageManager instance to control the image download and cache process using in UIImageView+WebCache category and likes. If not provided, use the shared manager (SDWebImageManager *)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCustomManager;

/**
 A id<SDWebImageTransformer> instance which conforms SDWebImageTransformer protocol. It's used for image transform after the image load finished and store the transformed image to cache. If you provide one, it will ignore the `transformer` in manager and use provided one instead. (id<SDWebImageTransformer>)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCustomTransformer;

/**
 A Class object which the instance is a `UIImage/NSImage` subclass and adopt `SDAnimatedImage` protocol. We will call `initWithData:scale:` to create the instance (or `initWithAnimatedCoder:scale` when using progressive download) . If the instance create failed, fallback to normal `UIImage/NSImage`.
 This can be used to improve animated images rendering performance (especially memory usage on big animated images) with `SDAnimatedImageView` (Class).
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextAnimatedImageClass;
