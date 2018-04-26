/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+MultiFormat.h"
#import "SDWebImageCodersManager.h"

@implementation UIImage (MultiFormat)

+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data {
    return [self sd_imageWithData:data scale:1];
}

+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data scale:(CGFloat)scale {
    if (!data) {
        return nil;
    }
    if (scale < 1) {
        scale = 1;
    }
    SDImageCoderOptions *options = @{SDImageCoderDecodeScaleFactor : @(scale)};
    return [[SDWebImageCodersManager sharedManager] decodedImageWithData:data options:options];
}

- (nullable NSData *)sd_imageData {
    return [self sd_imageDataAsFormat:SDImageFormatUndefined];
}

- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat {
    return [self sd_imageDataAsFormat:imageFormat compressionQuality:1];
}

- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat compressionQuality:(double)compressionQuality {
    SDImageCoderOptions *options = @{SDImageCoderEncodeCompressionQuality : @(compressionQuality)};
    return [[SDWebImageCodersManager sharedManager] encodedDataWithImage:self format:imageFormat options:options];
}

@end
