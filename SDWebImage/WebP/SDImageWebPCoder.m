/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import "SDImageWebPCoder.h"
#import "SDImageCoderHelper.h"
#import "NSImage+Compatibility.h"
#import "UIImage+Metadata.h"
#import "UIImage+ForceDecode.h"
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

@interface SDWebPCoderFrame : NSObject

@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSTimeInterval duration; // Frame duration in seconds
@property (nonatomic, assign) NSUInteger width; // Frame width
@property (nonatomic, assign) NSUInteger height; // Frame height
@property (nonatomic, assign) NSUInteger offsetX; // Frame origin.x in canvas (left-bottom based)
@property (nonatomic, assign) NSUInteger offsetY; // Frame origin.y in canvas (left-bottom based)
@property (nonatomic, assign) BOOL hasAlpha; // Whether frame contains alpha
@property (nonatomic, assign) BOOL isFullSize; // Whether frame size is equal to canvas size
@property (nonatomic, assign) WebPMuxAnimBlend blend; // Frame dispose method
@property (nonatomic, assign) WebPMuxAnimDispose dispose; // Frame blend operation
@property (nonatomic, assign) NSUInteger blendFromIndex; // The nearest previous frame index which blend mode is WEBP_MUX_BLEND

@end

@implementation SDWebPCoderFrame
@end

@implementation SDImageWebPCoder {
    WebPIDecoder *_idec;
    WebPDemuxer *_demux;
    NSData *_imageData;
    CGFloat _scale;
    NSUInteger _loopCount;
    NSUInteger _frameCount;
    NSArray<SDWebPCoderFrame *> *_frames;
    CGContextRef _canvas;
    BOOL _hasAnimation;
    BOOL _hasAlpha;
    BOOL _finished;
    CGFloat _canvasWidth;
    CGFloat _canvasHeight;
    dispatch_semaphore_t _lock;
    NSUInteger _currentBlendIndex;
}

- (void)dealloc {
    if (_idec) {
        WebPIDelete(_idec);
        _idec = NULL;
    }
    if (_demux) {
        WebPDemuxDelete(_demux);
        _demux = NULL;
    }
    if (_canvas) {
        CGContextRelease(_canvas);
        _canvas = NULL;
    }
}

+ (instancetype)sharedCoder {
    static SDImageWebPCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageWebPCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == SDImageFormatWebP);
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == SDImageFormatWebP);
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
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
    BOOL hasAnimation = flags & ANIMATION_FLAG;
    BOOL decodeFirstFrame = [options[SDImageCoderDecodeFirstFrameOnly] boolValue];
    CGFloat scale = 1;
    NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
    if (scaleFactor != nil) {
        scale = [scaleFactor doubleValue];
        if (scale < 1) {
            scale = 1;
        }
    }
    if (!hasAnimation) {
        // for static single webp image
        CGImageRef imageRef = [self sd_createWebpImageWithData:webpData];
        if (!imageRef) {
            return nil;
        }
#if SD_UIKIT || SD_WATCH
        UIImage *staticImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
        UIImage *staticImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
        CGImageRelease(imageRef);
        WebPDemuxDelete(demuxer);
        return staticImage;
    }
    
    // for animated webp image
    WebPIterator iter;
    // libwebp's index start with 1
    if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
        WebPDemuxReleaseIterator(&iter);
        WebPDemuxDelete(demuxer);
        return nil;
    }
    
    if (decodeFirstFrame) {
        // first frame for animated webp image
        CGImageRef imageRef = [self sd_createWebpImageWithData:iter.fragment];
#if SD_UIKIT || SD_WATCH
        UIImage *firstFrameImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
        UIImage *firstFrameImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
        firstFrameImage.sd_imageFormat = SDImageFormatWebP;
        CGImageRelease(imageRef);
        WebPDemuxReleaseIterator(&iter);
        WebPDemuxDelete(demuxer);
        return firstFrameImage;
    }
    
    int loopCount = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    BOOL hasAlpha = flags & ALPHA_FLAG;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    CGContextRef canvas = CGBitmapContextCreate(NULL, canvasWidth, canvasHeight, 8, 0, [SDImageCoderHelper colorSpaceGetDeviceRGB], bitmapInfo);
    if (!canvas) {
        WebPDemuxDelete(demuxer);
        return nil;
    }
    
    NSMutableArray<SDImageFrame *> *frames = [NSMutableArray array];
    
    do {
        @autoreleasepool {
            CGImageRef imageRef = [self sd_drawnWebpImageWithCanvas:canvas iterator:iter];
            if (!imageRef) {
                continue;
            }
#if SD_UIKIT || SD_WATCH
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
#else
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
            CGImageRelease(imageRef);
            
            NSTimeInterval duration = [self sd_frameDurationWithIterator:iter];
            SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
    } while (WebPDemuxNextFrame(&iter));
    
    WebPDemuxReleaseIterator(&iter);
    WebPDemuxDelete(demuxer);
    CGContextRelease(canvas);
    
    UIImage *animatedImage = [SDImageCoderHelper animatedImageWithFrames:frames];
    animatedImage.sd_imageLoopCount = loopCount;
    animatedImage.sd_imageFormat = SDImageFormatWebP;
    
    return animatedImage;
}

#pragma mark - Progressive Decode
- (instancetype)initIncrementalWithOptions:(nullable SDImageCoderOptions *)options {
    self = [super init];
    if (self) {
        // Progressive images need transparent, so always use premultiplied BGRA
        _idec = WebPINewRGB(MODE_bgrA, NULL, 0, 0);
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        _scale = scale;
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    if (_finished) {
        return;
    }
    _imageData = data;
    _finished = finished;
    VP8StatusCode status = WebPIUpdate(_idec, data.bytes, data.length);
    if (status != VP8_STATUS_OK && status != VP8_STATUS_SUSPENDED) {
        return;
    }
    // libwebp current does not support progressive decoding for animated image, so no need to scan and update the frame information
}

- (UIImage *)incrementalDecodedImageWithOptions:(SDImageCoderOptions *)options {
    UIImage *image;
    
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
        CGColorSpaceRef colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
        
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
        size_t components = 4;
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        // Why to use last_y for image height is because of libwebp's bug (https://bugs.chromium.org/p/webp/issues/detail?id=362)
        // It will not keep memory barrier safe on x86 architechure (macOS & iPhone simulator) but on ARM architecture (iPhone & iPad & tv & watch) it works great
        // If different threads use WebPIDecGetRGB to grab rgba bitmap, it will contain the previous decoded bitmap data
        // So this will cause our drawed image looks strange(above is the current part but below is the previous part)
        // We only grab the last_y height and draw the last_y height instead of total height image
        // Besides fix, this can enhance performance since we do not need to create extra bitmap
        CGImageRef imageRef = CGImageCreate(width, last_y, 8, components * 8, components * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
        
        CGDataProviderRelease(provider);
        
        if (!imageRef) {
            return nil;
        }
        
        CGContextRef canvas = CGBitmapContextCreate(NULL, width, height, 8, 0, [SDImageCoderHelper colorSpaceGetDeviceRGB], bitmapInfo);
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
        CGFloat scale = _scale;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        
#if SD_UIKIT || SD_WATCH
        image = [[UIImage alloc] initWithCGImage:newImageRef scale:scale orientation:UIImageOrientationUp];
#else
        image = [[UIImage alloc] initWithCGImage:newImageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
        image.sd_isDecoded = YES; // Already drawn on bitmap context above
        image.sd_imageFormat = SDImageFormatWebP;
        CGImageRelease(newImageRef);
        CGContextRelease(canvas);
    }
    
    return image;
}

- (void)sd_blendWebpImageWithCanvas:(CGContextRef)canvas iterator:(WebPIterator)iter {
    size_t canvasHeight = CGBitmapContextGetHeight(canvas);
    CGFloat tmpX = iter.x_offset;
    CGFloat tmpY = canvasHeight - iter.height - iter.y_offset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
    
    if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
        CGContextClearRect(canvas, imageRect);
    } else {
        CGImageRef imageRef = [self sd_createWebpImageWithData:iter.fragment];
        if (!imageRef) {
            return;
        }
        BOOL shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
        // If not blend, cover the target image rect. (firstly clear then draw)
        if (!shouldBlend) {
            CGContextClearRect(canvas, imageRect);
        }
        CGContextDrawImage(canvas, imageRect, imageRef);
        CGImageRelease(imageRef);
    }
}

- (nullable CGImageRef)sd_drawnWebpImageWithCanvas:(CGContextRef)canvas iterator:(WebPIterator)iter CF_RETURNS_RETAINED {
    CGImageRef imageRef = [self sd_createWebpImageWithData:iter.fragment];
    if (!imageRef) {
        return nil;
    }
    
    size_t canvasHeight = CGBitmapContextGetHeight(canvas);
    CGFloat tmpX = iter.x_offset;
    CGFloat tmpY = canvasHeight - iter.height - iter.y_offset;
    CGRect imageRect = CGRectMake(tmpX, tmpY, iter.width, iter.height);
    BOOL shouldBlend = iter.blend_method == WEBP_MUX_BLEND;
    
    // If not blend, cover the target image rect. (firstly clear then draw)
    if (!shouldBlend) {
        CGContextClearRect(canvas, imageRect);
    }
    CGContextDrawImage(canvas, imageRect, imageRef);
    CGImageRef newImageRef = CGBitmapContextCreateImage(canvas);
    
    CGImageRelease(imageRef);
    
    if (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
        CGContextClearRect(canvas, imageRect);
    }
    
    return newImageRef;
}

- (nullable CGImageRef)sd_createWebpImageWithData:(WebPData)webpData CF_RETURNS_RETAINED {
    WebPDecoderConfig config;
    if (!WebPInitDecoderConfig(&config)) {
        return nil;
    }
    
    if (WebPGetFeatures(webpData.bytes, webpData.size, &config.input) != VP8_STATUS_OK) {
        return nil;
    }
    
    BOOL hasAlpha = config.input.has_alpha;
    // iOS prefer BGRA8888 (premultiplied) or BGRX8888 bitmapInfo for screen rendering, which is same as `UIGraphicsBeginImageContext()` or `- [CALayer drawInContext:]`
    // use this bitmapInfo, combined with right colorspace, even without decode, can still avoid extra CA::Render::copy_image(which marked `Color Copied Images` from Instruments)
    WEBP_CSP_MODE colorspace = MODE_bgrA;
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
    config.options.use_threads = 1;
    config.output.colorspace = colorspace;
    
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
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = 32;
    size_t bytesPerRow = config.output.u.RGBA.stride;
    CGColorSpaceRef colorSpaceRef = [SDImageCoderHelper colorSpaceGetDeviceRGB];
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGDataProviderRelease(provider);
    
    return imageRef;
}

- (NSTimeInterval)sd_frameDurationWithIterator:(WebPIterator)iter {
    int duration = iter.duration;
    if (duration <= 10) {
        // WebP standard says 0 duration is used for canvas updating but not showing image, but actually Chrome and other implementations set it to 100ms if duration is lower or equal than 10ms
        // Some animated WebP images also created without duration, we should keep compatibility
        duration = 100;
    }
    return duration / 1000.0;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return (format == SDImageFormatWebP);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(nullable SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    
    NSData *data;
    
    double compressionQuality = 1;
    if (options[SDImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[SDImageCoderEncodeCompressionQuality] doubleValue];
    }
    NSArray<SDImageFrame *> *frames = [SDImageCoderHelper framesFromAnimatedImage:image];
    
    BOOL encodeFirstFrame = [options[SDImageCoderEncodeFirstFrameOnly] boolValue];
    if (encodeFirstFrame || frames.count == 0) {
        // for static single webp image
        data = [self sd_encodedWebpDataWithImage:image quality:compressionQuality];
    } else {
        // for animated webp image
        WebPMux *mux = WebPMuxNew();
        if (!mux) {
            return nil;
        }
        for (size_t i = 0; i < frames.count; i++) {
            SDImageFrame *currentFrame = frames[i];
            NSData *webpData = [self sd_encodedWebpDataWithImage:currentFrame.image quality:compressionQuality];
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

- (nullable NSData *)sd_encodedWebpDataWithImage:(nullable UIImage *)image quality:(double)quality {
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
            .colorSpace = [SDImageCoderHelper colorSpaceGetDeviceRGB],
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
    float qualityFactor = quality * 100; // WebP quality is 0-100
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

#pragma mark - SDAnimatedImageCoder
- (instancetype)initWithAnimatedImageData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    if (self) {
        WebPData webpData;
        WebPDataInit(&webpData);
        webpData.bytes = data.bytes;
        webpData.size = data.length;
        WebPDemuxer *demuxer = WebPDemux(&webpData);
        if (!demuxer) {
            return nil;
        }
        BOOL framesValid = [self scanAndCheckFramesValidWithDemuxer:demuxer];
        if (!framesValid) {
            WebPDemuxDelete(demuxer);
            return nil;
        }
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        _scale = scale;
        _demux = demuxer;
        _imageData = data;
        _currentBlendIndex = NSNotFound;
        _lock = dispatch_semaphore_create(1);
    }
    return self;
}

- (BOOL)scanAndCheckFramesValidWithDemuxer:(WebPDemuxer *)demuxer {
    if (!demuxer) {
        return NO;
    }
    WebPIterator iter;
    if (!WebPDemuxGetFrame(demuxer, 1, &iter)) {
        WebPDemuxReleaseIterator(&iter);
        return NO;
    }
    
    uint32_t iterIndex = 0;
    uint32_t lastBlendIndex = 0;
    uint32_t flags = WebPDemuxGetI(demuxer, WEBP_FF_FORMAT_FLAGS);
    BOOL hasAnimation = flags & ANIMATION_FLAG;
    BOOL hasAlpha = flags & ALPHA_FLAG;
    int canvasWidth = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_WIDTH);
    int canvasHeight = WebPDemuxGetI(demuxer, WEBP_FF_CANVAS_HEIGHT);
    uint32_t frameCount = WebPDemuxGetI(demuxer, WEBP_FF_FRAME_COUNT);
    uint32_t loopCount = WebPDemuxGetI(demuxer, WEBP_FF_LOOP_COUNT);
    NSMutableArray<SDWebPCoderFrame *> *frames = [NSMutableArray array];
    
    // We should loop all the frames and scan each frames' blendFromIndex for later decoding, this can also ensure all frames is valid
    do {
        SDWebPCoderFrame *frame = [[SDWebPCoderFrame alloc] init];
        frame.index = iterIndex;
        frame.duration = [self sd_frameDurationWithIterator:iter];
        frame.width = iter.width;
        frame.height = iter.height;
        frame.hasAlpha = iter.has_alpha;
        frame.dispose = iter.dispose_method;
        frame.blend = iter.blend_method;
        frame.offsetX = iter.x_offset;
        frame.offsetY = canvasHeight - iter.y_offset - iter.height;

        BOOL sizeEqualsToCanvas = (iter.width == canvasWidth && iter.height == canvasHeight);
        BOOL offsetIsZero = (iter.x_offset == 0 && iter.y_offset == 0);
        frame.isFullSize = (sizeEqualsToCanvas && offsetIsZero);
        
        if ((!frame.blend || !frame.hasAlpha) && frame.isFullSize) {
            lastBlendIndex = iterIndex;
            frame.blendFromIndex = iterIndex;
        } else {
            if (frame.dispose && frame.isFullSize) {
                frame.blendFromIndex = lastBlendIndex;
                lastBlendIndex = iterIndex + 1;
            } else {
                frame.blendFromIndex = lastBlendIndex;
            }
        }
        iterIndex++;
        [frames addObject:frame];
    } while (WebPDemuxNextFrame(&iter));
    WebPDemuxReleaseIterator(&iter);
    
    if (frames.count != frameCount) {
        return NO;
    }
    _frames = [frames copy];
    _hasAnimation = hasAnimation;
    _hasAlpha = hasAlpha;
    _canvasWidth = canvasWidth;
    _canvasHeight = canvasHeight;
    _frameCount = frameCount;
    _loopCount = loopCount;
    
    return YES;
}

- (NSData *)animatedImageData {
    return _imageData;
}

- (NSUInteger)animatedImageLoopCount {
    return _loopCount;
}

- (NSUInteger)animatedImageFrameCount {
    return _frameCount;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index {
    if (index >= _frameCount) {
        return 0;
    }
    return _frames[index].duration;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    UIImage *image;
    if (index >= _frameCount) {
        return nil;
    }
    LOCKBLOCK({
        image = [self safeAnimatedImageFrameAtIndex:index];
    });
    return image;
}

- (UIImage *)safeAnimatedImageFrameAtIndex:(NSUInteger)index {
    if (!_canvas) {
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= _hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        CGContextRef canvas = CGBitmapContextCreate(NULL, _canvasWidth, _canvasHeight, 8, 0, [SDImageCoderHelper colorSpaceGetDeviceRGB], bitmapInfo);
        if (!canvas) {
            return nil;
        }
        _canvas = canvas;
    }
    
    SDWebPCoderFrame *frame = _frames[index];
    UIImage *image;
    WebPIterator iter;
    if (_currentBlendIndex + 1 == index) {
        // If current blend index is equal to request index, normal serial process
        _currentBlendIndex = index;
        // libwebp's index start with 1
        if (!WebPDemuxGetFrame(_demux, (int)(index + 1), &iter)) {
            WebPDemuxReleaseIterator(&iter);
            return nil;
        }
        CGImageRef imageRef = [self sd_drawnWebpImageWithCanvas:_canvas iterator:iter];
        if (!imageRef) {
            return nil;
        }
#if SD_UIKIT || SD_WATCH
        image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:UIImageOrientationUp];
#else
        image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:kCGImagePropertyOrientationUp];
#endif
        CGImageRelease(imageRef);
    } else {
        // Else, this can happen when one image set to different imageViews or one loop end. So we should clear the shared cavans.
        if (_currentBlendIndex != NSNotFound) {
            CGContextClearRect(_canvas, CGRectMake(0, 0, _canvasWidth, _canvasHeight));
        }
        _currentBlendIndex = index;
        
        // Then, loop from the blend from index, draw each of previous frames on the canvas.
        // We use do while loop to call `WebPDemuxNextFrame`(fast), only (startIndex == endIndex) need to create image instance
        size_t startIndex = frame.blendFromIndex;
        size_t endIndex = frame.index;
        if (!WebPDemuxGetFrame(_demux, (int)(startIndex + 1), &iter)) {
            WebPDemuxReleaseIterator(&iter);
            return nil;
        }
        do {
            @autoreleasepool {
                if ((size_t)iter.frame_num == endIndex) {
                    [self sd_blendWebpImageWithCanvas:_canvas iterator:iter];
                } else {
                    CGImageRef imageRef = [self sd_drawnWebpImageWithCanvas:_canvas iterator:iter];
                    if (!imageRef) {
                        return nil;
                    }
#if SD_UIKIT || SD_WATCH
                    image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:UIImageOrientationUp];
#else
                    image = [[UIImage alloc] initWithCGImage:imageRef scale:_scale orientation:kCGImagePropertyOrientationUp];
#endif
                    CGImageRelease(imageRef);
                }
            }
        } while ((size_t)iter.frame_num < (endIndex + 1) && WebPDemuxNextFrame(&iter));
    }
    
    WebPDemuxReleaseIterator(&iter);
    return image;
}

@end

#endif

