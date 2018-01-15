/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "NSData+ImageContentType.h"

@interface UIImage (MultiFormat)

/**
 Create and decode a image with the specify image data

 @param data The image data
 @return The created image
 */
+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data;

/**
 Encode the current image to the data, the image format is unspecified

 @return The encoded data. If can't encode, return nil
 */
- (nullable NSData *)sd_imageData;

/**
 Encode the current image to data with the specify image format

 @param imageFormat The specify image format
 @return The encoded data. If can't encode, return nil
 */
- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat;

@end
