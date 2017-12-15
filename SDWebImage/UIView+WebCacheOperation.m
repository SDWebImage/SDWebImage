/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheOperation.h"

#if SD_UIKIT || SD_MAC

#import "objc/runtime.h"
#import "pthread.h"

#define LOCKED(...) pthread_mutex_lock(&_lock); \
__VA_ARGS__; \
pthread_mutex_unlock(&_lock);

static char loadOperationKey;

// A NSMutableDictionary subclass which basic operation is thread-safe, NSFastEnumeration is not thread-safe
@interface SDThreadSafeMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@implementation SDThreadSafeMutableDictionary {
    pthread_mutex_t _lock;
    NSMutableDictionary *_dictionary; // NSMutableDictionary is class cluster, you should override all primitive methods from Apple's doc
}

- (instancetype)init {
    if ((self = [super init])) {
        _dictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems {
    if ((self = [super init])) {
        _dictionary = [[NSMutableDictionary alloc] initWithCapacity:numItems];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (instancetype)initWithObjects:(NSArray *)objects forKeys:(NSArray<id<NSCopying>> *)keys {
    if ((self = [self initWithCapacity:objects.count])) {
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            _dictionary[keys[idx]] = obj;
        }];
    }
    return self;
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    LOCKED([_dictionary setObject:anObject forKey:aKey])
}

- (void)removeObjectForKey:(id)aKey {
    LOCKED([_dictionary removeObjectForKey:aKey])
}

- (NSUInteger)count {
    LOCKED(NSUInteger count = _dictionary.count)
    return count;
}

- (id)objectForKey:(id)aKey {
    LOCKED(id obj = [_dictionary objectForKey:aKey])
    return obj;
}

- (NSEnumerator *)keyEnumerator {
    LOCKED(NSEnumerator *keyEnumerator = [_dictionary keyEnumerator])
    return keyEnumerator;
}

- (id)copyWithZone:(NSZone *)zone {
    LOCKED(id copiedDictionary = [[NSDictionary allocWithZone:zone] initWithDictionary:_dictionary])
    return copiedDictionary;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    LOCKED(id copiedDictionary = [[self.class allocWithZone:zone] initWithDictionary:_dictionary])
    return copiedDictionary;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len {
    LOCKED(NSUInteger count = [[_dictionary copy] countByEnumeratingWithState:state objects:buffer count:len])
    return count;
}

@end

typedef SDThreadSafeMutableDictionary<NSString *, id> SDOperationsDictionary;

@implementation UIView (WebCacheOperation)

- (SDOperationsDictionary *)operationDictionary {
    @synchronized(self) {
        SDOperationsDictionary *operations = objc_getAssociatedObject(self, &loadOperationKey);
        if (operations) {
            return operations;
        }
        operations = [SDThreadSafeMutableDictionary dictionary];
        objc_setAssociatedObject(self, &loadOperationKey, operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operations;
    }
}

- (void)sd_setImageLoadOperation:(nullable id)operation forKey:(nullable NSString *)key {
    if (key) {
        [self sd_cancelImageLoadOperationWithKey:key];
        if (operation) {
            SDOperationsDictionary *operationDictionary = [self operationDictionary];
            operationDictionary[key] = operation;
        }
    }
}

- (void)sd_cancelImageLoadOperationWithKey:(nullable NSString *)key {
    // Cancel in progress downloader from queue
    SDOperationsDictionary *operationDictionary = [self operationDictionary];
    id operations = operationDictionary[key];
    if (operations) {
        if ([operations isKindOfClass:[NSArray class]]) {
            for (id <SDWebImageOperation> operation in operations) {
                if (operation) {
                    [operation cancel];
                }
            }
        } else if ([operations conformsToProtocol:@protocol(SDWebImageOperation)]){
            [(id<SDWebImageOperation>) operations cancel];
        }
        [operationDictionary removeObjectForKey:key];
    }
}

- (void)sd_removeImageLoadOperationWithKey:(nullable NSString *)key {
    if (key) {
        SDOperationsDictionary *operationDictionary = [self operationDictionary];
        [operationDictionary removeObjectForKey:key];
    }
}

@end

#endif
