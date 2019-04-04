/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <ImageIO/ImageIO.h>
#import "SDImageAnimatedCoder.h"
#import "NSData+ImageContentType.h"
#import "UIImage+Metadata.h"
#import "NSImage+Compatibility.h"
#import "SDImageCoderHelper.h"
#import "SDAnimatedImageRep.h"

SDImageCoderOption const SDImageCoderWebImageAnimatedPropertyDictionary = @"SDImageCoderWebImageAnimatedPropertyDictionary";
SDImageCoderOption const SDImageCoderWebImageAnimatedPropertyLoopCount = @"SDImageCoderWebImageAnimatedPropertyLoopCount";
SDImageCoderOption const SDImageCoderWebAnimatedPropertyUnclampedDelayTime = @"SDImageCoderWebAnimatedPropertyUnclampedDelayTime";
SDImageCoderOption const SDImageCoderWebAnimatedPropertyDelayTime = @"SDImageCoderWebAnimatedPropertyDelayTime";
SDImageCoderOption const SDImageCoderWebImageAnimatedFormat = @"SDImageCoderWebImageAnimatedFormat";
SDImageCoderOption const SDImageCoderWebImageAnimatedDefaultLoopCount = @"SDImageCoderWebImageAnimatedDefaultLoopCount";

@interface SDAnimatedCoderFrame : NSObject
@property (nonatomic, assign) NSUInteger index; // Frame index (zero based)
@property (nonatomic, assign) NSTimeInterval duration; // Frame duration in seconds
@end

@implementation SDAnimatedCoderFrame
@end

@implementation SDImageAnimatedCoder {
    size_t _width, _height;
    CGImageSourceRef _imageSource;
    NSData *_imageData;
    CGFloat _scale;
    NSUInteger _loopCount;
    NSUInteger _frameCount;
    NSArray<SDAnimatedCoderFrame *> *_frames;
    BOOL _finished;
    SDImageFormat _format;
    SDImageCoderOptions *_options;
}

- (instancetype)initWithOptions:(SDImageCoderOptions *)options
{
    if (self = [super init]) {
        _format = [options[SDImageCoderWebImageAnimatedFormat] ?: @(-1) integerValue];
        _options = options;
    }
    return self;
}

- (instancetype)init
{
    if (self = [self initWithOptions:nil]) {
    }
    return self;
}

- (void)dealloc
{
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
#if SD_UIKIT
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    if (_imageSource) {
        for (size_t i = 0; i < _frameCount; i++) {
            CGImageSourceRemoveCacheAtIndex(_imageSource, i);
        }
    }
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == _format);
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
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
    
#if SD_MAC
    SDAnimatedImageRep *imageRep = [[SDAnimatedImageRep alloc] initWithData:data];
    NSSize size = NSMakeSize(imageRep.pixelsWide / scale, imageRep.pixelsHigh / scale);
    imageRep.size = size;
    NSImage *animatedImage = [[NSImage alloc] initWithSize:size];
    [animatedImage addRepresentation:imageRep];
    return animatedImage;
#else
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
    UIImage *animatedImage;
    
    BOOL decodeFirstFrame = [options[SDImageCoderDecodeFirstFrameOnly] boolValue];
    if (decodeFirstFrame || count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data scale:scale];
    } else {
        NSMutableArray<SDImageFrame *> *frames = [NSMutableArray array];
        
        for (size_t i = 0; i < count; i++) {
            CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, i, NULL);
            if (!imageRef) {
                continue;
            }
            
            float duration = [self sd_frameDurationAtIndex:i source:source];
            UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
            CGImageRelease(imageRef);
            
            SDImageFrame *frame = [SDImageFrame frameWithImage:image duration:duration];
            [frames addObject:frame];
        }
        
        NSUInteger loopCount = [self sd_imageLoopCountWithSource:source];
        
        animatedImage = [SDImageCoderHelper animatedImageWithFrames:frames];
        animatedImage.sd_imageLoopCount = loopCount;
    }
    animatedImage.sd_imageFormat = _format;
    CFRelease(source);
    
    return animatedImage;
#endif
}

- (NSUInteger)sd_imageLoopCountWithSource:(CGImageSourceRef)source {
    NSUInteger loopCount = [_options[SDImageCoderWebImageAnimatedDefaultLoopCount] unsignedIntegerValue];
    NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);
    NSDictionary *properties = imageProperties[_options[SDImageCoderWebImageAnimatedPropertyDictionary] ?: @""];
    if (properties) {
        NSNumber *animatedLoopCount = properties[_options[SDImageCoderWebImageAnimatedPropertyLoopCount] ?: @""];
        if (animatedLoopCount != nil) {
            loopCount = animatedLoopCount.unsignedIntegerValue;
        }
    }
    return loopCount;
}

- (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source {
    float frameDuration = 0.1f;
    CFDictionaryRef cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    NSDictionary *frameProperties = (__bridge NSDictionary *)cfFrameProperties;
    NSDictionary *properties = frameProperties[_options[SDImageCoderWebImageAnimatedPropertyDictionary] ?: @""];
    
    NSNumber *delayTimeUnclampedProp = properties[_options[SDImageCoderWebAnimatedPropertyUnclampedDelayTime] ?: @""];
    if (delayTimeUnclampedProp != nil) {
        frameDuration = [delayTimeUnclampedProp floatValue];
    } else {
        NSNumber *delayTimeProp = properties[_options[SDImageCoderWebAnimatedPropertyDelayTime] ?: @""];
        if (delayTimeProp != nil) {
            frameDuration = [delayTimeProp floatValue];
        }
    }
    
    if (frameDuration < 0.011f) {
        frameDuration = 0.100f;
    }
    
    CFRelease(cfFrameProperties);
    return frameDuration;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return (format == _format);
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(nullable SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    
    if (format != _format) {
        return nil;
    }
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:_format];
    NSArray<SDImageFrame *> *frames = [SDImageCoderHelper framesFromAnimatedImage:image];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frames.count, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    NSMutableDictionary *animatedProperties = [NSMutableDictionary dictionary];
    double compressionQuality = 1;
    if (options[SDImageCoderEncodeCompressionQuality]) {
        compressionQuality = [options[SDImageCoderEncodeCompressionQuality] doubleValue];
    }
    animatedProperties[(__bridge NSString *)kCGImageDestinationLossyCompressionQuality] = @(compressionQuality);
    
    BOOL encodeFirstFrame = [options[SDImageCoderEncodeFirstFrameOnly] boolValue];
    if (encodeFirstFrame || frames.count == 0) {
        // for static single image
        CGImageDestinationAddImage(imageDestination, image.CGImage, (__bridge CFDictionaryRef)animatedProperties);
    } else {
        // for animated images
        NSUInteger loopCount = image.sd_imageLoopCount;
        NSDictionary *properties = @{_options[SDImageCoderWebImageAnimatedPropertyLoopCount] ?: @"" : @(loopCount)};
        animatedProperties[_options[SDImageCoderWebImageAnimatedPropertyDictionary] ?: @""] = properties;
        CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)animatedProperties);
        
        for (size_t i = 0; i < frames.count; i++) {
            SDImageFrame *frame = frames[i];
            float frameDuration = frame.duration;
            CGImageRef frameImageRef = frame.image.CGImage;
            NSDictionary *frameProperties = @{_options[SDImageCoderWebImageAnimatedPropertyDictionary] ?: @"" : @{_options[SDImageCoderWebAnimatedPropertyDelayTime] ?: @"" : @(frameDuration)}};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        imageData = nil;
    }
    
    CFRelease(imageDestination);
    
    return [imageData copy];
}

#pragma mark - Progressive Decode

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == _format);
}

- (instancetype)initIncrementalWithOptions:(nullable SDImageCoderOptions *)options {
    self = [super init];
    if (self) {
        _format = [options[SDImageCoderWebImageAnimatedFormat] ?: @(-1) integerValue];
        _options = [options copy];
        CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:_format];
        _imageSource = CGImageSourceCreateIncremental((__bridge CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : (__bridge NSString *)imageUTType});
        CGFloat scale = 1;
        NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
        if (scaleFactor != nil) {
            scale = [scaleFactor doubleValue];
            if (scale < 1) {
                scale = 1;
            }
        }
        _scale = scale;
#if SD_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    if (_finished) {
        return;
    }
    _imageData = data;
    _finished = finished;
    
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf
    
    // Update the data source, we must pass ALL the data, not just the new bytes
    CGImageSourceUpdateData(_imageSource, (__bridge CFDataRef)data, finished);
    
    if (_width + _height == 0) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_height);
            val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            if (val) CFNumberGetValue(val, kCFNumberLongType, &_width);
            CFRelease(properties);
        }
    }
    
    // For animated image progressive decoding because the frame count and duration may be changed.
    [self scanAndCheckFramesValidWithImageSource:_imageSource];
}

- (UIImage *)incrementalDecodedImageWithOptions:(SDImageCoderOptions *)options {
    UIImage *image;
    
    if (_width + _height > 0) {
        // Create the image
        CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        
        if (partialImageRef) {
            CGFloat scale = _scale;
            NSNumber *scaleFactor = options[SDImageCoderDecodeScaleFactor];
            if (scaleFactor != nil) {
                scale = [scaleFactor doubleValue];
                if (scale < 1) {
                    scale = 1;
                }
            }
#if SD_UIKIT || SD_WATCH
            image = [[UIImage alloc] initWithCGImage:partialImageRef scale:scale orientation:UIImageOrientationUp];
#else
            image = [[UIImage alloc] initWithCGImage:partialImageRef scale:scale orientation:kCGImagePropertyOrientationUp];
#endif
            CGImageRelease(partialImageRef);
            image.sd_imageFormat = _format;
        }
    }
    
    return image;
}

#pragma mark - SDAnimatedImageCoder
- (nullable instancetype)initWithAnimatedImageData:(nullable NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    self = [super init];
    if (self) {
        _format = [options[SDImageCoderWebImageAnimatedFormat] ?: @(-1) integerValue];
        _options = [options copy];
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
        if (!imageSource) {
            return nil;
        }
        BOOL framesValid = [self scanAndCheckFramesValidWithImageSource:imageSource];
        if (!framesValid) {
            CFRelease(imageSource);
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
        _imageSource = imageSource;
        _imageData = data;
#if SD_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (BOOL)scanAndCheckFramesValidWithImageSource:(CGImageSourceRef)imageSource
{
    if (!imageSource) {
        return NO;
    }
    NSUInteger frameCount = CGImageSourceGetCount(imageSource);
    NSUInteger loopCount = [self sd_imageLoopCountWithSource:imageSource];
    NSMutableArray<SDAnimatedCoderFrame *> *frames = [NSMutableArray array];
    
    for (size_t i = 0; i < frameCount; i++) {
        SDAnimatedCoderFrame *frame = [[SDAnimatedCoderFrame alloc] init];
        frame.index = i;
        frame.duration = [self sd_frameDurationAtIndex:i source:imageSource];
        [frames addObject:frame];
    }
    
    _frameCount = frameCount;
    _loopCount = loopCount;
    _frames = [frames copy];
    
    return YES;
}

- (NSData *)animatedImageData
{
    return _imageData;
}

- (NSUInteger)animatedImageLoopCount
{
    return _loopCount;
}

- (NSUInteger)animatedImageFrameCount
{
    return _frameCount;
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index
{
    if (index >= _frameCount) {
        return 0;
    }
    return _frames[index].duration;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index
{
    CGImageRef imageRef = CGImageSourceCreateImageAtIndex(_imageSource, index, NULL);
    if (!imageRef) {
        return nil;
    }
    // Image/IO create CGImage does not decompressed, so we do this because this is called background queue, this can avoid main queue block when rendering(especially when one more imageViews use the same image instance)
    CGImageRef newImageRef = [SDImageCoderHelper CGImageCreateDecoded:imageRef];
    if (!newImageRef) {
        newImageRef = imageRef;
    } else {
        CGImageRelease(imageRef);
    }
#if SD_MAC
    UIImage *image = [[UIImage alloc] initWithCGImage:newImageRef scale:_scale orientation:kCGImagePropertyOrientationUp];
#else
    UIImage *image = [UIImage imageWithCGImage:newImageRef scale:_scale orientation:UIImageOrientationUp];
#endif
    CGImageRelease(newImageRef);
    return image;
}


@end
