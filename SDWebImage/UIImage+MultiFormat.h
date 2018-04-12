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
#pragma mark - Decode
/**
 Create and decode a image with the specify image data

 @param data The image data
 @return The created image
 */
+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data;

/**
 Create and decode a image with the specify image data and scale
 
 @param data The image data
 @param scale The image scale factor. Should be greater than or equal to 1.0.
 @return The created image
 */
+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data scale:(CGFloat)scale;

#pragma mark - Encode
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

/**
 Encode the current image to data with the specify image format and compression quality

 @param imageFormat The specify image format
 @param compressionQuality The quality of the resulting image data. Value between 0.0-1.0. Some coders may not support compression quality.
 @return The encoded data. If can't encode, return nil
 */
- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat compressionQuality:(double)compressionQuality;

@end
