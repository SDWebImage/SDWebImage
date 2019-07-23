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

@implementation UIImage (ForceDecode)

- (BOOL)sd_isDecoded {
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_isDecoded));
    return value.boolValue;
}

- (void)setSd_isDecoded:(BOOL)sd_isDecoded {
    objc_setAssociatedObject(self, @selector(sd_isDecoded), @(sd_isDecoded), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (UIImage *)sd_decodedImageWithImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    return [SDImageCoderHelper decodedImageWithImage:image];
}

+ (UIImage *)sd_decodedAndScaledDownImageWithImage:(UIImage *)image {
    return [self sd_decodedAndScaledDownImageWithImage:image limitBytes:0];
}

+ (UIImage *)sd_decodedAndScaledDownImageWithImage:(UIImage *)image limitBytes:(NSUInteger)bytes {
    if (!image) {
        return nil;
    }
    return [SDImageCoderHelper decodedAndScaledDownImageWithImage:image limitBytes:bytes];
}

@end
