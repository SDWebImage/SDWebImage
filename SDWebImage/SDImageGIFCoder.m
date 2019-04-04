/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageGIFCoder.h"
#import "NSImage+Compatibility.h"
#import "UIImage+Metadata.h"
#import <ImageIO/ImageIO.h>
#import "NSData+ImageContentType.h"
#import "SDImageCoderHelper.h"
#import "SDAnimatedImageRep.h"

@implementation SDImageGIFCoder

- (NSDictionary *)imagePropertyOptions {
    return @{
             SDImageCoderWebImageAnimatedPropertyDictionary: (__bridge NSString *)kCGImagePropertyGIFDictionary,
             SDImageCoderWebImageAnimatedPropertyLoopCount: (__bridge NSString *)kCGImagePropertyGIFLoopCount,
             SDImageCoderWebAnimatedPropertyUnclampedDelayTime: (__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime,
             SDImageCoderWebAnimatedPropertyDelayTime:(__bridge NSString *)kCGImagePropertyGIFDelayTime,
             SDImageCoderWebImageAnimatedFormat: @(SDImageFormatGIF),
             SDImageCoderWebImageAnimatedDefaultLoopCount: @(1)
             };
}

+ (instancetype)sharedCoder {
    static SDImageGIFCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDImageGIFCoder alloc] init];
    });
    return coder;
}

- (instancetype)init {
    if (self = [super initWithOptions:self.imagePropertyOptions]) {
    }
    return self;
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
