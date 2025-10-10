/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDImageHEICCoder.h"
#import "SDImageIOAnimatedCoderInternal.h"

// These constants are available from iOS 13+ and Xcode 11. This raw value is used for toolchain and firmware compatibility
static NSString * kSDCGImagePropertyHEICSDictionary = @"{HEICS}";
static NSString * kSDCGImagePropertyHEICSLoopCount = @"LoopCount";
static NSString * kSDCGImagePropertyHEICSDelayTime = @"DelayTime";
static NSString * kSDCGImagePropertyHEICSUnclampedDelayTime = @"UnclampedDelayTime";

@implementation SDImageHEICCoder

+ (void)initialize {
    if (@available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)) {
        // Use SDK instead of raw value
        kSDCGImagePropertyHEICSDictionary = (__bridge NSString *)kCGImagePropertyHEICSDictionary;
        kSDCGImagePropertyHEICSLoopCount = (__bridge NSString *)kCGImagePropertyHEICSLoopCount;
        kSDCGImagePropertyHEICSDelayTime = (__bridge NSString *)kCGImagePropertyHEICSDelayTime;
        kSDCGImagePropertyHEICSUnclampedDelayTime = (__bridge NSString *)kCGImagePropertyHEICSUnclampedDelayTime;
    }
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
    SDImageFormat format = [NSData sd_imageFormatForImageData:data];
    if (format == SDImageFormatHEIC) {
        // Check HEIC decoding compatibility
        return [self.class canDecodeFromFormat:SDImageFormatHEIC];
    } else if (format == SDImageFormatHEIF) {
        // Check HEIF decoding compatibility
        return [self.class canDecodeFromFormat:SDImageFormatHEIF];
    } else {
        return NO;
    }
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return [self canDecodeFromData:data];
}

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    if (format == SDImageFormatHEIC) {
        // Check HEIC encoding compatibility
        return [self.class canEncodeToFormat:SDImageFormatHEIC];
    } else if (format == SDImageFormatHEIF) {
        // Check HEIF encoding compatibility
        return [self.class canEncodeToFormat:SDImageFormatHEIF];
    } else {
        return NO;
    }
}

#pragma mark - Subclass Override

+ (SDImageFormat)imageFormat {
    return SDImageFormatHEIC;
}

+ (NSString *)imageUTType {
    // See: https://nokiatech.github.io/heif/technical.html
    // Actually HEIC has another concept called `non-timed Image Sequence`, which can be encoded using `public.heic`
    return (__bridge NSString *)kSDUTTypeHEIC;
}

+ (NSString *)animatedImageUTType {
    // See: https://nokiatech.github.io/heif/technical.html
    // We use `timed Image Sequence`, means, `public.heics` for animated image encoding
    return (__bridge NSString *)kSDUTTypeHEICS;
}

+ (NSString *)dictionaryProperty {
    return kSDCGImagePropertyHEICSDictionary;
}

+ (NSString *)unclampedDelayTimeProperty {
    return kSDCGImagePropertyHEICSUnclampedDelayTime;
}

+ (NSString *)delayTimeProperty {
    return kSDCGImagePropertyHEICSDelayTime;
}

+ (NSString *)loopCountProperty {
    return kSDCGImagePropertyHEICSLoopCount;
}

+ (NSUInteger)defaultLoopCount {
    return 0;
}

@end
