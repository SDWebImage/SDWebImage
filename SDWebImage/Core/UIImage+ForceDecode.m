/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+ForceDecode.h"
#import "SDImageCoderHelper.h"
#import "objc/runtime.h"
#import "NSImage+Compatibility.h"

@implementation UIImage (ForceDecode)

- (BOOL)sd_isDecoded {
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_isDecoded));
    if (value != nil) {
        return value.boolValue;
    } else {
        // Assume only CGImage based can use lazy decoding
        CGImageRef cgImage = self.CGImage;
        if (cgImage) {
            CFStringRef uttype = CGImageGetUTType(self.CGImage);
            if (uttype) {
                // Only ImageIO can set `com.apple.ImageIO.imageSourceTypeIdentifier`
                return NO;
            } else {
                // Thumbnail or CGBitmapContext drawn image
                return YES;
            }
        }
    }
    // Assume others as non-decoded
    return NO;
}

- (void)setSd_isDecoded:(BOOL)sd_isDecoded {
    objc_setAssociatedObject(self, @selector(sd_isDecoded), @(sd_isDecoded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (nullable UIImage *)sd_decodedImageWithImage:(nullable UIImage *)image {
    if (!image) {
        return nil;
    }
    return [SDImageCoderHelper decodedImageWithImage:image];
}

+ (nullable UIImage *)sd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image {
    return [self sd_decodedAndScaledDownImageWithImage:image limitBytes:0];
}

+ (nullable UIImage *)sd_decodedAndScaledDownImageWithImage:(nullable UIImage *)image limitBytes:(NSUInteger)bytes {
    if (!image) {
        return nil;
    }
    return [SDImageCoderHelper decodedAndScaledDownImageWithImage:image limitBytes:bytes];
}

@end
