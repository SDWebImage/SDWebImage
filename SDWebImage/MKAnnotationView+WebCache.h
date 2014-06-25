//
//  MKAnnotationView+WebCache.h
//  SDWebImage
//
//  Created by Olivier Poitrey on 14/03/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "MapKit/MapKit.h"
#import "SDWebImageManager.h"

/**
 * Integrates SDWebImage async downloading and caching of remote images with MKAnnotationView.
 */
@interface MKAnnotationView (WebCache)

/**
 * Get the current image URL.
 *
 * Note that because of the limitations of categories this property can get out of sync
 * if you use sd_setImage: directly.
 */
- (NSURL *)sd_imageURL;

/**
 * Set the imageView `image` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url The url for the image.
 */
- (void)sd_setImageWithURL:(NSURL *)url;

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url         The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @see sd_setImageWithURL:placeholderImage:options:
 */
- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url         The url for the image.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options     The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 */

- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options;

/**
 * Set the imageView `image` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 *                       The forth parameter is the original image url.
 */
- (void)sd_setImageWithURL:(NSURL *)url completed:(SDWebImageCompletionBlock)completedBlock;

/**
 * Set the imageView `image` with an `url`, placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 *                       The forth parameter is the original image url.
 */
- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletionBlock)completedBlock;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache of from the network.
 *                       The forth parameter is the original image url.
 */
- (void)sd_setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletionBlock)completedBlock;

/**
 * Cancel the current download
 */
- (void)sd_cancelCurrentImageLoad;

@end


@interface MKAnnotationView (WebCacheDeprecated)

- (NSURL *)imageURL __deprecated_msg("Use `sd_imageURL`");

- (void)setImageWithURL:(NSURL *)url __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:`");
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:placeholderImage:`");
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:placeholderImage:options:`");

- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:completed:`");
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:placeholderImage:completed:`");
- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:placeholderImage:options:completed:`");

- (void)cancelCurrentImageLoad __deprecated_msg("Use `sd_cancelCurrentImageLoad`");

@end
