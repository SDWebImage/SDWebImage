/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheOperation.h"
#import "objc/runtime.h"

static char loadOperationKey;

// key is copy, value is weak because operation instance is retained by SDWebImageManager's runningOperations property
// we should use lock to keep thread-safe because these method may not be acessed from main queue
typedef NSMapTable<NSString *, id<SDWebImageOperation>> SDOperationsDictionary;

@implementation UIView (WebCacheOperation)

- (SDOperationsDictionary *)sd_operationDictionary {
    @synchronized(self) {
        SDOperationsDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
        if (operations) {
            return operations;
        }
        operations = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operations;
    }
}

- (void)sd_setImageLoadOperation:(nullable id<SDWebImageOperation>)operation forKey:(nullable NSString *)key {
    if (key) {
        [self sd_cancelImageLoadOperationWithKey:key];
        if (operation) {
            SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
            @synchronized (self) {
                [operationDictionary setObject:operation forKey:key];
            }
        }
    }
}

- (void)sd_cancelImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        // Cancel in progress downloader from queue
        SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
        id<SDWebImageOperation> operation;
        
        @synchronized (self) {
            operation = [operationDictionary objectForKey:key];
        }
        if (operation) {
            if ([operation conformsToProtocol:@protocol(SDWebImageOperation)]) {
                [operation cancel];
            }
            @synchronized (self) {
                [operationDictionary removeObjectForKey:key];
                // Also remove pair of image url and operation key
                [self sd_imageURLOperationDictionary][key] = nil;
            }
        }
    }
}

- (void)sd_cancelAllImageLoadOperations {
    NSDictionary<NSString *, id<SDWebImageOperation>> *operationDictionary = nil;
    @synchronized (self) {
         operationDictionary = [[self sd_operationDictionary] dictionaryRepresentation];
    }
    
    for (NSString *key in operationDictionary.allKeys) {
        [self sd_cancelImageLoadOperationWithKey:key];
    }
}

- (void)sd_removeImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
        @synchronized (self) {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

- (NSMutableDictionary<NSString *, NSURL *> *)sd_imageURLOperationDictionary {
    @synchronized(self) {
        NSMutableDictionary<NSString *, NSURL *> *imageURLOperationDictionay = objc_getAssociatedObject(self, _cmd);
        if (!imageURLOperationDictionay) {
            imageURLOperationDictionay = [NSMutableDictionary dictionary];
            objc_setAssociatedObject(self, _cmd, imageURLOperationDictionay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return imageURLOperationDictionay;
    }
}

- (void)sd_setImageURL:(NSURL *)url forOperationKey:(NSString *)operationKey {
    if (operationKey) {
        @synchronized (self) {
            [self sd_imageURLOperationDictionary][operationKey] = url;
        }
    }
}

- (NSURL *)sd_getImageURLWithOperationKey:(nullable NSString *)operationKey {
    if (operationKey) {
        @synchronized (self) {
            return [self sd_imageURLOperationDictionary][operationKey];
        }
    }
    return nil;
}

@end
