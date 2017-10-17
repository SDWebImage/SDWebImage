/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import "SDWebImageWebPCoder.h"
#import "NSImage+WebCache.h"
#import "UIImage+MultiFormat.h"
#import "NSData+ImageContentType.h"
#import <ImageIO/ImageIO.h>
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
#if SD_UIKIT || SD_WATCH
    int loopCount = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    int frameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
#endif
    int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    CGBitmapInfo bitmapInfo;
    if (!(flags & ALPHA_FLAG)) {
        bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
    } else {
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
    
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
#if SD_UIKIT || SD_WATCH
    NSTimeInterval totalDuration = 0;
    int durations[frameCount];
#endif
    
    do {
        @autoreleasepool {
            UIImage *image;
            if (iter.blend_method == WEBP_MUX_BLEND) {
                image = [self sd_blendWebpImageWithCanvas:canvas iterator:iter];
            } else {
                image = [self sd_nonblendWebpImageWithCanvas:canvas iterator:iter];
            }
            
            if (!image) {
                continue;
            }
            
            [images addObject:image];
            
#if SD_MAC
            break;
#else
            
            int duration = iter.duration;
            if (duration <= 10) {
                // WebP standard says 0 duration is used for canvas updating but not showing image, but actually Chrome and other implementations set it to 100ms if duration is lower or equal than 10ms
                // Some animated WebP images also created without duration, we should keep compatibility
                duration = 100;
            }
            totalDuration += duration;
            size_t count = images.count;
            durations[count - 1] = duration;
#endif
        }
        
    } while (WebPDemuxNextFrame(&iter));
    
    WebPDemuxReleaseIterator(&iter);
    WebPDemuxDelete(demuxer);
    CGContextRelease(canvas);
    
    UIImage *finalImage = nil;
#if SD_UIKIT || SD_WATCH
    NSArray<UIImage *> *animatedImages = [self sd_animatedImagesWithImages:images durations:durations totalDuration:totalDuration];
    finalImage = [UIImage animatedImageWithImages:animatedImages duration:totalDuration / 1000.0];
    if (finalImage) {
        finalImage.sd_imageLoopCount = loopCount;
    }
#elif SD_MAC
    finalImage = images.firstObject;
#endif
    return finalImage;
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
    
    int width;
    int height;
    uint8_t *rgba = WebPIDecGetRGB(_idec, NULL, (int *)&width, (int *)&height, NULL);
    
    if (width + height > 0) {
        // Construct a UIImage from the decoded RGBA value array
        CGDataProviderRef provider =
        CGDataProviderCreateWithData(NULL, rgba, 0, NULL);
        CGColorSpaceRef colorSpaceRef = SDCGColorSpaceGetDeviceRGB();
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
        size_t components = 4;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        CGImageRef imageRef = CGImageCreate(width, height, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
        
        CGDataProviderRelease(provider);
        
        if (!imageRef) {
            return nil;
        }
        
        CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, 8, 0, SDCGColorSpaceGetDeviceRGB(), bitmapInfo);
        if (!canvas) {
            CGImageRelease(imageRef);
            return nil;
        }
        
        CGContextDrawImage(canvas, CGRectMake(0, 0, width, height), imageRef);
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

- (nullable UIImage *)sd_blendWebpImageWithCanvas:(CGContextRef)canvas iterator:(WebPIterator)iter {
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
    
    CGContextDrawImage(canvas, imageRect, image.CGImage);
    CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
    
#if SD_UIKIT || SD_WATCH
    image = [UIImage imageWithCGImage:newImageRef];
#elif SD_MAC
    image = [[UIImage alloc] initWithCGImage:newImageRef size:NSZeroSize];
#endif
    
    CGImageRelease(newImageRef);
    
    if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
        CGContextClearRect(canvas, imageRect);
    }
    
    return image;
}

- (nullable UIImage *)sd_nonblendWebpImageWithCanvas:(CGContextRef)canvas iterator:(WebPIterator)iter {
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
    
    CGContextClearRect(canvas, imageRect);
    CGContextDrawImage(canvas, imageRect, image.CGImage);
    CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
    
#if SD_UIKIT || SD_WATCH
    image = [UIImage imageWithCGImage:newImageRef];
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
    CGBitmapInfo bitmapInfo = config.input.has_alpha ? kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast : kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
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
#if SD_UIKIT || SD_WATCH
    if (!image.images) {
#endif
        // for static single webp image
        data = [self sd_encodedWebpDataWithImage:image];
#if SD_UIKIT || SD_WATCH
    } else {
        // for animated webp image
        int durations[image.images.count];
        NSArray<UIImage *> *images = [self sd_imagesFromAnimatedImages:image.images totalDuration:image.duration durations:durations];
        WebPMux *mux = WebPMuxNew();
        if (!mux) {
            return nil;
        }
        for (NSUInteger i = 0; i < images.count; i++) {
            NSData *webpData = [self sd_encodedWebpDataWithImage:images[i]];
            int duration = durations[i];
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
#endif
    
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
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    uint8_t *rgba = (uint8_t *)CFDataGetBytePtr(dataRef);
    
    uint8_t *data = NULL;
    float quality = 100.0;
    size_t size = WebPEncodeRGBA(rgba, (int)width, (int)height, (int)bytesPerRow, quality, &data);
    CFRelease(dataRef);
    rgba = NULL;
    
    if (size) {
        // success
        webpData = [NSData dataWithBytes:data length:size];
    }
    if (data) {
        WebPFree(data);
    }
    
    return webpData;
}

- (NSArray<UIImage *> *)sd_animatedImagesWithImages:(NSArray<UIImage *> *)images durations:(int const * const)durations totalDuration:(NSTimeInterval)totalDuration
{
    // [UIImage animatedImageWithImages:duration:] only use the average duration for per frame
    // divide the total duration to implement per frame duration for animated WebP
    NSUInteger count = images.count;
    if (!count) {
        return nil;
    }
    if (count == 1) {
        return images;
    }
    
    int const gcd = gcdArray(count, durations);
    NSMutableArray<UIImage *> *animatedImages = [NSMutableArray arrayWithCapacity:count];
    [images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        int duration = durations[idx];
        int repeatCount;
        if (gcd) {
            repeatCount = duration / gcd;
        } else {
            repeatCount = 1;
        }
        for (int i = 0; i < repeatCount; ++i) {
            [animatedImages addObject:image];
        }
    }];
    
    return animatedImages;
}

- (NSArray<UIImage *> *)sd_imagesFromAnimatedImages:(NSArray<UIImage *> *)animatedImages totalDuration:(NSTimeInterval)totalDuration durations:(int * const)durations {
    // This is the reversed procedure to sd_animatedImagesWithImages:durations:totalDuration
    // To avoid precision loss, convert from s to ms during this method
    NSUInteger count = animatedImages.count;
    if (!count) {
        return nil;
    }
    if (count == 1) {
        durations[0] = totalDuration * 1000; // s -> ms
    }
    
    int const duration = totalDuration * 1000 / count;
    
    __block NSUInteger index = 0;
    __block int repeatCount = 1;
    __block UIImage *previousImage = animatedImages.firstObject;
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    [animatedImages enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        // ignore first
        if (idx == 0) {
            return;
        }
        if ([image isEqual:previousImage]) {
            repeatCount++;
        } else {
            [images addObject:previousImage];
            durations[index] = duration * repeatCount;
            repeatCount = 1;
            index++;
        }
        previousImage = image;
        // last one
        if (idx == count - 1) {
            [images addObject:previousImage];
            durations[index] = duration * repeatCount;
        }
    }];
    
    return images;
}

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

static int gcdArray(size_t const count, int const * const values) {
    int result = values[0];
    for (size_t i = 1; i < count; ++i) {
        result = gcd(values[i], result);
    }
    return result;
}

static int gcd(int a,int b) {
    int c;
    while (a != 0) {
        c = a;
        a = b % a;
        b = c;
    }
    return b;
}

@end

#endif
