/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDImageHEICCoder.h"
#import "SDImageHEICCoderInternal.h"

// These constantce are available from iOS 13+ and Xcode 11. This raw value is used for toolchain and firmware compatiblitiy
static CFStringRef kSDCGImagePropertyHEICSDictionary = (__bridge CFStringRef)@"{HEICS}";
static CFStringRef kSDCGImagePropertyHEICSLoopCount = (__bridge CFStringRef)@"LoopCount";
static CFStringRef kSDCGImagePropertyHEICSDelayTime = (__bridge CFStringRef)@"DelayTime";
static CFStringRef kSDCGImagePropertyHEICSUnclampedDelayTime = (__bridge CFStringRef)@"UnclampedDelayTime";

@implementation SDImageHEICCoder

+ (void)initialize {
#if __IPHONE_13_0 || __TVOS_13_0 || __MAC_10_15 || __WATCHOS_6_0
    // Xcode 11
    if (@available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)) {
        // Use SDK instead of raw value
        kSDCGImagePropertyHEICSDictionary = kCGImagePropertyHEICSDictionary;
        kSDCGImagePropertyHEICSLoopCount = kCGImagePropertyHEICSLoopCount;
        kSDCGImagePropertyHEICSDelayTime = kCGImagePropertyHEICSDelayTime;
        kSDCGImagePropertyHEICSUnclampedDelayTime = kCGImagePropertyHEICSUnclampedDelayTime;
    }
#endif
}

+ (instancetype)sharedCoder {
    static SDImageHEICCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageHEICCoder alloc] init];
    });
    return coder;
}

#pragma mark - SDImageCoder

- (BOOL)canDecodeFromData:(nullable NSData *)data {
    switch ([NSData sd_imageFormatForImageData:data]) {
        case SDImageFormatHEIC:
            // Check HEIC decoding compatibility
            return [SDImageHEICCoder canDecodeFromHEICFormat];
        case SDImageFormatHEIF:
            // Check HEIF decoding compatibility
            return [SDImageHEICCoder canDecodeFromHEIFFormat];
        default:
            return NO;
    }
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return [self canDecodeFromData:data];
}

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    switch (format) {
        case SDImageFormatHEIC:
            // Check HEIC encoding compatibility
            return [SDImageHEICCoder canEncodeToHEICFormat];
        case SDImageFormatHEIF:
            // Check HEIF encoding compatibility
            return [SDImageHEICCoder canEncodeToHEIFFormat];
        default:
            return NO;
    }
}

#pragma mark - HEIF Format

+ (BOOL)canDecodeFromFormat:(SDImageFormat)format {
    CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:format];
    NSArray *imageUTTypes = (__bridge_transfer NSArray *)CGImageSourceCopyTypeIdentifiers();
    if ([imageUTTypes containsObject:(__bridge NSString *)(imageUTType)]) {
        return YES;
    }
    return NO;
}

+ (BOOL)canDecodeFromHEICFormat {
    static BOOL canDecode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canDecode = [self canDecodeFromFormat:SDImageFormatHEIC];
    });
    return canDecode;
}

+ (BOOL)canDecodeFromHEIFFormat {
    static BOOL canDecode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canDecode = [self canDecodeFromFormat:SDImageFormatHEIF];
    });
    return canDecode;
}

+ (BOOL)canEncodeToFormat:(SDImageFormat)format {
    NSMutableData *imageData = [NSMutableData data];
    CFStringRef imageUTType = [NSData sd_UTTypeFromImageFormat:format];
    
    // Create an image destination.
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)imageData, imageUTType, 1, NULL);
    if (!imageDestination) {
        // Can't encode to HEIC
        return NO;
    } else {
        // Can encode to HEIC
        CFRelease(imageDestination);
        return YES;
    }
}

+ (BOOL)canEncodeToHEICFormat {
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canEncode = [self canEncodeToFormat:SDImageFormatHEIC];
    });
    return canEncode;
}

+ (BOOL)canEncodeToHEIFFormat {
    static BOOL canEncode = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canEncode = [self canEncodeToFormat:SDImageFormatHEIF];
    });
    return canEncode;
}

#pragma mark - Subclass Override

+ (SDImageFormat)imageFormat {
    return SDImageFormatHEIC;
}

+ (NSString *)imageUTType {
    return (__bridge NSString *)kSDUTTypeHEIC;
}

+ (NSString *)dictionaryProperty {
    return (__bridge NSString *)kSDCGImagePropertyHEICSDictionary;
}

+ (NSString *)unclampedDelayTimeProperty {
    return (__bridge NSString *)kSDCGImagePropertyHEICSUnclampedDelayTime;
}

+ (NSString *)delayTimeProperty {
    return (__bridge NSString *)kSDCGImagePropertyHEICSDelayTime;
}

+ (NSString *)loopCountProperty {
    return (__bridge NSString *)kSDCGImagePropertyHEICSLoopCount;
}

+ (NSUInteger)defaultLoopCount {
    return 0;
}

@end
