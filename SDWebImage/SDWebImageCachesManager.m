/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCachesManager.h"

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

@implementation SDWebImageCachesManager

+ (SDWebImageCachesManager *)sharedManager {
    static dispatch_once_t onceToken;
    static SDWebImageCachesManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[SDWebImageCachesManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.queryOperationPolicy = SDWebImageCachesManagerOperationPolicyAll;
        self.storeOperationPolicy = SDWebImageCachesManagerOperationPolicyHighest;
        self.removeOperationPolicy = SDWebImageCachesManagerOperationPolicyAll;
        self.clearOperationPolicy = SDWebImageCachesManagerOperationPolicyAll;
    }
    return self;
}

#pragma mark - Cache IO operations

- (void)addCache:(id<SDWebImageCache>)cache {
    if (![cache conformsToProtocol:@protocol(SDWebImageCache)]) {
        return;
    }
    NSMutableArray<id<SDWebImageCache>> *mutableCaches = [self.caches mutableCopy];
    if (!mutableCaches) {
        mutableCaches = [NSMutableArray array];
    }
    [mutableCaches addObject:cache];
    self.caches = [mutableCaches copy];
}

- (void)removeCache:(id<SDWebImageCache>)cache {
    if (![cache conformsToProtocol:@protocol(SDWebImageCache)]) {
        return;
    }
    NSMutableArray<id<SDWebImageCache>> *mutableCaches = [self.caches mutableCopy];
    [mutableCaches removeObject:cache];
    self.caches = [mutableCaches copy];
}

#pragma mark - SDWebImageCache

- (id<SDWebImageOperation>)queryImageForKey:(NSString *)key options:(SDWebImageOptions)options context:(SDWebImageContext *)context completion:(SDImageCacheQueryCompletedBlock)completionBlock {
    if (!key) {
        return nil;
    }
    NSArray<id<SDWebImageCache>> *caches = [self.caches copy];
    NSUInteger count = caches.count;
    if (count == 0) {
        return nil;
    } else if (count == 1) {
        return [caches.firstObject queryImageForKey:key options:options context:context completion:completionBlock];
    }
    switch (self.queryOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighest: {
            id<SDWebImageCache> cache = caches.lastObject;
            return [cache queryImageForKey:key options:options context:context completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowest: {
            id<SDWebImageCache> cache = caches.firstObject;
            return [cache queryImageForKey:key options:options context:context completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyAll: {
            NSOperation *operation = [NSOperation new];
            [self recursiveQueryImageForEnumerator:self.caches.reverseObjectEnumerator operation:operation key:key options:options context:context completion:completionBlock];
            return operation;
        }
            break;
        default:
            return nil;
            break;
    }
}

- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<SDWebImageCache>> *caches = [self.caches copy];
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
    }
    switch (self.storeOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighest: {
            id<SDWebImageCache> cache = caches.lastObject;
            [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowest: {
            id<SDWebImageCache> cache = caches.firstObject;
            [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyAll: {
            dispatch_group_t group = dispatch_group_create();
            for (id<SDWebImageCache> cache in caches.reverseObjectEnumerator) {
                dispatch_group_enter(group);
                [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:^{
                    dispatch_group_leave(group);
                }];
            }
            if (completionBlock) {
                dispatch_group_notify(group, dispatch_get_main_queue(), completionBlock);
            }
        }
            break;
        default:
            break;
    }
}

- (void)removeImageForKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<SDWebImageCache>> *caches = [self.caches copy];
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject removeImageForKey:key cacheType:cacheType completion:completionBlock];
    }
    switch (self.removeOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighest: {
            id<SDWebImageCache> cache = caches.lastObject;
            [cache removeImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowest: {
            id<SDWebImageCache> cache = caches.firstObject;
            [cache removeImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyAll: {
            dispatch_group_t group = dispatch_group_create();
            for (id<SDWebImageCache> cache in caches.reverseObjectEnumerator) {
                dispatch_group_enter(group);
                [cache removeImageForKey:key cacheType:cacheType completion:^{
                    dispatch_group_leave(group);
                }];
            }
            if (completionBlock) {
                dispatch_group_notify(group, dispatch_get_main_queue(), completionBlock);
            }
        }
            break;
        default:
            break;
    }
}

- (void)clearWithCacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock {
    NSArray<id<SDWebImageCache>> *caches = [self.caches copy];
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject clearWithCacheType:cacheType completion:completionBlock];
    }
    switch (self.clearOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighest: {
            id<SDWebImageCache> cache = caches.lastObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowest: {
            id<SDWebImageCache> cache = caches.firstObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyAll: {
            dispatch_group_t group = dispatch_group_create();
            for (id<SDWebImageCache> cache in caches.reverseObjectEnumerator) {
                dispatch_group_enter(group);
                [cache clearWithCacheType:cacheType completion:^{
                    dispatch_group_leave(group);
                }];
            }
            if (completionBlock) {
                dispatch_group_notify(group, dispatch_get_main_queue(), completionBlock);
            }
        }
            break;
        default:
            break;
    }
}

#pragma mark - Util
- (void)recursiveQueryImageForEnumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(NSOperation *)operation key:(NSString *)key options:(SDWebImageOptions)options context:(SDWebImageContext *)context completion:(SDImageCacheQueryCompletedBlock)completionBlock {
    if (operation.isCancelled) {
        return;
    }
    id<SDWebImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Failed
        if (completionBlock) {
            completionBlock(nil, nil, SDImageCacheTypeNone);
        }
        return;
    }
    __weak typeof(self) wself = self;
    [cache queryImageForKey:key options:options context:context completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (image) {
            // Finished
            if (completionBlock) {
                completionBlock(image, data, cacheType);
            }
            return;
        }
        // Next
        [wself recursiveQueryImageForEnumerator:enumerator operation:operation key:key options:options context:context completion:completionBlock];
    }];
}

@end
