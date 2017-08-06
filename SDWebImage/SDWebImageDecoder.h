/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) james <https://github.com/mystcolor>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SDWebImageDecoderType) {
    SDWebImageDecoderTypeAuto = 0, // default, will check image format by sd_imageFormatForImageData and decode only the recognized format
    SDWebImageDecoderTypeImageIO, // use ImageIO to decode image format that ImageIO support
    SDWebImageDecoderTypeWebP // use libwebp to decode WebP format
};

@interface SDWebImageDecoder : NSObject

- (instancetype)initWithType:(SDWebImageDecoderType)type;

- (nullable UIImage *)incrementalDecodedImageWithUpdateData:(nullable NSData *)updateData finished:(BOOL)finished;

@end

@interface UIImage (ForceDecode)

+ (nullable UIImage *)decodedImageWithImage:(nullable UIImage *)image;

+ (nullable UIImage *)decodedAndScaledDownImageWithImage:(nullable UIImage *)image;

@end

NS_ASSUME_NONNULL_END
