/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+MemoryCacheCost.h"
#import "objc/runtime.h"

FOUNDATION_STATIC_INLINE NSUInteger SDMemoryCacheCostForImage(UIImage *image) {
#if SD_MAC
    return image.size.height * image.size.width;
#elif SD_UIKIT || SD_WATCH
    NSUInteger imageSize = image.size.height * image.size.width * image.scale * image.scale;
    return image.images ? (imageSize * image.images.count) : imageSize;
#endif
}

@implementation UIImage (MemoryCacheCost)

- (NSUInteger)sd_memoryCost {
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_memoryCost));
    NSUInteger memoryCost;
    if (value != nil) {
        memoryCost = [value unsignedIntegerValue];
    } else {
        memoryCost = SDMemoryCacheCostForImage(self);
    }
    return memoryCost;
}

- (void)setSd_memoryCost:(NSUInteger)sd_memoryCost {
    objc_setAssociatedObject(self, @selector(sd_memoryCost), @(sd_memoryCost), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
