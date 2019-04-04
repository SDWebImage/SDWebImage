/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageAPNGCoder.h"
#import <ImageIO/ImageIO.h>
#import "NSData+ImageContentType.h"
#import "UIImage+Metadata.h"
#import "NSImage+Compatibility.h"
#import "SDImageCoderHelper.h"
#import "SDAnimatedImageRep.h"

// iOS 8 Image/IO framework binary does not contains these APNG contants, so we define them. Thanks Apple :)
#if (__IPHONE_OS_VERSION_MIN_REQUIRED && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_9_0)
const CFStringRef kCGImagePropertyAPNGLoopCount = (__bridge CFStringRef)@"LoopCount";
const CFStringRef kCGImagePropertyAPNGDelayTime = (__bridge CFStringRef)@"DelayTime";
const CFStringRef kCGImagePropertyAPNGUnclampedDelayTime = (__bridge CFStringRef)@"UnclampedDelayTime";
#endif

@implementation SDImageAPNGCoder

+ (instancetype)sharedCoder {
    static SDImageAPNGCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageAPNGCoder alloc] init];
    });
    return coder;
}

- (instancetype)init {
    if (self = [super initWithOptions:self.imagePropertyOptions]) {
    }
    return self;
}

- (NSDictionary *)imagePropertyOptions {
    return @{
             SDImageCoderWebImageAnimatedPropertyDictionary: (__bridge NSString *)kCGImagePropertyPNGDictionary,
             SDImageCoderWebImageAnimatedPropertyLoopCount: (__bridge NSString *)kCGImagePropertyAPNGLoopCount,
             SDImageCoderWebAnimatedPropertyUnclampedDelayTime: (__bridge NSString *)kCGImagePropertyAPNGUnclampedDelayTime,
             SDImageCoderWebAnimatedPropertyDelayTime:(__bridge NSString *)kCGImagePropertyAPNGDelayTime,
             SDImageCoderWebImageAnimatedFormat: @(SDImageFormatPNG),
             SDImageCoderWebImageAnimatedDefaultLoopCount: @(0)
             };
}

- (instancetype)initIncrementalWithOptions:(SDImageCoderOptions *)options {
    SDImageCoderMutableOptions *mutableOptions = [options ?: @{} mutableCopy];
    [mutableOptions addEntriesFromDictionary:self.imagePropertyOptions];
    if (self = [super initIncrementalWithOptions:[mutableOptions copy]]) {
    }
    return self;
}

- (instancetype)initWithAnimatedImageData:(NSData *)data options:(SDImageCoderOptions *)options {
    SDImageCoderMutableOptions *mutableOptions = [options ?: @{} mutableCopy];
    [mutableOptions addEntriesFromDictionary:self.imagePropertyOptions];
    if (self = [super initWithAnimatedImageData:data options:[mutableOptions copy]]) {
    }
    return self;
}

@end
