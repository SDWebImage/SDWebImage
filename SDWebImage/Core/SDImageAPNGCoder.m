/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageAPNGCoder.h"
#if SD_MAC
#import <CoreServices/CoreServices.h>
#else
#import <MobileCoreServices/MobileCoreServices.h>
#endif

// iOS 8 Image/IO framework binary does not contains these APNG contants, so we define them. Thanks Apple :)
static NSString * kSDCGImagePropertyAPNGLoopCount = @"LoopCount";
static NSString * kSDCGImagePropertyAPNGDelayTime = @"DelayTime";
static NSString * kSDCGImagePropertyAPNGUnclampedDelayTime = @"UnclampedDelayTime";

@implementation SDImageAPNGCoder

+ (void)initialize {
    if (@available(iOS 9, *)) {
        kSDCGImagePropertyAPNGLoopCount = (__bridge NSString *)kCGImagePropertyAPNGLoopCount;
        kSDCGImagePropertyAPNGDelayTime = (__bridge NSString *)kCGImagePropertyAPNGDelayTime;
        kSDCGImagePropertyAPNGUnclampedDelayTime = (__bridge NSString *)kCGImagePropertyAPNGUnclampedDelayTime;
    }
}

+ (instancetype)sharedCoder {
    static SDImageAPNGCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageAPNGCoder alloc] init];
    });
    return coder;
}

#pragma mark - Subclass Override

+ (SDImageFormat)imageFormat {
    return SDImageFormatPNG;
}

+ (NSString *)imageUTType {
    return (__bridge NSString *)kUTTypePNG;
}

+ (NSString *)dictionaryProperty {
    return (__bridge NSString *)kCGImagePropertyPNGDictionary;
}

+ (NSString *)unclampedDelayTimeProperty {
    return kSDCGImagePropertyAPNGUnclampedDelayTime;
}

+ (NSString *)delayTimeProperty {
    return kSDCGImagePropertyAPNGDelayTime;
}

+ (NSString *)loopCountProperty {
    return kSDCGImagePropertyAPNGLoopCount;
}

+ (NSUInteger)defaultLoopCount {
    return 0;
}

@end
