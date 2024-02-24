/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageDefine.h"
#import "SDWebImageManager.h"
#import "SDWebImageTransition.h"
#import "SDWebImageIndicator.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCacheState.h"

/**
 The value specify that the image progress unit count cannot be determined because the progressBlock is not been called.
 */
FOUNDATION_EXPORT const int64_t SDWebImageProgressUnitCountUnknown; /* 1LL */

typedef void(^SDSetImageBlock)(UIImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL);

/**
 Integrates SDWebImage async downloading and caching of remote images with UIView subclass.
 */
@interface UIView (WebCache)

/**
 * Get the current image operation key. Operation key is used to identify the different queries for one view instance (like UIButton).
 * See more about this in `SDWebImageContextSetImageOperationKey`.
 *
 * @note You can use method `UIView+WebCacheOperation` to investigate different queries' operation.
 * @note For the history version compatible, when current UIView has property exactly called `image`, the operation key will use `NSStringFromClass(self.class)`. Include `UIImageView.image/NSImageView.image/NSButton.image` (without `UIButton`)
 * @warning This property should be only used for single state view, like `UIImageView` without highlighted state. For stateful view like `UIBUtton` (one view can have multiple images loading), check their header to call correct API, like `-[UIButton sd_imageOperationKeyForState:]`
 */
@property (nonatomic, strong, readonly, nullable) NSString *sd_latestOperationKey;

#pragma mark - State

/**
 * Get the current image URL.
 * This simply translate to `[self sd_imageLoadStateForKey:self.sd_latestOperationKey].url` from v5.18.0
 *
 * @note Note that because of the limitations of categories this property can get out of sync if you use setImage: directly.
 * @warning This property should be only used for single state view, like `UIImageView` without highlighted state. For stateful view like `UIBUtton` (one view can have multiple images loading), use `sd_imageLoadStateForKey:` instead. See `UIView+WebCacheState.h` for more information.
 */
@property (nonatomic, strong, readonly, nullable) NSURL *sd_imageURL;

/**
 * The current image loading progress associated to the view. The unit count is the received size and excepted size of download.
 * The `totalUnitCount` and `completedUnitCount` will be reset to 0 after a new image loading start (change from current queue). And they will be set to `SDWebImageProgressUnitCountUnknown` if the progressBlock not been called but the image loading success to mark the progress finished (change from main queue).
 * @note You can use Key-Value Observing on the progress, but you should take care that the change to progress is from a background queue during download(the same as progressBlock). If you want to using KVO and update the UI, make sure to dispatch on the main queue. And it's recommend to use some KVO libs like KVOController because it's more safe and easy to use.
 * @note The getter will create a progress instance if the value is nil. But by default, we don't create one. If you need to use Key-Value Observing, you must trigger the getter or set a custom progress instance before the loading start. The default value is nil.
 * @note Note that because of the limitations of categories this property can get out of sync if you update the progress directly.
 * @warning This property should be only used for single state view, like `UIImageView` without highlighted state. For stateful view like `UIBUtton` (one view can have multiple images loading), use `sd_imageLoadStateForKey:` instead. See `UIView+WebCacheState.h` for more information.
 */
@property (nonatomic, strong, null_resettable) NSProgress *sd_imageProgress;

/**
 * Set the imageView `image` with an `url` and optionally a placeholder image.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param context        A context contains different options to perform specify changes or processes, see `SDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 * @param setImageBlock  Block used for custom set image code. If not provide, use the built-in set image code (supports `UIImageView/NSImageView` and `UIButton/NSButton` currently)
 * @param progressBlock  A block called while image is downloading
 *                       @note the progress block is executed on a background queue
 * @param completedBlock A block called when operation has been completed.
 *   This block has no return value and takes the requested UIImage as first parameter and the NSData representation as second parameter.
 *   In case of error the image parameter is nil and the third parameter may contain an NSError.
 *
 *   The forth parameter is an `SDImageCacheType` enum indicating if the image was retrieved from the local cache
 *   or from the memory cache or from the network.
 *
 *   The fifth parameter normally is always YES. However, if you provide SDWebImageAvoidAutoSetImage with SDWebImageProgressiveLoad options to enable progressive downloading and set the image yourself. This block is thus called repeatedly with a partial image. When image is fully downloaded, the
 *   block is called a last time with the full image and the last parameter set to YES.
 *
 *   The last parameter is the original image URL
 *  @return The returned operation for cancelling cache and download operation, typically type is `SDWebImageCombinedOperation`
 */
- (nullable id<SDWebImageOperation>)sd_internalSetImageWithURL:(nullable NSURL *)url
                                              placeholderImage:(nullable UIImage *)placeholder
                                                       options:(SDWebImageOptions)options
                                                       context:(nullable SDWebImageContext *)context
                                                 setImageBlock:(nullable SDSetImageBlock)setImageBlock
                                                      progress:(nullable SDImageLoaderProgressBlock)progressBlock
                                                     completed:(nullable SDInternalCompletionBlock)completedBlock;

/**
 * Cancel the latest image load, using the `sd_latestOperationKey` as operation key
 * This simply translate to `[self sd_cancelImageLoadOperationWithKey:self.sd_latestOperationKey]`
 */
- (void)sd_cancelLatestImageLoad;

/**
 * Cancel the current image load, for single state view.
 * This actually does not cancel current loading, because stateful view can load multiple images at the same time (like UIButton, each state can load different images). Just behave the same as `sd_cancelLatestImageLoad`
 *
 * @warning This method should be only used for single state view, like `UIImageView` without highlighted state. For stateful view like `UIBUtton` (one view can have multiple images loading), use `sd_cancelImageLoadOperationWithKey:` instead. See `UIView+WebCacheOperation.h` for more information.
 * @deprecated Use `sd_cancelLatestImageLoad` instead. Which don't cause overload method misunderstanding (`UIImageView+WebCache` provide the same API as this one, but does not do the same thing). This API will be totally removed in v6.0 due to this.
 */
- (void)sd_cancelCurrentImageLoad API_DEPRECATED_WITH_REPLACEMENT("sd_cancelLatestImageLoad", macos(10.10, 10.10), ios(8.0, 8.0), tvos(9.0, 9.0), watchos(2.0, 2.0));

#if SD_UIKIT || SD_MAC

#pragma mark - Image Transition

/**
 The image transition when image load finished. See `SDWebImageTransition`.
 If you specify nil, do not do transition. Defaults to nil.
 @warning This property should be only used for single state view, like `UIImageView` without highlighted state. For stateful view like `UIBUtton` (one view can have multiple images loading), write your own implementation in `setImageBlock:`, and check current stateful view's state to render the UI.
 */
@property (nonatomic, strong, nullable) SDWebImageTransition *sd_imageTransition;

#pragma mark - Image Indicator

/**
 The image indicator during the image loading. If you do not need indicator, specify nil. Defaults to nil
 The setter will remove the old indicator view and add new indicator view to current view's subview.
 @note Because this is UI related, you should access only from the main queue.
 @warning This property should be only used for single state view, like `UIImageView` without highlighted state. For stateful view like `UIBUtton` (one view can have multiple images loading), write your own implementation in `setImageBlock:`, and check current stateful view's state to render the UI.
 */
@property (nonatomic, strong, nullable) id<SDWebImageIndicator> sd_imageIndicator;

#endif

@end
