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
#import "webp/mux_types.h"
#import "webp/demux.h"
#else
#import "libwebp/webp/decode.h"
#import "libwebp/webpc/mux_types.h"
#import "libwebp/webp/demux.h"
#endif

// Callback for CGDataProviderRelease
static void FreeImageData(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation UIImage (WebP)

+ (UIImage *)sd_imageWithWebPData:(NSData *)data {
    if (!data) {
        return nil;
    }
    
    WebPData webpData;
    WebPDataInit(&webpData);
    webpData.bytes = data.bytes;
    webpData.size = data.length;
    WebPDemuxer *demuxer = WebPDemux(&webpData);
    if (!demuxer) {
        return nil;
    }
    
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    if (!(flags & ANIMATION_FLAG)) {
        // for static single webp image
        return [self sd_rawWepImageWithData:webpData];
    }
    
    WebPIterator iter;
    if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
        return nil;
    }
    
    NSMutableArray *images = [NSMutableArray array];
    NSTimeInterval duration = 0;
    
    do {
        UIImage *image;
        if (iter.blend_method == WEBP_MUX_BLEND) {
            image = [self sd_blendWebpImageWithOriginImage:[images lastObject] iterator:iter];
        } else {
            image = [self sd_rawWepImageWithData:iter.fragment];
        }
        
        if (!image) {
            continue;
        }
        
        [images addObject:image];
        duration += iter.duration / 1000.0f;
        
    } while (WebPDemuxNextFrame(&iter));
    
    UIImage *animateImage = [UIImage animatedImageWithImages:images duration:duration];
    return animateImage;
}


+ (UIImage *)sd_blendWebpImageWithOriginImage:(UIImage *)originImage iterator:(WebPIterator)iter
{
    if (!originImage) {
        return nil;
    }
    
    CGSize size = originImage.size;
    CGFloat tmpX = iter.x_offset;
    CGFloat tmpY = size.height - iter.height - iter.y_offset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
    
    UIImage *image = [self sd_rawWepImageWithData:iter.fragment];
    if (!image) {
        return nil;
    }
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    uint32_t bitmapInfo = iter.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : 0;
    CGContextRef blendCanvas = CGBitmapContextCreate(NULL, size.width, size.height, 8, 0, colorSpaceRef, bitmapInfo);
    CGContextDrawImage(blendCanvas, CGRectMake(0, 0, size.width, size.height), originImage.CGImage);
    CGContextDrawImage(blendCanvas, imageRect, image.CGImage);
    CGImageRef newImageRef = CGBitmapContextCreateImage(blendCanvas);
    
    image = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    CGContextRelease(blendCanvas);
    CGColorSpaceRelease(colorSpaceRef);
    
    return image;
}

+ (UIImage *)sd_rawWepImageWithData:(WebPData)webpData
{
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }

    if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
        return nil;
    }

    config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
    config.options.use_threads = 1;

    // Decode the WebP image data into a RGBA value array.
    if (WebPDecode(webpData.bytes, webpData.size, &config) != VP8_STATUS_OK) {
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
