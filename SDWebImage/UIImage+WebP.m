//
//  UIImage+WebP.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#ifdef SD_WEBP
#import "UIImage+WebP.h"

#if !COCOAPODS
#import "webp/decode.h"
#else
#import "webp/decode.h"
#endif

// Callback for CGDataProviderRelease
static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

@implementation UIImage (WebP);

+ (UIImage *)sd_imageWithWebPData:(NSData *)data {
    return [self sd_imageWithWebPData:data scale:1.0];
}

+ (UIImage *)sd_imageWithWebPData:(NSData *)data scale:(CGFloat)scale {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }

    if (WebPGetFeatures(data.bytes, data.length, &config.input) != VP8_STATUS_OK) {
        return nil;
    }

#if kCGBitmapByteOrder32Host == kCGBitmapByteOrder32Little
    config.output.colorspace = config.input.has_alpha ? MODE_bgrA : MODE_RGB;
#else
    config.output.colorspace = config.input.has_alpha ? MODE_Argb : MODE_RGB;
#endif

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

#if kCGBitmapByteOrder32Host == kCGBitmapByteOrder32Little
    const CGBitmapInfo bitmapInfo = config.input.has_alpha ? kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst : kCGBitmapByteOrderDefault | kCGImageAlphaNone;
#else
    const CGBitmapInfo bitmapInfo = config.input.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedFirst : kCGBitmapByteOrderDefault | kCGImageAlphaNone;
#endif

    const size_t components = config.input.has_alpha ? 4 : 3;

    // Construct a UIImage from the decoded RGBA value array.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, config.output.u.RGBA.stride, colorSpaceRef, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);

    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);

    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);

    return image;
}

@end

#if !COCOAPODS
// Functions to resolve some undefined symbols when using WebP and force_load flag
void WebPInitPremultiplyNEON(void) {}
void WebPInitUpsamplersNEON(void) {}
void VP8DspInitNEON(void) {}
#endif

#endif
