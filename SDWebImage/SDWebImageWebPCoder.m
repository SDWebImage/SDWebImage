/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import "SDWebImageWebPCoder.h"
#import "SDWebImageCoderHelper.h"
#import "NSImage+WebCache.h"
#import "UIImage+MultiFormat.h"
#if __has_include(<webp/decode.h>) && __has_include(<webp/encode.h>) && __has_include(<webp/demux.h>) && __has_include(<webp/mux.h>)
#import <webp/decode.h>
#import <webp/encode.h>
#import <webp/demux.h>
#import <webp/mux.h>
#else
#import "webp/decode.h"
#import "webp/encode.h"
#import "webp/demux.h"
#import "webp/mux.h"
#endif
#import <Accelerate/Accelerate.h>

@implementation SDWebImageWebPCoder {
    WebPIDecoder *_idec;
}

- (void)dealloc {
    if (_idec) {
        WebPIDelete(_idec);
        _idec = NULL;
    }
}

+ (instancetype)sharedCoder {
    static SDWebImageWebPCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDWebImageWebPCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == SDImageFormatWebP);
}

- (BOOL)canIncrementallyDecodeFromData:(NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == SDImageFormatWebP);
}

- (UIImage *)decodedImageWithData:(NSData *)data {
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
    int loopCount = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    CGBitmapInfo bitmapInfo;
    // `CGBitmapContextCreate` does not support RGB888 on iOS. Where `CGImageCreate` supports.
    if (!(flags & ALPHA_FLAG)) {
        // RGBX8888
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
    } else {
        // RGBA8888
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    }
    CGContextRef canvas = CGBitmapContextCreate(NULL, canvasWidth, canvasHeight, 8, 0, SDCGColorSpaceGetDeviceRGB(), bitmapInfo);
    if (!canvas) {
        WebPDemuxDelete(demuxer);
        return nil;
    }
    
    if (!(flags & ANIMATION_FLAG)) {
        // for static single webp image
        UIImage *staticImage = [self sd_rawWebpImageWithData:webpData];
        if (staticImage) {
            // draw on CGBitmapContext can reduce memory usage
            CGImageRef imageRef = staticImage.CGImage;
            size_t width = CGImageGetWidth(imageRef);
            size_t height = CGImageGetHeight(imageRef);
            CGContextDrawImage(canvas, CGRectMake(0, 0, width, height), imageRef);
            CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
#if SD_UIKIT || SD_WATCH
            staticImage = [[UIImage alloc] initWithCGImage:newImageRef];
#else
            staticImage = [[UIImage alloc] initWithCGImage:newImageRef size:NSZeroSize];
#endif
            CGImageRelease(newImageRef);
        }
        WebPDemuxDelete(demuxer);
        CGContextRelease(canvas);
        staticImage.sd_imageFormat = SDImageFormatWebP;
        return staticImage;
    }
    
    // for animated webp image
    WebPIterator iter;
    if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
        WebPDemuxReleaseIterator(&iter);
        WebPDemuxDelete(demuxer);
        CGContextRelease(canvas);
        return nil;
    }
    
    NSMutableArray<SDWebImageFrame *> *frames = [NSMutableArray array];
    
    do {
        @autoreleasepool {
            UIImage *image = [self sd_drawnWebpImageWithCanvas:canvas iterator:iter];
            if (!image) {
                continue;
            }
            
            int duration = iter.duration;
            if (duration <= 10) {
                // WebP standard says 0 duration is used for canvas updating but not showing image, but actually Chrome and other implementations set it to 100ms if duration is lower or equal than 10ms
                // Some animated WebP images also created without duration, we should keep compatibility
                duration = 100;
            }
            SDWebImageFrame *frame = [SDWebImageFrame frameWithImage:image duration:duration / 1000.f];
            [frames addObject:frame];
        }
        
    } while (WebPDemuxNextFrame(&iter));
    
    WebPDemuxReleaseIterator(&iter);
    WebPDemuxDelete(demuxer);
    CGContextRelease(canvas);
    
    UIImage *animatedImage = [SDWebImageCoderHelper animatedImageWithFrames:frames];
    animatedImage.sd_imageLoopCount = loopCount;
    animatedImage.sd_imageFormat = SDImageFormatWebP;
    
    return animatedImage;
}

- (UIImage *)incrementallyDecodedImageWithData:(NSData *)data finished:(BOOL)finished {
    if (!_idec) {
        // Progressive images need transparent, so always use premultiplied RGBA
        _idec = WebPINewRGB(MODE_rgbA, NULL, 0, 0);
        if (!_idec) {
            return nil;
        }
    }
    
    UIImage *image;
    
    VP8StatusCode status = WebPIUpdate(_idec, data.bytes, data.length);
    if (status != VP8_STATUS_OK && status != VP8_STATUS_SUSPENDED) {
        return nil;
    }
    
    int width = 0;
    int height = 0;
    int last_y = 0;
    int stride = 0;
    uint8_t *rgba = WebPIDecGetRGB(_idec, &last_y, &width, &height, &stride);
    // last_y may be 0, means no enough bitmap data to decode, ignore this
    if (width + height > 0 && last_y > 0 && height >= last_y) {
        // Construct a UIImage from the decoded RGBA value array
        size_t rgbaSize = last_y * stride;
        CGDataProviderRef provider =
        CGDataProviderCreateWithData(NULL, rgba, rgbaSize, NULL);
        CGColorSpaceRef colorSpaceRef = SDCGColorSpaceGetDeviceRGB();
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        size_t components = 4;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        // Why to use last_y for image height is because of libwebp's bug (https://bugs.chromium.org/p/webp/issues/detail?id=362)
        // It will not keep memory barrier safe on x86 architechure (macOS & iPhone simulator) but on ARM architecture (iPhone & iPad & tv & watch) it works great
        // If different threads use WebPIDecGetRGB to grab rgba bitmap, it will contain the previous decoded bitmap data
        // So this will cause our drawed image looks strange(above is the current part but below is the previous part)
        // We only grab the last_y height and draw the last_y heigh instead of total height image
        // Besides fix, this can enhance performance since we do not need to create extra bitmap
        CGImageRef imageRef = CGImageCreate(width, last_y, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
        
        CGDataProviderRelease(provider);
        
        if (!imageRef) {
            return nil;
        }
        
        CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, 8, 0, SDCGColorSpaceGetDeviceRGB(), bitmapInfo);
        if (!canvas) {
            CGImageRelease(imageRef);
            return nil;
        }
        
        // Only draw the last_y image height, keep remains transparent, in Core Graphics coordinate system
        CGContextDrawImage(canvas, CGRectMake(0, height - last_y, width, last_y), imageRef);
        CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
        CGImageRelease(imageRef);
        if (!newImageRef) {
            CGContextRelease(canvas);
            return nil;
        }
        
#if SD_UIKIT || SD_WATCH
        image = [[UIImage alloc] initWithCGImage:newImageRef];
#else
        image = [[UIImage alloc] initWithCGImage:newImageRef size:NSZeroSize];
#endif
        image.sd_imageFormat = SDImageFormatWebP;
        CGImageRelease(newImageRef);
        CGContextRelease(canvas);
    }
    
    if (finished) {
        if (_idec) {
            WebPIDelete(_idec);
            _idec = NULL;
        }
    }
    
    return image;
}

- (UIImage *)decompressedImageWithImage:(UIImage *)image
                                   data:(NSData *__autoreleasing  _Nullable *)data
                                options:(nullable NSDictionary<NSString*, NSObject*>*)optionsDict {
    // WebP do not decompress
    return image;
}

- (nullable UIImage *)sd_drawnWebpImageWithCanvas:(CGContextRef)canvas iterator:(WebPIterator)iter {
    UIImage *image = [self sd_rawWebpImageWithData:iter.fragment];
    if (!image) {
        return nil;
    }
    
    size_t canvasWidth = CGBitmapContextGetWidth(canvas);
    size_t canvasHeight = CGBitmapContextGetHeight(canvas);
    CGSize size = CGSizeMake(canvasWidth, canvasHeight);
    CGFloat tmpX = iter.x_offset;
    CGFloat tmpY = size.height - iter.height - iter.y_offset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
    BOOL shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
    
    // If not blend, cover the target image rect. (firstly clear then draw)
    if (!shouldBlend) {
        CGContextClearRect(canvas, imageRect);
    }
    CGContextDrawImage(canvas, imageRect, image.CGImage);
    CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
    
#if SD_UIKIT || SD_WATCH
    image = [[UIImage alloc] initWithCGImage:newImageRef];
#elif SD_MAC
    image = [[UIImage alloc] initWithCGImage:newImageRef size:NSZeroSize];
#endif
    
    CGImageRelease(newImageRef);
    
    if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
        CGContextClearRect(canvas, imageRect);
    }
    
    return image;
}

- (nullable UIImage *)sd_rawWebpImageWithData:(WebPData)webpData {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    
    if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    
    config.output.colorspace = config.input.has_alpha ? MODE_rgbA : MODE_RGB;
    config.options.use_threads = 1;
    
    // Decode the WebP image data into a RGBA value array
    if (WebPDecode(webpData.bytes, webpData.size, &config) != VP8_STATUS_OK) {
        return nil;
    }
    
    int width = config.input.width;
    int height = config.input.height;
    if (config.options.use_scaling) {
        width = config.options.scaled_width;
        height = config.options.scaled_height;
    }
    
    // Construct a UIImage from the decoded RGBA value array
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config.output.u.RGBA.rgba, config.output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = SDCGColorSpaceGetDeviceRGB();
    CGBitmapInfo bitmapInfo;
    // `CGBitmapContextCreate` does not support RGB888 on iOS. Where `CGImageCreate` supports.
    if (!config.input.has_alpha) {
        // RGB888
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNone;
    } else {
        // RGBA8888
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    }
    size_t components = config.input.has_alpha ? 4 : 3;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    
#if SD_UIKIT || SD_WATCH
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef size:NSZeroSize];
#endif
    CGImageRelease(imageRef);
    
    return image;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return (format == SDImageFormatWebP);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format {
    if (!image) {
        return nil;
    }
    
    NSData *data;
    
    NSArray<SDWebImageFrame *> *frames = [SDWebImageCoderHelper framesFromAnimatedImage:image];
    if (frames.count == 0) {
        // for static single webp image
        data = [self sd_encodedWebpDataWithImage:image];
    } else {
        // for animated webp image
        WebPMux *mux = WebPMuxNew();
        if (!mux) {
            return nil;
        }
        for (size_t i = 0; i < frames.count; i++) {
            SDWebImageFrame *currentFrame = frames[i];
            NSData *webpData = [self sd_encodedWebpDataWithImage:currentFrame.image];
            int duration = currentFrame.duration * 1000;
            WebPMuxFrameInfo frame = { .bitstream.bytes = webpData.bytes,
                .bitstream.size = webpData.length,
                .duration = duration,
                .id = WEBP_CHUNK_ANMF,
                .dispose_method = WEBP_MUX_DISPOSE_BACKGROUND, // each frame will clear canvas
                .blend_method = WEBP_MUX_NO_BLEND
            };
            if (WebPMuxPushFrame(mux, &frame, 0) != WEBP_MUX_OK) {
                WebPMuxDelete(mux);
                return nil;
            }
        }
        
        int loopCount = (int)image.sd_imageLoopCount;
        WebPMuxAnimParams params = { .bgcolor = 0,
            .loop_count = loopCount
        };
        if (WebPMuxSetAnimationParams(mux, &params) != WEBP_MUX_OK) {
            WebPMuxDelete(mux);
            return nil;
        }
        
        WebPData outputData;
        WebPMuxError error = WebPMuxAssemble(mux, &outputData);
        WebPMuxDelete(mux);
        if (error != WEBP_MUX_OK) {
            return nil;
        }
        data = [NSData dataWithBytes:outputData.bytes length:outputData.size];
        WebPDataClear(&outputData);
    }
    
    return data;
}

- (nullable NSData *)sd_encodedWebpDataWithImage:(nullable UIImage *)image {
    if (!image) {
        return nil;
    }
    
    NSData *webpData;
    CGImageRef imageRef = image.CGImage;
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (width == 0 || width > WEBP_MAX_DIMENSION) {
        return nil;
    }
    if (height == 0 || height > WEBP_MAX_DIMENSION) {
        return nil;
    }
    
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    // If we can not get bitmap buffer, early return
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    if (!dataProvider) {
        return nil;
    }
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    if (!dataRef) {
        return nil;
    }
    
    uint8_t *rgba = NULL;
    // We could not assume that input CGImage's color mode is always RGB888/RGBA8888. Convert all other cases to target color mode using vImage
    if (byteOrderNormal && ((alphaInfo == kCGImageAlphaNone) || (alphaInfo == kCGImageAlphaLast))) {
        // If the input CGImage is already RGB888/RGBA8888
        rgba = (uint8_t *)CFDataGetBytePtr(dataRef);
    } else {
        // Convert all other cases to target color mode using vImage
        vImageConverterRef convertor = NULL;
        vImage_Error error = kvImageNoError;
        
        vImage_CGImageFormat srcFormat = {
            .bitsPerComponent = (uint32_t)CGImageGetBitsPerComponent(imageRef),
            .bitsPerPixel = (uint32_t)CGImageGetBitsPerPixel(imageRef),
            .colorSpace = CGImageGetColorSpace(imageRef),
            .bitmapInfo = bitmapInfo
        };
        vImage_CGImageFormat destFormat = {
            .bitsPerComponent = 8,
            .bitsPerPixel = hasAlpha ? 32 : 24,
            .colorSpace = SDCGColorSpaceGetDeviceRGB(),
            .bitmapInfo = hasAlpha ? kCGImageAlphaLast | kCGBitmapByteOrderDefault : kCGImageAlphaNone | kCGBitmapByteOrderDefault // RGB888/RGBA8888 (Non-premultiplied to works for libwebp)
        };
        
        convertor = vImageConverter_CreateWithCGImageFormat(&srcFormat, &destFormat, NULL, kvImageNoFlags, &error);
        if (error != kvImageNoError) {
            CFRelease(dataRef);
            return nil;
        }
        
        vImage_Buffer src = {
            .data = (uint8_t *)CFDataGetBytePtr(dataRef),
            .width = width,
            .height = height,
            .rowBytes = bytesPerRow
        };
        vImage_Buffer dest;
        
        error = vImageBuffer_Init(&dest, height, width, destFormat.bitsPerPixel, kvImageNoFlags);
        if (error != kvImageNoError) {
            CFRelease(dataRef);
            return nil;
        }
        
        // Convert input color mode to RGB888/RGBA8888
        error = vImageConvert_AnyToAny(convertor, &src, &dest, NULL, kvImageNoFlags);
        if (error != kvImageNoError) {
            CFRelease(dataRef);
            return nil;
        }
        
        rgba = dest.data; // Converted buffer
        bytesPerRow = dest.rowBytes; // Converted bytePerRow
        CFRelease(dataRef);
        dataRef = NULL;
    }
    
    uint8_t *data = NULL; // Output WebP data
    float qualityFactor = 100; // WebP quality is 0-100
    // Encode RGB888/RGBA8888 buffer to WebP data
    size_t size;
    if (hasAlpha) {
        size = WebPEncodeRGBA(rgba, (int)width, (int)height, (int)bytesPerRow, qualityFactor, &data);
    } else {
        size = WebPEncodeRGB(rgba, (int)width, (int)height, (int)bytesPerRow, qualityFactor, &data);
    }
    if (dataRef) {
        CFRelease(dataRef); // free non-converted rgba buffer
        dataRef = NULL;
    } else {
        free(rgba); // free converted rgba buffer
        rgba = NULL;
    }
    
    if (size) {
        // success
        webpData = [NSData dataWithBytes:data length:size];
    }
    if (data) {
        WebPFree(data);
    }
    
    return webpData;
}

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

@end

#endif
