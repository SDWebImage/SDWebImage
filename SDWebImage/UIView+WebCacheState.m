/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheState.h"
#import "objc/runtime.h"

SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerURL = @"url";
SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerProgress = @"progress";
SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerTransition = @"transition";

static char loadStateKey;
typedef NSMapTable<NSString *, SDWebImageStateContainer *> SDStateContainerTable;

@implementation UIView (WebCacheState)

- (SDStateContainerTable *)sd_imageLoadStateTable {
    SDStateContainerTable *states = objc_getAssociatedObject(self, &loadStateKey);
    if (!states) {
        states = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        objc_setAssociatedObject(self, &loadStateKey, states, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return states;
}

- (SDWebImageStateContainer *)sd_imageLoadStateForKey:(NSString *)key {
    if (!key) {
        key = NSStringFromClass(self.class);
    }
    return [self.sd_imageLoadStateTable objectForKey:key];
}

- (void)sd_setImageLoadState:(SDWebImageStateContainer *)state forKey:(NSString *)key {
    if (!key) {
        key = NSStringFromClass(self.class);
    }
    [self.sd_imageLoadStateTable setObject:state forKey:key];
}

- (void)sd_removeImageLoadStateForKey:(NSString *)key {
    if (!key) {
        key = NSStringFromClass(self.class);
    }
    [self.sd_imageLoadStateTable removeObjectForKey:key];
}

@end
