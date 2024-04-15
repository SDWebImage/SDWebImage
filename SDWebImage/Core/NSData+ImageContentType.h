/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

/**
 You can use switch case like normal enum. It's also recommended to add a default case. You should not assume anything about the raw value.
 For custom coder plugin, it can also extern the enum for supported format. See `SDImageCoder` for more detailed information.
 */
typedef NSInteger SDImageFormat NS_TYPED_EXTENSIBLE_ENUM;
extern const SDImageFormat SDImageFormatUndefined;
extern const SDImageFormat SDImageFormatJPEG;
extern const SDImageFormat SDImageFormatPNG;
extern const SDImageFormat SDImageFormatGIF;
extern const SDImageFormat SDImageFormatTIFF;
extern const SDImageFormat SDImageFormatWebP;
extern const SDImageFormat SDImageFormatHEIC;
extern const SDImageFormat SDImageFormatHEIF;
extern const SDImageFormat SDImageFormatPDF;
extern const SDImageFormat SDImageFormatSVG;
extern const SDImageFormat SDImageFormatBMP;
extern const SDImageFormat SDImageFormatRAW;

/**
 NSData category about the image content type and UTI.
 */
@interface NSData (ImageContentType)

/**
 *  Return image format
 *
 *  @param data the input image data
 *
 *  @return the image format as `SDImageFormat` (enum)
 */
+ (SDImageFormat)sd_imageFormatForImageData:(nullable NSData *)data;

/**
 *  Convert SDImageFormat to UTType
 *
 *  @param format Format as SDImageFormat
 *  @return The UTType as CFStringRef
 *  @note For unknown format, `kSDUTTypeImage` abstract type will return
 */
+ (nonnull CFStringRef)sd_UTTypeFromImageFormat:(SDImageFormat)format CF_RETURNS_NOT_RETAINED NS_SWIFT_NAME(sd_UTType(from:));

/**
 *  Convert UTType to SDImageFormat
 *
 *  @param uttype The UTType as CFStringRef
 *  @return The Format as SDImageFormat
 *  @note For unknown type, `SDImageFormatUndefined` will return
 */
+ (SDImageFormat)sd_imageFormatFromUTType:(nonnull CFStringRef)uttype;

@end
