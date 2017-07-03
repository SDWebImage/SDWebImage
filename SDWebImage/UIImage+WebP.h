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
 * Get the current WebP image loop count, the default value is 0.
 * For static WebP image, the value is 0.
 * For animated WebP image, 0 means repeat the animation indefinitely.
 * Note that because of the limitations of categories this property can get out of sync
 * if you create another instance with CGImage or other methods.
 * @return WebP image loop count
 */
- (NSInteger)sd_webpLoopCount;

+ (nullable UIImage *)sd_imageWithWebPData:(nullable NSData *)data;

@end

#endif
