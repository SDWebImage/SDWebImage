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
#import "NSData+ImageContentType.h"

@interface SDWebImageDecoder : NSObject

- (nullable UIImage *)incrementalDecodedImageWithData:(nullable NSData *)data format:(SDImageFormat)format finished:(BOOL)finished;

- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image format:(SDImageFormat)format properties:(nullable NSDictionary *)properties;

- (nullable NSDictionary *)propertiesOfImageData:(nullable NSData *)data;

@end

@interface UIImage (ForceDecode)

+ (nullable UIImage *)decodedImageWithImage:(nullable UIImage *)image;

+ (nullable UIImage *)decodedAndScaledDownImageWithImage:(nullable UIImage *)image;

@end
