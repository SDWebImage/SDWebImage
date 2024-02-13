/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSData+ImageContentType.h"
#if SD_MAC
#import <CoreServices/CoreServices.h>
#else
#import <MobileCoreServices/MobileCoreServices.h>
#endif
#import "SDImageIOAnimatedCoderInternal.h"

#define kSVGTagEnd @"</svg>"

@implementation NSData (ImageContentType)

+ (SDImageFormat)sd_imageFormatForImageData:(nullable NSData *)data {
    if (!data) {
        return SDImageFormatUndefined;
    }
    
    // File signatures table: http://www.garykessler.net/library/file_sigs.html
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return SDImageFormatJPEG;
        case 0x89:
            return SDImageFormatPNG;
        case 0x47:
            return SDImageFormatGIF;
        case 0x49:
        case 0x4D:
            return SDImageFormatTIFF;
        case 0x42:
            return SDImageFormatBMP;
        case 0x52: {
            if (data.length >= 12) {
                //RIFF....WEBP
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return SDImageFormatWebP;
                }
            }
            break;
        }
        case 0x00: {
            if (data.length >= 12) {
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"ftypheic"]
                    || [testString isEqualToString:@"ftypheix"]
                    || [testString isEqualToString:@"ftyphevc"]
                    || [testString isEqualToString:@"ftyphevx"]) {
                    return SDImageFormatHEIC;
                }
                //....ftypmif1 ....ftypmsf1
                if ([testString isEqualToString:@"ftypmif1"] || [testString isEqualToString:@"ftypmsf1"]) {
                    return SDImageFormatHEIF;
                }
            }
            break;
        }
        case 0x25: {
            if (data.length >= 4) {
                //%PDF
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(1, 3)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"PDF"]) {
                    return SDImageFormatPDF;
                }
            }
            break;
        }
        case 0x3C: {
            // Check end with SVG tag
            if ([data rangeOfData:[kSVGTagEnd dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range: NSMakeRange(data.length - MIN(100, data.length), MIN(100, data.length))].location != NSNotFound) {
                return SDImageFormatSVG;
            }
            break;
        }
    }
    return SDImageFormatUndefined;
}

+ (nonnull CFStringRef)sd_UTTypeFromImageFormat:(SDImageFormat)format {
    CFStringRef UTType;
    switch (format) {
        case SDImageFormatJPEG:
            UTType = kSDUTTypeJPEG;
            break;
        case SDImageFormatPNG:
            UTType = kSDUTTypePNG;
            break;
        case SDImageFormatGIF:
            UTType = kSDUTTypeGIF;
            break;
        case SDImageFormatTIFF:
            UTType = kSDUTTypeTIFF;
            break;
        case SDImageFormatWebP:
            UTType = kSDUTTypeWebP;
            break;
        case SDImageFormatHEIC:
            UTType = kSDUTTypeHEIC;
            break;
        case SDImageFormatHEIF:
            UTType = kSDUTTypeHEIF;
            break;
        case SDImageFormatPDF:
            UTType = kSDUTTypePDF;
            break;
        case SDImageFormatSVG:
            UTType = kSDUTTypeSVG;
            break;
        case SDImageFormatBMP:
            UTType = kSDUTTypeBMP;
            break;
        case SDImageFormatRAW:
            UTType = kSDUTTypeRAW;
            break;
        default:
            // default is kUTTypeImage abstract type
            UTType = kSDUTTypeImage;
            break;
    }
    return UTType;
}

+ (SDImageFormat)sd_imageFormatFromUTType:(CFStringRef)uttype {
    if (!uttype) {
        return SDImageFormatUndefined;
    }
    SDImageFormat imageFormat;
    if (CFStringCompare(uttype, kSDUTTypeJPEG, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatJPEG;
    } else if (CFStringCompare(uttype, kSDUTTypePNG, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatPNG;
    } else if (CFStringCompare(uttype, kSDUTTypeGIF, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatGIF;
    } else if (CFStringCompare(uttype, kSDUTTypeTIFF, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatTIFF;
    } else if (CFStringCompare(uttype, kSDUTTypeWebP, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatWebP;
    } else if (CFStringCompare(uttype, kSDUTTypeHEIC, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatHEIC;
    } else if (CFStringCompare(uttype, kSDUTTypeHEIF, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatHEIF;
    } else if (CFStringCompare(uttype, kSDUTTypePDF, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatPDF;
    } else if (CFStringCompare(uttype, kSDUTTypeSVG, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatSVG;
    } else if (CFStringCompare(uttype, kSDUTTypeBMP, 0) == kCFCompareEqualTo) {
        imageFormat = SDImageFormatBMP;
    } else if (UTTypeConformsTo(uttype, kSDUTTypeRAW)) {
        imageFormat = SDImageFormatRAW;
    } else {
        imageFormat = SDImageFormatUndefined;
    }
    return imageFormat;
}

@end
