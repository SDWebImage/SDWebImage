/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import "SDWebImageCompat.h"

@interface UIImage (WebP)

/**
 Create a image from the WebP data.
 This may create animated image if the data is Animated WebP.

 @param data The WebP data
 @return The created image
 */
+ (nullable UIImage *)sd_imageWithWebPData:(nullable NSData *)data;

/**
 Create a image from the WebP data.
 
 @param data The WebP data
 @param firstFrameOnly Even if the image data is Animated WebP format, decode the first frame only
 @return The created image
 */
+ (nullable UIImage *)sd_imageWithWebPData:(nullable NSData *)data firstFrameOnly:(BOOL)firstFrameOnly;

@end

#endif
