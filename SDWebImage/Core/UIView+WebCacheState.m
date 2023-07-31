/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheState.h"
#import "objc/runtime.h"

typedef NSMutableDictionary<NSString *, SDWebImageLoadState *> SDStatesDictionary;

@implementation SDWebImageLoadState

@end

@implementation UIView (WebCacheState)

- (SDStatesDictionary *)sd_imageLoadStateDictionary {
    SDStatesDictionary *states = objc_getAssociatedObject(self, @selector(sd_imageLoadStateDictionary));
    if (!states) {
        states = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @selector(sd_imageLoadStateDictionary), states, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return states;
}

- (SDWebImageLoadState *)sd_imageLoadStateForKey:(NSString *)key {
    if (!key) {
        key = NSStringFromClass(self.class);
    }
    @synchronized(self) {
        return [self.sd_imageLoadStateDictionary objectForKey:key];
    }
}

- (void)sd_setImageLoadState:(SDWebImageLoadState *)state forKey:(NSString *)key {
    if (!key) {
        key = NSStringFromClass(self.class);
    }
    @synchronized(self) {
        self.sd_imageLoadStateDictionary[key] = state;
    }
}

- (void)sd_removeImageLoadStateForKey:(NSString *)key {
    if (!key) {
        key = NSStringFromClass(self.class);
    }
    @synchronized(self) {
        self.sd_imageLoadStateDictionary[key] = nil;
    }
}

@end
