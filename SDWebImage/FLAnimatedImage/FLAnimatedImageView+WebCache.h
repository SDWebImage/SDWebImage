/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_UIKIT

#if __has_include(<FLAnimatedImage/FLAnimatedImage.h>)
#import <FLAnimatedImage/FLAnimatedImage.h>
#else
#import "FLAnimatedImage.h"
#endif

#import "SDWebImageManager.h"

/**
 *  FLAnimatedImage is not a subclass of UIImage, so it's not possible to store it into the memory cache currently. However, for performance issue and cell reuse on FLAnimatedImageView, we use associate object to bind a FLAnimatedImage into UIImage when an animated GIF image load. For most cases, you don't need to touch this.
 */
@interface UIImage (FLAnimatedImage)

/**
 *  The FLAnimatedImage associated to the UIImage instance when an animated GIF image load.
 *  For most cases this is read-only and you should avoid manually setting this value. Util some cases like using placeholder with a `FLAnimatedImage`.
 */
@property (nonatomic, strong, nullable) FLAnimatedImage *sd_FLAnimatedImage;

@end

typedef NS_ENUM(NSUInteger, FLAnimatedImageViewSetImagePolicy) {
    FLAnimatedImageViewSetImagePolicyStandard, // The setImageBlock & completionBlock is always run on the same runloop. When the image or image data can determinate as a GIF image, create `FLAnimatedImage` instance on the main queue and then set it to `animatedImage` property. This may block main queue for large GIF.
    FLAnimatedImageViewSetImagePolicyFast // The completionBlock may run on the next runloop after setImageBlock. When the image or image data can determinate as a GIF image, firstlly use static poster image to let it render, then create `FLAnimatedImage` instance on the global queue, and finally set it to `animatedImage` property on the main queue. This may be helpful for large GIF.
};


/**
 *  A category for the FLAnimatedImage imageView class that hooks it to the SDWebImage system.
 *  Very similar to the base class category (UIImageView (WebCache))
 */
@interface FLAnimatedImageView (WebCache)

/**
 * Optimal frame cache size of FLAnimatedImage during initializer. (1.0.11 version later)
 * This value will help you set `optimalFrameCacheSize` arg of FLAnimatedImage initializer after image load.
 * Defaults to 0.
 */
@property (nonatomic, assign) NSUInteger sd_optimalFrameCacheSize;

/**
 * Predrawing control of FLAnimatedImage during initializer. (1.0.11 version later)
 * This value will help you set `predrawingEnabled` arg of FLAnimatedImage initializer after image load.
 * Defaults to YES.
 */
@property (nonatomic, assign) BOOL sd_predrawingEnabled;

/**
 * The advanced control for setImage process and rendering for FLAnimatedImageView after image loading. This may be useful for GIF render performance.
 * See `FLAnimatedImageViewSetImagePolicy` description above for different behavior and choose the most proper one for your use case.
 * Defaults to `FLAnimatedImageViewSetImagePolicyStandard`.
 */
@property (nonatomic, assign) FLAnimatedImageViewSetImagePolicy sd_setImagePolicy;

/**
 * Load the image at the given url (either from cache or download) and load it in this imageView. It works with both static and dynamic images
 * The download is asynchronous and cached.
 *
 * @param url The url for the image.
 */
- (void)sd_setImageWithURL:(nullable NSURL *)url NS_REFINED_FOR_SWIFT;

/**
 * Load the image at the given url (either from cache or download) and load it in this imageView. It works with both static and dynamic images
 * The download is asynchronous and cached.
 * Uses a placeholder until the request finishes.
 *
 * @param url         The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 */
- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder NS_REFINED_FOR_SWIFT;

/**
 * Load the image at the given url (either from cache or download) and load it in this imageView. It works with both static and dynamic images
 * The download is asynchronous and cached.
 * Uses a placeholder until the request finishes.
 *
 *  @param url         The url for the image.
 *  @param placeholder The image to be set initially, until the image request finishes.
 *  @param options     The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 */
- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options NS_REFINED_FOR_SWIFT;

/**
 * Load the image at the given url (either from cache or download) and load it in this imageView. It works with both static and dynamic images
 * The download is asynchronous and cached.
 *
 *  @param url            The url for the image.
 *  @param completedBlock A block called when operation has been completed. This block has no return value
 *                        and takes the requested UIImage as first parameter. In case of error the image parameter
 *                        is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                        indicating if the image was retrieved from the local cache or from the network.
 *                        The fourth parameter is the original image url.
 */
- (void)sd_setImageWithURL:(nullable NSURL *)url
                 completed:(nullable SDExternalCompletionBlock)completedBlock;

/**
 * Load the image at the given url (either from cache or download) and load it in this imageView. It works with both static and dynamic images
 * The download is asynchronous and cached.
 * Uses a placeholder until the request finishes.
 *
 *  @param url            The url for the image.
 *  @param placeholder    The image to be set initially, until the image request finishes.
 *  @param completedBlock A block called when operation has been completed. This block has no return value
 *                        and takes the requested UIImage as first parameter. In case of error the image parameter
 *                        is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                        indicating if the image was retrieved from the local cache or from the network.
 *                        The fourth parameter is the original image url.
 */
- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                 completed:(nullable SDExternalCompletionBlock)completedBlock NS_REFINED_FOR_SWIFT;

/**
 * Load the image at the given url (either from cache or download) and load it in this imageView. It works with both static and dynamic images
 * The download is asynchronous and cached.
 * Uses a placeholder until the request finishes.
 *
 *  @param url            The url for the image.
 *  @param placeholder    The image to be set initially, until the image request finishes.
 *  @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 *  @param completedBlock A block called when operation has been completed. This block has no return value
 *                        and takes the requested UIImage as first parameter. In case of error the image parameter
 *                        is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                        indicating if the image was retrieved from the local cache or from the network.
 *                        The fourth parameter is the original image url.
 */
- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                 completed:(nullable SDExternalCompletionBlock)completedBlock;

/**
 * Load the image at the given url (either from cache or download) and load it in this imageView. It works with both static and dynamic images
 * The download is asynchronous and cached.
 * Uses a placeholder until the request finishes.
 *
 *  @param url            The url for the image.
 *  @param placeholder    The image to be set initially, until the image request finishes.
 *  @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 *  @param progressBlock  A block called while image is downloading
 *                        @note the progress block is executed on a background queue
 *  @param completedBlock A block called when operation has been completed. This block has no return value
 *                        and takes the requested UIImage as first parameter. In case of error the image parameter
 *                        is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                        indicating if the image was retrieved from the local cache or from the network.
 *                        The fourth parameter is the original image url.
 */
- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                  progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock;

@end

#endif
