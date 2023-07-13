/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

/**
 UIImage category about force decode feature (avoid Image/IO's lazy decoding during rendering behavior).
 */
@interface UIImage (ForceDecode)

/**
 A bool value indicating whether the image has already been decoded. This can help to avoid extra force decode.
 Force decode is used for 2 cases:
 -- 1. for ImageIO created image (via `CGImageCreateWithImageSource` SPI), it's lazy and we trigger the decode before rendering
 -- 2. for non-ImageIO created image (via `CGImageCreate` API), we can ensure it's alignment is suitable to render on screen without copy by CoreAnimation
 @note For coder plugin developer, always use the SDImageCoderHelper's `colorSpaceGetDeviceRGB`/`preferredPixelFormat` to create CGImage.
 @note For more information why force decode, see: https://github.com/path/FastImageCache#byte-alignment
 @note From v5.17.0, the default value is always NO. Use `SDImageForceDecodePolicy` to control complicated policy.
 */
@property (nonatomic, assign) BOOL sd_isDecoded;

/**
 Decode the provided image. This is useful if you want to force decode the image before rendering to improve performance.

 @param image The image to be decoded
 @return The decoded image
 */
+ (nullable UIImage *)sd_decodedImageWithImage:(nullable UIImage *)image;

/**
 Decode and scale down the provided image

 @param image The image to be decoded
 @return The decoded and scaled down image
 */
+ (nullable UIImage *)sd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image;

/**
 Decode and scale down the provided image with limit bytes
 
 @param image The image to be decoded
 @param bytes The limit bytes size. Provide 0 to use the build-in limit.
 @return The decoded and scaled down image
 */
+ (nullable UIImage *)sd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image limitBytes:(NSUInteger)bytes;

@end
