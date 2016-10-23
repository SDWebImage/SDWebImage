/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "NSData+ImageContentType.h"
#import <ImageIO/ImageIO.h>

@interface UIImage (MultiFormat)

+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data;
- (nullable NSData *)sd_imageData;
- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat;
#if SD_UIKIT || SD_WATCH
+ (UIImageOrientation)sd_imageOrientationFromCGImageSource:(nonnull CGImageSourceRef)imageSource;
#endif
@end
