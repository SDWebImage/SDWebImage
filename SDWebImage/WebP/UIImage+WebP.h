/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import "SDWebImageCompat.h"

// This category is just use as a convenience method. For more detail control, use methods in `UIImage+MultiFormat.h` or directlly use `SDImageCoder`
@interface UIImage (WebP)

/**
 Create a image from the WebP data.
 This will create animated image if the data is Animated WebP. And will create a static image is the data is Static WebP.

 @param data The WebP data
 @return The created image
 */
+ (nullable UIImage *)sd_imageWithWebPData:(nullable NSData *)data;

@end

#endif
