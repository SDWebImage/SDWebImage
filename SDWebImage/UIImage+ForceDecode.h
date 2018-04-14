/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

@interface UIImage (ForceDecode)

/**
 A bool value indicating whether the image has already been decoded. This can help to avoid extra force decode.
 */
@property (nonatomic, assign) BOOL sd_isDecoded;

/**
 Decompress (force decode before rendering) the provided image

 @param image The image to be decompressed
 @return The decompressed image
 */
+ (nullable UIImage *)sd_decodedImageWithImage:(nullable UIImage *)image;

/**
 Decompress and scale down the provided image

 @param image The image to be decompressed
 @return The decompressed and scaled down image
 */
+ (nullable UIImage *)sd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image;

/**
 Decompress and scale down the provided image and limit bytes
 
 @param image The image to be decompressed
 @param bytes The limit bytes size. Provide 0 to use the build-in limit.
 @return The decompressed and scaled down image
 */
+ (nullable UIImage *)sd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image limitBytes:(NSUInteger)bytes;

@end
