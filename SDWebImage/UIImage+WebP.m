//
//  UIImage+WebP.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#ifdef SD_WEBP
#import "UIImage+WebP.h"
#import "webp/decode.h"

// Callback for CGDataProviderRelease
static void FreeImageData(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation UIImage (WebP)

+ (UIImage *)sd_imageWithWebPData:(NSData *)data {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }

    config.output.colorspace = MODE_rgbA;
    config.options.use_threads = 1;

    // Decode the WebP image data into a RGBA value array.
    if (WebPDecode(data.bytes, data.length, &config) != VP8_STATUS_OK) {
        return nil;
    }

    int width = config.input.width;
    int height = config.input.height;
    if (config.options.use_scaling) {
        width = config.options.scaled_width;
        height = config.options.scaled_height;
    }

    // Construct a UIImage from the decoded RGBA value array.
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);

    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);

    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);

    return image;
}

@end

// Functions to resolve some undefined symbols when using WebP and force_load flag
void WebPInitPremultiplyNEON(void) {}
void WebPInitUpsamplersNEON(void) {}
void VP8DspInitNEON(void) {}
#endif
