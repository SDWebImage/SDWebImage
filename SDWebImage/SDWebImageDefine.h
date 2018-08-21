/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

typedef void(^SDWebImageNoParamsBlock)(void);
typedef NSString * SDWebImageContextOption NS_EXTENSIBLE_STRING_ENUM;
typedef NSDictionary<SDWebImageContextOption, id> SDWebImageContext;
typedef NSMutableDictionary<SDWebImageContextOption, id> SDWebImageMutableContext;

#pragma mark - Image scale

/**
 Return the image scale factor for the specify key, supports file name and url key.
 This is the built-in way to check the scale factor when we have no context about it. Because scale factor is not stored in image data (It's typically from filename).
 However, you can also provide custom scale factor as well, see `SDWebImageContextImageScaleFactor`.

 @param key The image cache key
 @return The scale factor for image
 */
FOUNDATION_EXPORT CGFloat SDImageScaleFactorForKey(NSString * _Nullable key);

/**
 Scale the image with the scale factor for the specify key. If no need to scale, return the original image.
 This works for `UIImage`(UIKit) or `NSImage`(AppKit). And this function also preserve the associated value in `UIImage+Metadata.h`.
 @note This is actually a convenience function, which firstlly call `SDImageScaleFactorForKey` and then call `SDScaledImageForScaleFactor`, kept for backward compatibility.

 @param key The image cache key
 @param image The image
 @return The scaled image
 */
FOUNDATION_EXPORT UIImage * _Nullable SDScaledImageForKey(NSString * _Nullable key, UIImage * _Nullable image);

/**
 Scale the image with the scale factor. If no need to scale, return the original image.
 This works for `UIImage`(UIKit) or `NSImage`(AppKit). And this function also preserve the associated value in `UIImage+Metadata.h`.
 
 @param scale The image scale factor
 @param image The image
 @return The scaled image
 */
FOUNDATION_EXPORT UIImage * _Nullable SDScaledImageForScaleFactor(CGFloat scale, UIImage * _Nullable image);

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
     * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
     * By default, the image is only displayed once completely downloaded.
     */
    SDWebImageProgressiveLoad = 1 << 2,
    
    /**
     * Even if the image is cached, respect the HTTP response cache control, and refresh the image from remote location if needed.
     * The disk caching will be handled by NSURLCache instead of SDWebImage leading to slight performance degradation.
     * This option helps deal with images changing behind the same request URL, e.g. Facebook graph api profile pics.
     * If a cached image is refreshed, the completion block is called once with the cached image and again with the final image.
     *
     * Use this flag only if you can't make your URLs static with embedded cache busting parameter.
     */
    SDWebImageRefreshCached = 1 << 3,
    
    /**
     * In iOS 4+, continue the download of the image if the app goes to background. This is achieved by asking the system for
     * extra time in background to let the request finish. If the background task expires the operation will be cancelled.
     */
    SDWebImageContinueInBackground = 1 << 4,
    
    /**
     * Handles cookies stored in NSHTTPCookieStore by setting
     * NSMutableURLRequest.HTTPShouldHandleCookies = YES;
     */
    SDWebImageHandleCookies = 1 << 5,
    
    /**
     * Enable to allow untrusted SSL certificates.
     * Useful for testing purposes. Use with caution in production.
     */
    SDWebImageAllowInvalidSSLCertificates = 1 << 6,
    
    /**
     * By default, images are loaded in the order in which they were queued. This flag moves them to
     * the front of the queue.
     */
    SDWebImageHighPriority = 1 << 7,
    
    /**
     * By default, placeholder images are loaded while the image is loading. This flag will delay the loading
     * of the placeholder image until after the image has finished loading.
     */
    SDWebImageDelayPlaceholder = 1 << 8,
    
    /**
     * We usually don't apply transform on animated images as most transformers could not manage animated images.
     * Use this flag to transform them anyway.
     */
    SDWebImageTransformAnimatedImage = 1 << 9,
    
    /**
     * By default, image is added to the imageView after download. But in some cases, we want to
     * have the hand before setting the image (apply a filter or add it with cross-fade animation for instance)
     * Use this flag if you want to manually set the image in the completion when success
     */
    SDWebImageAvoidAutoSetImage = 1 << 10,
    
    /**
     * By default, images are decoded respecting their original size. On iOS, this flag will scale down the
     * images to a size compatible with the constrained memory of devices.
     * This flag take no effect if `SDWebImageAvoidDecodeImage` is set. And it will be ignored if `SDWebImageProgressiveLoad` is set.
     */
    SDWebImageScaleDownLargeImages = 1 << 11,
    
    /**
     * By default, we do not query image data when the image is already cached in memory. This mask can force to query image data at the same time. However, this query is asynchronously unless you specify `SDWebImageQueryMemoryDataSync`
     */
    SDWebImageQueryMemoryData = 1 << 12,
    
    /**
     * By default, when you only specify `SDWebImageQueryMemoryData`, we query the memory image data asynchronously. Combined this mask as well to query the memory image data synchronously.
     * @note Query data synchronously is not recommend, unless you want to ensure the image is loaded in the same runloop to avoid flashing during cell reusing.
     */
    SDWebImageQueryMemoryDataSync = 1 << 13,
    
    /**
     * By default, when the memory cache miss, we query the disk cache asynchronously. This mask can force to query disk cache (when memory cache miss) synchronously.
     * @note These 3 query options can be combined together. For the full list about these masks combination, see wiki page.
     * @note Query data synchronously is not recommend, unless you want to ensure the image is loaded in the same runloop to avoid flashing during cell reusing.
     */
    SDWebImageQueryDiskDataSync = 1 << 14,
    
    /**
     * By default, when the cache missed, the image is load from the loader. This flag can prevent this to load from cache only.
     */
    SDWebImageFromCacheOnly = 1 << 15,
    
    /**
     * By default, we query the cache before the image is load from the loader. This flag can prevent this to load from loader only.
     */
    SDWebImageFromLoaderOnly = 1 << 16,
    
    /**
     * By default, when you use `SDWebImageTransition` to do some view transition after the image load finished, this transition is only applied for image download from the network. This mask can force to apply view transition for memory and disk cache as well.
     */
    SDWebImageForceTransition = 1 << 17,
    
    /**
     * By default, we will decode the image in the background during cache query and download from the network. This can help to improve performance because when rendering image on the screen, it need to be firstly decoded. But this happen on the main queue by Core Animation.
     * However, this process may increase the memory usage as well. If you are experiencing a issue due to excessive memory consumption, This flag can prevent decode the image.
     */
    SDWebImageAvoidDecodeImage = 1 << 18,
    
    /**
     * By default, we decode the animated image. This flag can force decode the first frame only and produece the static image.
     */
    SDWebImageDecodeFirstFrameOnly = 1 << 19,
    
    /**
     * By default, for `SDAnimatedImage`, we decode the animated image frame during rendering to reduce memory usage. However, you can specify to preload all frames into memory to reduce CPU usage when the animated image is shared by lots of imageViews.
     * This will actually trigger `preloadAllAnimatedImageFrames` in the background queue(Disk Cache & Download only).
     */
    SDWebImagePreloadAllFrames = 1 << 20
};


#pragma mark - Context Options

/**
 A String to be used as the operation key for view category to store the image load operation. This is used for view instance which supports different image loading process. If nil, will use the class name as operation key. (NSString *)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSetImageOperationKey;

/**
 A SDWebImageManager instance to control the image download and cache process using in UIImageView+WebCache category and likes. If not provided, use the shared manager (SDWebImageManager *)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCustomManager;

/**
 A id<SDImageTransformer> instance which conforms `SDImageTransformer` protocol. It's used for image transform after the image load finished and store the transformed image to cache. If you provide one, it will ignore the `transformer` in manager and use provided one instead. (id<SDImageTransformer>)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextImageTransformer;

/**
 A CGFloat raw value which specify the image scale factor. The number should be greater than or equal to 1.0. If not provide or the number is invalid, we will use the cache key to specify the scale factor. (NSNumber)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextImageScaleFactor;

/**
 A SDImageCacheType raw value which specify the cache type when the image has just been downloaded and will be stored to the cache. Specify `SDImageCacheTypeNone` to disable cache storage; `SDImageCacheTypeDisk` to store in disk cache only; `SDImageCacheTypeMemory` to store in memory only. And `SDImageCacheTypeAll` to store in both memory cache and disk cache.
 If not provide or the value is invalid, we will use `SDImageCacheTypeAll`. (NSNumber)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextStoreCacheType;

/**
 A Class object which the instance is a `UIImage/NSImage` subclass and adopt `SDAnimatedImage` protocol. We will call `initWithData:scale:options:` to create the instance (or `initWithAnimatedCoder:scale:` when using progressive download) . If the instance create failed, fallback to normal `UIImage/NSImage`.
 This can be used to improve animated images rendering performance (especially memory usage on big animated images) with `SDAnimatedImageView` (Class).
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextAnimatedImageClass;

/**
 A id<SDWebImageDownloaderRequestModifier> instance to modify the image download request. It's used for downloader to modify the original request from URL and options. If you provide one, it will ignore the `requestModifier` in downloader and use provided one instead. (id<SDWebImageDownloaderRequestModifier>)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextDownloadRequestModifier;

/**
 A id<SDWebImageCacheKeyFilter> instance to convert an URL into a cache key. It's used when manager need cache key to use image cache. If you provide one, it will ignore the `cacheKeyFilter` in manager and use provided one instead. (id<SDWebImageCacheKeyFilter>)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCacheKeyFilter;

/**
 A id<SDWebImageCacheSerializer> instance to convert the decoded image, the source downloaded data, to the actual data. It's used for manager to store image to the disk cache. If you provide one, it will ignore the `cacheSerializer` in manager and use provided one instead. (id<SDWebImageCacheSerializer>)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCacheSerializer;
