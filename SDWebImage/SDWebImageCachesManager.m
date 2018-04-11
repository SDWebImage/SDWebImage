/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCachesManager.h"

// This is used for operation management, but not for operation queue execute
@interface SDWebImageCachesManagerOperation : NSOperation

@property (nonatomic, assign, readonly) NSUInteger pendingCount;

- (void)beginWithTotalCount:(NSUInteger)totalCount;
- (void)completeOne;
- (void)done;

@end

@implementation SDWebImageCachesManagerOperation

@synthesize executing = _executing;
@synthesize finished = _finished;
@synthesize cancelled = _cancelled;

- (void)beginWithTotalCount:(NSUInteger)totalCount {
    self.executing = YES;
    self.finished = NO;
    _pendingCount = totalCount;
}

- (void)completeOne {
    _pendingCount = _pendingCount > 0 ? _pendingCount - 1 : 0;
}

- (void)cancel {
    self.cancelled = YES;
    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    _pendingCount = 0;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setCancelled:(BOOL)cancelled {
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
}

@end

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
        self.queryOperationPolicy = SDWebImageCachesManagerOperationPolicySerial;
        self.storeOperationPolicy = SDWebImageCachesManagerOperationPolicyHighestOnly;
        self.removeOperationPolicy = SDWebImageCachesManagerOperationPolicyConcurrent;
        self.containsOperationPolicy = SDWebImageCachesManagerOperationPolicySerial;
        self.clearOperationPolicy = SDWebImageCachesManagerOperationPolicyConcurrent;
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

- (id<SDWebImageOperation>)queryImageForKey:(NSString *)key options:(SDWebImageOptions)options context:(SDWebImageContext *)context completion:(SDImageCacheQueryCompletionBlock)completionBlock {
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
        case SDWebImageCachesManagerOperationPolicyHighestOnly: {
            id<SDWebImageCache> cache = caches.lastObject;
            return [cache queryImageForKey:key options:options context:context completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowestOnly: {
            id<SDWebImageCache> cache = caches.firstObject;
            return [cache queryImageForKey:key options:options context:context completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyConcurrent: {
            SDWebImageCachesManagerOperation *operation = [SDWebImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentQueryImageForKey:key options:options context:context completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
            return operation;
        }
            break;
        case SDWebImageCachesManagerOperationPolicySerial: {
            SDWebImageCachesManagerOperation *operation = [SDWebImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self serialQueryImageForKey:key options:options context:context completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
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
        return;
    }
    switch (self.storeOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighestOnly: {
            id<SDWebImageCache> cache = caches.lastObject;
            [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowestOnly: {
            id<SDWebImageCache> cache = caches.firstObject;
            [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyConcurrent: {
            SDWebImageCachesManagerOperation *operation = [SDWebImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentStoreImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case SDWebImageCachesManagerOperationPolicySerial: {
            [self serialStoreImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
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
        return;
    }
    switch (self.removeOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighestOnly: {
            id<SDWebImageCache> cache = caches.lastObject;
            [cache removeImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowestOnly: {
            id<SDWebImageCache> cache = caches.firstObject;
            [cache removeImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyConcurrent: {
            SDWebImageCachesManagerOperation *operation = [SDWebImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentRemoveImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case SDWebImageCachesManagerOperationPolicySerial: {
            [self serialRemoveImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}

- (void)containsImageForKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDImageCacheContainsCompletionBlock)completionBlock {
    if (!key) {
        return;
    }
    NSArray<id<SDWebImageCache>> *caches = [self.caches copy];
    NSUInteger count = caches.count;
    if (count == 0) {
        return;
    } else if (count == 1) {
        [caches.firstObject containsImageForKey:key cacheType:cacheType completion:completionBlock];
        return;
    }
    switch (self.clearOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighestOnly: {
            id<SDWebImageCache> cache = caches.lastObject;
            [cache containsImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowestOnly: {
            id<SDWebImageCache> cache = caches.firstObject;
            [cache containsImageForKey:key cacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyConcurrent: {
            SDWebImageCachesManagerOperation *operation = [SDWebImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentContainsImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case SDWebImageCachesManagerOperationPolicySerial: {
            SDWebImageCachesManagerOperation *operation = [SDWebImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self serialContainsImageForKey:key cacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
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
        return;
    }
    switch (self.clearOperationPolicy) {
        case SDWebImageCachesManagerOperationPolicyHighestOnly: {
            id<SDWebImageCache> cache = caches.lastObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyLowestOnly: {
            id<SDWebImageCache> cache = caches.firstObject;
            [cache clearWithCacheType:cacheType completion:completionBlock];
        }
            break;
        case SDWebImageCachesManagerOperationPolicyConcurrent: {
            SDWebImageCachesManagerOperation *operation = [SDWebImageCachesManagerOperation new];
            [operation beginWithTotalCount:caches.count];
            [self concurrentClearWithCacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator operation:operation];
        }
            break;
        case SDWebImageCachesManagerOperationPolicySerial: {
            [self serialClearWithCacheType:cacheType completion:completionBlock enumerator:caches.reverseObjectEnumerator];
        }
            break;
        default:
            break;
    }
}

#pragma mark - Concurrent Operation

- (void)concurrentQueryImageForKey:(NSString *)key options:(SDWebImageOptions)options context:(SDWebImageContext *)context completion:(SDImageCacheQueryCompletionBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(SDWebImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<SDWebImageCache> cache in enumerator) {
        [cache queryImageForKey:key options:options context:context completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (image) {
                // Success
                [operation done];
                if (completionBlock) {
                    completionBlock(image, data, cacheType);
                }
                return;
            }
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock(nil, nil, SDImageCacheTypeNone);
                }
            }
        }];
    }
}

- (void)concurrentStoreImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(SDWebImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<SDWebImageCache> cache in enumerator) {
        [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:^{
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

- (void)concurrentRemoveImageForKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(SDWebImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<SDWebImageCache> cache in enumerator) {
        [cache removeImageForKey:key cacheType:cacheType completion:^{
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

- (void)concurrentContainsImageForKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDImageCacheContainsCompletionBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(SDWebImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<SDWebImageCache> cache in enumerator) {
        [cache containsImageForKey:key cacheType:cacheType completion:^(SDImageCacheType containsCacheType) {
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (containsCacheType != SDImageCacheTypeNone) {
                // Success
                [operation done];
                if (completionBlock) {
                    completionBlock(containsCacheType);
                }
                return;
            }
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock(SDImageCacheTypeNone);
                }
            }
        }];
    }
}

- (void)concurrentClearWithCacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(SDWebImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    for (id<SDWebImageCache> cache in enumerator) {
        [cache clearWithCacheType:cacheType completion:^{
            if (operation.isCancelled) {
                // Cancelled
                return;
            }
            if (operation.isFinished) {
                // Finished
                return;
            }
            [operation completeOne];
            if (operation.pendingCount == 0) {
                // Complete
                [operation done];
                if (completionBlock) {
                    completionBlock();
                }
            }
        }];
    }
}

#pragma mark - Serial Operation

- (void)serialQueryImageForKey:(NSString *)key options:(SDWebImageOptions)options context:(SDWebImageContext *)context completion:(SDImageCacheQueryCompletionBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(SDWebImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    id<SDWebImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        [operation done];
        if (completionBlock) {
            completionBlock(nil, nil, SDImageCacheTypeNone);
        }
        return;
    }
    __weak typeof(self) wself = self;
    [cache queryImageForKey:key options:options context:context completion:^(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType) {
        if (operation.isCancelled) {
            // Cancelled
            return;
        }
        if (operation.isFinished) {
            // Finished
            return;
        }
        [operation completeOne];
        if (image) {
            // Success
            [operation done];
            if (completionBlock) {
                completionBlock(image, data, cacheType);
            }
            return;
        }
        // Next
        [wself serialQueryImageForKey:key options:options context:context completion:completionBlock enumerator:enumerator operation:operation];
    }];
}

- (void)serialStoreImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator {
    NSParameterAssert(enumerator);
    id<SDWebImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    __weak typeof(self) wself = self;
    [cache storeImage:image imageData:imageData forKey:key cacheType:cacheType completion:^{
        // Next
        [wself serialStoreImage:image imageData:imageData forKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

- (void)serialRemoveImageForKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator {
    NSParameterAssert(enumerator);
    id<SDWebImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    __weak typeof(self) wself = self;
    [cache removeImageForKey:key cacheType:cacheType completion:^{
        // Next
        [wself serialRemoveImageForKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

- (void)serialContainsImageForKey:(NSString *)key cacheType:(SDImageCacheType)cacheType completion:(SDImageCacheContainsCompletionBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator operation:(SDWebImageCachesManagerOperation *)operation {
    NSParameterAssert(enumerator);
    NSParameterAssert(operation);
    id<SDWebImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        [operation done];
        if (completionBlock) {
            completionBlock(SDImageCacheTypeNone);
        }
        return;
    }
    __weak typeof(self) wself = self;
    [cache containsImageForKey:key cacheType:cacheType completion:^(SDImageCacheType containsCacheType) {
        if (operation.isCancelled) {
            // Cancelled
            return;
        }
        if (operation.isFinished) {
            // Finished
            return;
        }
        [operation completeOne];
        if (containsCacheType != SDImageCacheTypeNone) {
            // Success
            [operation done];
            if (completionBlock) {
                completionBlock(containsCacheType);
            }
            return;
        }
        // Next
        [wself serialContainsImageForKey:key cacheType:cacheType completion:completionBlock enumerator:enumerator operation:operation];
    }];
}

- (void)serialClearWithCacheType:(SDImageCacheType)cacheType completion:(SDWebImageNoParamsBlock)completionBlock enumerator:(NSEnumerator<id<SDWebImageCache>> *)enumerator {
    NSParameterAssert(enumerator);
    id<SDWebImageCache> cache = enumerator.nextObject;
    if (!cache) {
        // Complete
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    __weak typeof(self) wself = self;
    [cache clearWithCacheType:cacheType completion:^{
        // Next
        [wself serialClearWithCacheType:cacheType completion:completionBlock enumerator:enumerator];
    }];
}

@end
