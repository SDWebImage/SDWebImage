/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+CacheMemoryCost.h"
#import "objc/runtime.h"

FOUNDATION_STATIC_INLINE NSUInteger SDCacheCostForImage(UIImage *image) {
#if SD_MAC
    return image.size.height * image.size.width;
#elif SD_UIKIT || SD_WATCH
    NSUInteger imageSize = image.size.height * image.size.width * image.scale * image.scale;
    return image.images ? (imageSize * image.images.count) : imageSize;
#endif
}

@implementation UIImage (CacheMemoryCost)

- (NSUInteger)sd_memoryCost {
    NSNumber *memoryCost = objc_getAssociatedObject(self, _cmd);
    if (memoryCost == nil) {
        memoryCost = @(SDCacheCostForImage(self));
    }
    return [memoryCost unsignedIntegerValue];
}

- (void)setSd_memoryCost:(NSUInteger)sd_memoryCost {
    objc_setAssociatedObject(self, @selector(sd_memoryCost), @(sd_memoryCost), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
