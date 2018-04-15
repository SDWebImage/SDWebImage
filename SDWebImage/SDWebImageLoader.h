/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageDefine.h"
#import "SDWebImageOperation.h"

typedef void(^SDWebImageLoaderProgressBlock)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL);
typedef void(^SDWebImageLoaderCompletedBlock)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished);
typedef void(^SDWebImageLoaderDataCompletedBlock)(NSData * _Nullable data, NSError * _Nullable error, BOOL finished);

@protocol SDWebImageCoder, SDWebImageProgressiveCoder;

/**
 This is the built-in decoding process for image download from network or local file.
 @note If you want to implement your custom loader with `loadImageWithURL:options:context:progress:completed:` API, but also want to keep compatible with SDWebImage's behavior, you'd better use this to produce image.

 @param imageData The image data from the network. Should not be nil
 @param imageURL The image URL from the input. Should not be nil
 @param coder The image coder. You can pass nil to use the default `SDWebImageCodersManager`. See `SDWebImageCoder`
 @param options The options arg from the input
 @param context The context arg from the input
 @return The decoded image for current image data load from the network
 */
FOUNDATION_EXPORT UIImage * _Nullable SDWebImageLoaderDecodeImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, id<SDWebImageCoder> _Nullable coder, SDWebImageOptions options, SDWebImageContext * _Nullable context);

/**
 This is the built-in decoding process for image progressive download from network. It's used when `SDWebImageProgressiveDownload` option is set.
 @note If you want to implement your custom loader with `loadImageWithURL:options:context:progress:completed:` API, but also want to keep compatible with SDWebImage's behavior, you'd better use this to produce image.

 @param imageData The image data from the network so far. Should not be nil
 @param imageURL The image URL from the input. Should not be nil
 @param finished Pass NO to specify the download process has not finished. Pass YES when all image data has finished.
 @param progressiveCoder The image progressive coder. Should not be nil. You should bind the progressive coder for each of loading operation to avoid conflict. See `SDWebImageProgressiveCoder`.
 @param options The options arg from the input
 @param context The context arg from the input
 @return The decoded progressive image for current image data load from the network
 */
FOUNDATION_EXPORT UIImage * _Nullable SDWebImageLoaderDecodeProgressiveImageData(NSData * _Nonnull imageData, NSURL * _Nonnull imageURL, BOOL finished, id<SDWebImageProgressiveCoder> _Nonnull progressiveCoder, SDWebImageOptions options, SDWebImageContext * _Nullable context);

/**
 A `UIImage` instance from `SDWebImageManager` when you specify `SDWebImageRefreshCached` and image cache hit.
 This can be a hint for image loader to load the image from network and refresh the image from remote location if needed. If the cached image is equal to the remote location one. you should call the completion with all nil args. (UIImage)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextLoaderCachedImage;

#pragma mark - SDWebImageLoader

@protocol SDWebImageLoader <NSObject>

- (BOOL)canLoadWithURL:(nullable NSURL *)url;

// We provide two ways to allow a image loader to load the image.
// The first one should return the `UIImage` image instance as well as `NSData` image data. This is suitable for the use case such as image from third-party SDKs, such as image directlly from Photos framework.
// The second one should return just the `NSData` image data, we will use the common image decoding logic to process the correct image instance, so the image loader itself can concentrate on only data retriving. This is suitable for the use case such as load the data from network or local file.
// Your image loader **MUST** implement at least one of those protocol, or an assert will occur. We will firstlly ask for `loadImageWithURL:options:progress:completed:context:` if you implement it. If this one return nil, we will continue to ask for `loadImageDataWithURL:options:progress:completed:context:` if you implement it.
// @note It's your responsibility to load the image in the desired global queue(to avoid block main queue). We do not dispatch these method call in a global queue but just from the call queue (For `SDWebImageManager`, it typically call from the main queue).

@optional
/**
 Load the image and image data with the given URL and return the image data. You're responsible for producing the image instance.

 @param url The URL represent the image. Note this may not be a HTTP URL
 @param options A mask to specify options to use for this request
 @param context A context contains different options to perform specify changes or processes, see `SDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 @param progressBlock A block called while image is downloading
 *                    @note the progress block is executed on a background queue
 @param completedBlock A block called when operation has been completed.
 @return An operation which allow the user to cancel the current request.
 */
- (nullable id<SDWebImageOperation>)loadImageWithURL:(nullable NSURL *)url
                                             options:(SDWebImageOptions)options
                                             context:(nullable SDWebImageContext *)context
                                            progress:(nullable SDWebImageLoaderProgressBlock)progressBlock
                                           completed:(nullable SDWebImageLoaderCompletedBlock)completedBlock;

/**
 Load the image with the given URL and return the image data. We will automatically handler the image decoding stuff for you.

 @param url The URL represent the image. Note this may not be a HTTP URL
 @param options A mask to specify options to use for this request
 @param context A context contains different options to perform specify changes or processes, see `SDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 @param progressBlock A block called while image is downloading
 *                    @note the progress block is executed on a background queue
 @param completedBlock A block called when operation has been completed.
 @return An operation which allow the user to cancel the current request.
 */
- (nullable id<SDWebImageOperation>)loadImageDataWithURL:(nullable NSURL *)url
                                                 options:(SDWebImageOptions)options
                                                 context:(nullable SDWebImageContext *)context
                                                progress:(nullable SDWebImageLoaderProgressBlock)progressBlock
                                               completed:(nullable SDWebImageLoaderDataCompletedBlock)completedBlock;

@end
