//
//  SDWebImageCoderHelper.m
//  SDWebImage
//
//  Created by lizhuoli on 2017/10/28.
//  Copyright © 2017年 Dailymotion. All rights reserved.
//

#import "SDWebImageCoderHelper.h"
#import "SDWebImageFrame.h"
#import "UIImage+MultiFormat.h"
#import "NSImage+WebCache.h"
#import <ImageIO/ImageIO.h>

@implementation SDWebImageCoderHelper

+ (CGColorSpaceRef)currentDeviceRGB {
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

+ (BOOL)containsAlphaForImageRef:(CGImageRef)imageRef {
    if (!imageRef) {
        return NO;
    }
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    BOOL hasAlpha = !(alphaInfo == kCGImageAlphaNone ||
                      alphaInfo == kCGImageAlphaNoneSkipFirst ||
                      alphaInfo == kCGImageAlphaNoneSkipLast);
    return hasAlpha;
}

+ (UIImage *)animatedImageWithFrames:(NSArray<SDWebImageFrame *> *)frames properties:(NSDictionary *)properties {
    NSUInteger frameCount = frames.count;
    if (frameCount == 0) {
        return nil;
    }
    
    UIImage *animatedImage;
    NSUInteger loopCount = 0;
    if ([properties objectForKey:SDWebImageFrameLoopCountKey]) {
        loopCount = [[properties objectForKey:SDWebImageFrameLoopCountKey] unsignedIntegerValue];
    }
    
#if SD_UIKIT || SD_WATCH
    NSUInteger durations[frameCount];
    for (size_t i = 0; i < frameCount; i++) {
        durations[i] = frames[i].duration;
    }
    NSUInteger const gcd = gcdArray(frameCount, durations);
    __block NSUInteger totalDuration = 0;
    NSMutableArray<UIImage *> *animatedImages = [NSMutableArray arrayWithCapacity:frameCount];
    [frames enumerateObjectsUsingBlock:^(SDWebImageFrame * _Nonnull frame, NSUInteger idx, BOOL * _Nonnull stop) {
        UIImage *image = frame.image;
        NSUInteger duration = frame.duration;
        NSUInteger repeatCount;
        if (gcd) {
            repeatCount = duration / gcd;
        } else {
            repeatCount = 1;
        }
        for (size_t i = 0; i < repeatCount; ++i) {
            totalDuration += duration;
            [animatedImages addObject:image];
        }
    }];
    
    animatedImage = [UIImage animatedImageWithImages:animatedImages duration:totalDuration / 1000.f];
    
#else
    
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData sd_UTTypeFromSDImageFormat:SDImageFormatGIF];
    // Create an image destination. GIF does not support EXIF image orientation
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, frameCount, NULL);
    if (!imageDestination) {
        // Handle failure.
        return nil;
    }
    NSDictionary *gifProperties = @{(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary: @{(__bridge_transfer NSString *)kCGImagePropertyGIFLoopCount : @(loopCount)}};
    CGImageDestinationSetProperties(imageDestination, (__bridge CFDictionaryRef)gifProperties);
    for (size_t i = 0; i < frameCount; i++) {
        @autoreleasepool {
            SDWebImageFrame *frame = frames[i];
            float frameDuration = frame.duration;
            CGImageRef frameImageRef = frame.image.CGImage;
            NSDictionary *frameProperties = @{(__bridge_transfer NSString *)kCGImagePropertyGIFDictionary : @{(__bridge_transfer NSString *)kCGImagePropertyGIFUnclampedDelayTime : @(frameDuration)}};
            CGImageDestinationAddImage(imageDestination, frameImageRef, (__bridge CFDictionaryRef)frameProperties);
        }
    }
    // Finalize the destination.
    if (CGImageDestinationFinalize(imageDestination) == NO) {
        // Handle failure.
        CFRelease(imageDestination);
        return nil;
    }
    CFRelease(imageDestination);
    animatedImage = [[NSImage alloc] initWithData:imageData];
#endif
    
    animatedImage.sd_imageLoopCount = loopCount;
    
    return animatedImage;
}

+ (NSArray<SDWebImageFrame *> *)framesFromAnimatedImage:(UIImage *)animatedImage {
    if (!animatedImage) {
        return nil;
    }
    
    NSMutableArray<SDWebImageFrame *> *frames = [NSMutableArray array];
    NSUInteger frameCount = 0;
    
#if SD_UIKIT || SD_WATCH
    NSArray<UIImage *> *animatedImages = animatedImage.images;
    frameCount = animatedImages.count;
    if (frameCount == 0) {
        return nil;
    }
    
    NSUInteger avgDuration = animatedImage.duration * 1000 / frameCount;
    if (avgDuration == 0) {
        avgDuration = 100; // if it's a animated image but no duration, set it to default 100ms (this do not have that 10ms limit like GIF or WebP to allow custom coder provide the limit)
    }
    
    __block NSUInteger index = 0;
    __block NSUInteger repeatCount = 1;
    __block UIImage *previousImage = animatedImages.firstObject;
    [animatedImages enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        // ignore first
        if (idx == 0) {
            return;
        }
        if ([image isEqual:previousImage]) {
            repeatCount++;
        } else {
            SDWebImageFrame *frame = [SDWebImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount property:nil];
            [frames addObject:frame];
            repeatCount = 1;
            index++;
        }
        previousImage = image;
        // last one
        if (idx == frameCount - 1) {
            SDWebImageFrame *frame = [SDWebImageFrame frameWithImage:previousImage duration:avgDuration * repeatCount property:nil];
            [frames addObject:frame];
        }
    }];
    
#else
    
    NSBitmapImageRep *bitmapRep;
    for (NSImageRep *imageRep in animatedImage.representations) {
        if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
            bitmapRep = (NSBitmapImageRep *)imageRep;
            break;
        }
    }
    if (bitmapRep) {
        frameCount = [[bitmapRep valueForProperty:NSImageFrameCount] unsignedIntegerValue];
    }
    
    if (frameCount == 0) {
        return nil;
    }
    
    for (size_t i = 0; i < frameCount; i++) {
        @autoreleasepool {
            // NSBitmapImageRep need to manually change frame. "Good taste" API
            [bitmapRep setProperty:NSImageCurrentFrame withValue:@(i)];
            float frameDuration = [[bitmapRep valueForProperty:NSImageCurrentFrameDuration] floatValue];
            NSImage *frameImage = [[NSImage alloc] initWithCGImage:bitmapRep.CGImage size:CGSizeZero];
            SDWebImageFrame *frame = [SDWebImageFrame frameWithImage:frameImage duration:frameDuration * 1000 property:nil];
            [frames addObject:frame];
        }
    }
#endif
    
    return frames;
}

#if SD_UIKIT || SD_WATCH
// Convert an EXIF image orientation to an iOS one.
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(NSInteger)exifOrientation {
    // CGImagePropertyOrientation is available on iOS 8 above. Currently kept for compatibility
    UIImageOrientation imageOrientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case 1:
            imageOrientation = UIImageOrientationUp;
            break;
        case 3:
            imageOrientation = UIImageOrientationDown;
            break;
        case 8:
            imageOrientation = UIImageOrientationLeft;
            break;
        case 6:
            imageOrientation = UIImageOrientationRight;
            break;
        case 2:
            imageOrientation = UIImageOrientationUpMirrored;
            break;
        case 4:
            imageOrientation = UIImageOrientationDownMirrored;
            break;
        case 5:
            imageOrientation = UIImageOrientationLeftMirrored;
            break;
        case 7:
            imageOrientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return imageOrientation;
}

// Convert an iOS orientation to an EXIF image orientation.
+ (NSInteger)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation {
    // CGImagePropertyOrientation is available on iOS 8 above. Currently kept for compatibility
    NSInteger exifOrientation = 1;
    switch (imageOrientation) {
        case UIImageOrientationUp:
            exifOrientation = 1;
            break;
        case UIImageOrientationDown:
            exifOrientation = 3;
            break;
        case UIImageOrientationLeft:
            exifOrientation = 8;
            break;
        case UIImageOrientationRight:
            exifOrientation = 6;
            break;
        case UIImageOrientationUpMirrored:
            exifOrientation = 2;
            break;
        case UIImageOrientationDownMirrored:
            exifOrientation = 4;
            break;
        case UIImageOrientationLeftMirrored:
            exifOrientation = 5;
            break;
        case UIImageOrientationRightMirrored:
            exifOrientation = 7;
            break;
        default:
            break;
    }
    return exifOrientation;
}
#endif

#pragma mark - Helper Fuction
#if SD_UIKIT || SD_WATCH
static NSUInteger gcd(NSUInteger a,NSUInteger b) {
    NSUInteger c;
    while (a != 0) {
        c = a;
        a = b % a;
        b = c;
    }
    return b;
}

static NSUInteger gcdArray(size_t const count, NSUInteger const * const values) {
    if (count == 0) {
        return 0;
    }
    NSUInteger result = values[0];
    for (size_t i = 1; i < count; ++i) {
        result = gcd(values[i], result);
    }
    return result;
}
#endif

@end
