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
#import <webp/demux.h>
#import <webp/mux_types.h>

// Callback for CGDataProviderRelease
static void FreeImageData(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation UIImage (WebP)

+ (UIImage *)sd_imageWithWebPData:(NSData *)data {
    
    UIImage *image = [UIImage sd_animatedWebPImageWithWebPData:data];
    if (image) {
        return image;
    } else {
        return [UIImage sd_webpImageWithWithWebPData:data];
    }
    
}

+ (UIImage *)sd_animatedWebPImageWithWebPData:(NSData *)data {
    UIImage *result = nil;
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = (const uint8_t *)[data bytes];
    webpData.size = [data length];
    WebPDemuxer* demux = WebPDemux(&webpData);
    uint32_t flags = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS);
    
    if (flags & ANIMATION_FLAG) {
        WebPIterator iter;
        if (WebPDemuxGetFrame(demux, 1, &iter)) {
            
            WebPDecoderConfig config;
            WebPInitDecoderConfig(&config);
            
            int width = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
            int height = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
            
            config.input.height = height;
            config.input.width = width;
            config.input.has_alpha = iter.has_alpha;
            config.input.has_animation = 1;
            config.options.no_fancy_upsampling = 1;
            config.options.bypass_filtering = 1;
            config.options.use_threads = 1;
            config.output.colorspace = MODE_RGBA;
            
            CGFloat frameDuration = iter.duration;
            NSMutableArray *images = [NSMutableArray array];
            do {
                WebPData frame = iter.fragment;
                
                VP8StatusCode status = WebPDecode(frame.bytes, frame.size, &config);
                if (status != VP8_STATUS_OK) {
                    NSLog(@"Error decoding frame");
                }
                
                uint8_t *data = WebPDecodeRGBA(frame.bytes, frame.size, &width, &height);
                CGDataProviderRef provider = CGDataProviderCreateWithData(&config, data, config.options.scaled_width  * config.options.scaled_height * 4, NULL);
                
                CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
                CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
                CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
                
                CGImageRef imageRef = CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, YES, renderingIntent);
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                if (image) {
                    [images addObject:image];
                }
                CGImageRelease(imageRef);
                CGColorSpaceRelease(colorSpaceRef);
                CGDataProviderRelease(provider);
                
            } while (WebPDemuxNextFrame(&iter));
            WebPDemuxReleaseIterator(&iter);
            NSTimeInterval duration = [images count] * frameDuration / 1000;
            result = [UIImage animatedImageWithImages:images duration:duration];
        }
    }
    WebPDemuxDelete(demux);
    
    return result;
}

+ (UIImage *)sd_webpImageWithWithWebPData:(NSData *)data {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }

    if (WebPGetFeatures(data.bytes, data.length, &config.input) != VP8_STATUS_OK) {
        return nil;
    }

    config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
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
    CGBitmapInfo bitmapInfo = config.input.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : 0;
    size_t components = config.input.has_alpha ? 4 : 3;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);

    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);

    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
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
