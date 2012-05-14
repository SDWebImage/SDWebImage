/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

@class SDWebImageManager;
@class UIImage;

/**
 * Delegate protocol for SDWebImageManager
 */
@protocol SDWebImageManagerDelegate <NSObject>

@optional

/**
 * Called while an image is downloading with an partial image object representing the currently downloaded portion of the image.
 * This delegate is called only if ImageIO is available and `SDWebImageProgressiveDownload` option has been used.
 *
 * @param imageManager The image manager
 * @param image The retrived image object
 * @param url The image URL used to retrive the image
 * @param info The user info dictionnary
 */
- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info;
- (void)webImageManager:(SDWebImageManager *)imageManager didProgressWithPartialImage:(UIImage *)image forURL:(NSURL *)url;

/**
 * Called when image download is completed successfuly.
 *
 * @param imageManager The image manager
 * @param image The retrived image object
 * @param url The image URL used to retrive the image
 * @param info The user info dictionnary
 */
- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image forURL:(NSURL *)url userInfo:(NSDictionary *)info;
- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image forURL:(NSURL *)url;
- (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image;

/**
 * Called when an error occurred.
 *
 * @param imageManager The image manager
 * @param error The error
 * @param url The image URL used to retrive the image
 * @param info The user info dictionnary
 */
- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error forURL:(NSURL *)url userInfo:(NSDictionary *)info;
- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error forURL:(NSURL *)url;
- (void)webImageManager:(SDWebImageManager *)imageManager didFailWithError:(NSError *)error;

@end
