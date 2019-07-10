/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import "SDMemoryLRUCache.h"
#import "SDImageCacheConfig.h"
#import "SDInternalMacros.h"
#import "UIImage+MemoryCacheCost.h"
#import <CoreFoundation/CoreFoundation.h>
#import <pthread.h>

static void *SDMemoryLRUCacheContext = &SDMemoryLRUCacheContext;

static inline dispatch_queue_t SDMemoryCacheGetReleaseQueue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}
/**
 * A node in deque map.
 */
@interface SDMemoryCacheMapNode : NSObject {
    @package
    SDMemoryCacheMapNode *_pre;
    SDMemoryCacheMapNode *_next;
    id _key;
    id _val;
    NSUInteger _cost;
}

@end

@implementation SDMemoryCacheMapNode

@end

@interface SDMemoryCacheMap : NSObject {
    @package
    CFMutableDictionaryRef _dic;
    NSUInteger _totalCost;
    NSUInteger _totalCount;
    SDMemoryCacheMapNode *_headNode;
    SDMemoryCacheMapNode *_tailNode;
    BOOL _releaseAsynchronously;
    BOOL _releaseOnMainThread;
}

/**
 * Insert a node at the head of reference dictionary then update the total cost.
 */
- (void)insertAtHeadWithNode:(SDMemoryCacheMapNode *)node;

/**
 * After visited a existed node, bring it to header.
 */
- (void)bringToHeadWithNode:(SDMemoryCacheMapNode *)node;

/**
 * Remove a inner node then update the total cost.
 */
- (void)removeNode:(SDMemoryCacheMapNode *)node;

/**
 * Remove tail node.
 */
- (SDMemoryCacheMapNode *)removeTailNode;

/**
 * Remove all node in reference dictionary.
 */
- (void)removeAll;

@end

@implementation SDMemoryCacheMap

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _releaseAsynchronously = YES;
        _releaseOnMainThread = NO;
    }
    
    return self;
}

- (void)dealloc {
    CFRelease(_dic);
}

- (void)insertAtHeadWithNode:(SDMemoryCacheMapNode *)node {
    CFDictionarySetValue(_dic, (__bridge const void *)(node->_key), (__bridge const void *)(node));
    _totalCost += node->_cost;
    _totalCount++;
    if (!_head) {
        _head = _tail = node;
    } else {
        node->_next = _head;
        _head->_pre = node;
        _head = node;
    }
}

- (void)bringToHeadWithNode:(SDMemoryCacheMapNode *)node {
    if (_head == node) {
        return;
    }
    
    if (_tail == node) {
        _tail = _tail->_pre;
        _tail->_next = nil;
    } else {
        node->_next->_pre = node->_pre;
        node->_pre->_next = node->_next;
    }
    
    node->_next = _head;
    node->_pre = nil;
    _head->_pre = node;
    _head = node;
}

- (void)removeNode:(SDMemoryCacheMapNode *)node {
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(node->_key));
    _totalCost -= node->_cost;
    _totalCount--;
    
    if (node->_next) {
        node->_next->_pre = node->_pre;
    }
    if (node->_pre) {
        node->_pre->_next = node->_next;
    }
    if (_head == node) {
        _head = node->_next;
    }
    if (_tail == node) {
        _tail = node->_pre;
    }
}

- (SDMemoryCacheMapNode *)removeTailNode {
    if (!_tail) {
        return nil;
    }
    
    SDMemoryCacheMapNode *tail = _tail;
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(_tail->_key));
    _totalCost-= _tail->_cost;
    _totalCount--;
    
    if (_head == _tail) {
        _head = _tail = nil;
    } else {
        _tail = tail->_pre;
        _tail->_next = nil;
    }
    
    return tail;
}

- (void)removeAll {
    _totalCost = _totalCount = 0;
    _head = _tail = nil;
    
    if (CFDictionaryGetCount(_dic) > 0) {
        CFMutableDictionaryRef dic = _dic;
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        
        if (_releaseAsynchronously) {
            dispatch_queue_t queue = _releaseOnMainThread ? dispatch_get_main_queue() : SDMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                CFRelease(dic);
            });
        } else if (_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRelease(dic);
            });
        } else {
            CFRelease(dic);
        }
    }
}

@end

@interface SDMemoryLRUCache<KeyType, ObjectType>() {
    pthread_mutex_t _lock;
    SDMemoryCacheMap *_lru;
    dispatch_queue_t _queue;
    NSTimeInterval _autoTrimInterval;
}

@property (strong, nonatomic, nullable) SDImageCacheConfig *config;

@property (assign, nonatomic) NSUInteger totalCostLimit;

@property (assign, nonatomic) NSUInteger countLimit;

@property (nonatomic, strong, nonnull) NSMapTable<KeyType, ObjectType> *weakCache; // strong-weak cache
@property (nonatomic, strong, nonnull) dispatch_semaphore_t weakCacheLock; // a lock to keep the access to `weakCache` thread-safe

@end

@implementation SDMemoryLRUCache 

- (void)dealloc {
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) context:SDMemoryLRUCacheContext];
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) context:SDMemoryLRUCacheContext];
    
    pthread_mutex_destroy(&_lock);
    [_lru removeAll];
    
#if SD_UIKIT
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
#endif
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [[SDImageCacheConfig alloc] init];
        [self commonInit];
    }
    return self;
}


- (instancetype)initWithConfig:(SDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.releaseAsynchronously = true;
    self.releaseOnMainThread = NO;
    self.weakCache = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    self.weakCacheLock = dispatch_semaphore_create(1);
    
    SDImageCacheConfig *config = self.config;
    _totalCostLimit = config.maxMemoryCost == 0 ? NSUIntegerMax : config.maxMemoryCost;
    _countLimit = config.maxMemoryCount == 0 ? NSUIntegerMax : config.maxMemoryCount;

    pthread_mutex_init(&_lock, NULL);
    _lru = [SDMemoryCacheMap new];
    _queue = dispatch_queue_create("com.hackemist.SDImageMemoryLRUCache", DISPATCH_QUEUE_SERIAL);
    // Default auto trim cache interval is 5.0.
    _autoTrimInterval = 5.0;
    
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) options:0 context:SDMemoryLRUCacheContext];
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) options:0 context:SDMemoryLRUCacheContext];
    
#if SD_UIKIT
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
#endif
}

- (void)setReleaseAsynchronously:(BOOL)releaseAsynchronously {
    pthread_mutex_lock(&_lock);
    _lru->_releaseAsynchronously = releaseAsynchronously;
    pthread_mutex_unlock(&_lock);
}

- (BOOL)releaseAsynchronously {
    pthread_mutex_lock(&_lock);
    BOOL releaseAsynchronously = _lru->_releaseAsynchronously;
    pthread_mutex_unlock(&_lock);
    return releaseAsynchronously;
}

- (BOOL)releaseOnMainThread {
    pthread_mutex_lock(&_lock);
    BOOL releaseOnMainThread = _lru->_releaseOnMainThread;
    pthread_mutex_unlock(&_lock);
    return releaseOnMainThread;
}

- (void)setReleaseOnMainThread:(BOOL)releaseOnMainThread {
    pthread_mutex_lock(&_lock);
    _lru->_releaseOnMainThread = releaseOnMainThread;
    pthread_mutex_unlock(&_lock);
}

#if SD_UIKIT
- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self removeAllObjects];
}

- (void)didEnterBackground:(NSNotification *)notification {
    [self removeAllObjects];
}
#endif

- (void)setObject:(nullable id)object forKey:(nonnull id)key {
    [self setObject:object forKey:key cost:0];
}

// `setObject:forKey:` just call this with 0 cost. LRU algorithm memory cache has totalCountLimit && totalCostLimit properties to guarantee it.
- (void)setObject:(nullable id)object forKey:(nonnull id)key cost:(NSUInteger)cost {
    if (!key) {
        return;
    }
    
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    
    pthread_mutex_lock(&_lock);
    SDMemoryCacheMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void*)(key));
    if (node) {
        _lru->_totalCost -= node->_cost;
        _lru->_totalCost += cost;
        node->_cost = cost;
        node->_val = object;
        [_lru bringToHeadWithNode:node];
    } else {
        node = [SDMemoryCacheMapNode new];
        node->_key = key;
        node->_val = object;
        node->_cost = cost;
        [_lru insertAtHeadWithNode:node];
    }
    
    if (_lru->_totalCost > _totalCostLimit) {
        // Shrink the memory caache totalCost until under limit.
        dispatch_async(_queue, ^{
            [self trimCostUnderLimit];
        });
    }
    
    if (_lru->_totalCount > _countLimit) {
        // Only remove the tail node.
        SDMemoryCacheMapNode *tailNode = [_lru removeTailNode];
        if (_lru->_releaseAsynchronously) {
            dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : SDMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                [tailNode class];
            });
        } else if (_lru->_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [tailNode class];
            });
        }
       
    }
    pthread_mutex_unlock(&_lock);
    
    if (!self.config.shouldUseWeakMemoryCache) {
        return;
    }
    if (key && object) {
        // Store weak cache
        SD_LOCK(self.weakCacheLock);
        [self.weakCache setObject:object forKey:key];
        SD_UNLOCK(self.weakCacheLock);
    }
}


- (id)objectForKey:(id)key {
    if (!key) {
        return nil;
    }
    
    pthread_mutex_lock(&_lock);
    SDMemoryCacheMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void *)(key));
    if (node) {
        [_lru bringToHeadWithNode:node];
    }
    pthread_mutex_unlock(&_lock);
    
    id obj = node ? node->_val : nil;
    if (!self.config.shouldUseWeakMemoryCache) {
        return obj;
    }
    if (key && !obj) {
        // Check weak cache
        SD_LOCK(self.weakCacheLock);
        obj = [self.weakCache objectForKey:key];
        SD_UNLOCK(self.weakCacheLock);
        if (obj) {
            // Sync cache
            NSUInteger cost = 0;
            if ([obj isKindOfClass:[UIImage class]]) {
                cost = [(UIImage *)obj sd_memoryCost];
            }
            [self setObject:obj forKey:key cost:cost];
        }
    }
    return obj;
}

- (void)removeObjectForKey:(id)key {
    if (!key) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    SDMemoryCacheMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void*)(key));
    if (node) {
        [_lru removeNode:node];
        if (_lru->_releaseAsynchronously) {
            dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : SDMemoryCacheGetReleaseQueue();
            dispatch_async(queue, ^{
                [node class];
            });
        } else if (_lru->_releaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class];
            });
        }
    }
    pthread_mutex_unlock(&_lock);
    
    if (!self.config.shouldUseWeakMemoryCache) {
        return;
    }
    if (key) {
        // Remove weak cache
        SD_LOCK(self.weakCacheLock);
        [self.weakCache removeObjectForKey:key];
        SD_UNLOCK(self.weakCacheLock);
    }
}

- (void)removeAllObjects {
    pthread_mutex_lock(&_lock);
    [_lru removeAll];
    pthread_mutex_unlock(&_lock);
    
    if (!self.config.shouldUseWeakMemoryCache) {
        return;
    }
    // Manually remove should also remove weak cache
    SD_LOCK(self.weakCacheLock);
    [self.weakCache removeAllObjects];
    SD_UNLOCK(self.weakCacheLock);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == SDMemoryLRUCacheContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCost))]) {
            self.totalCostLimit  = self.config.maxMemoryCost;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCount))]) {
            self.countLimit = self.config.maxMemoryCount;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Trim

- (void)trimRecursively{
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @strongify(self);
        if (!self) {
            return;
        }
        [self trimInBackground];
        [self trimRecursively];
    });
}

- (void)trimInBackground {
    dispatch_async(_queue, ^{
        [self trimCostUnderLimit];
        [self trimCountUnderLimit];
    });
}

- (void)trimCostUnderLimit {
    if (_lru->_totalCost <= _totalCostLimit) {
        return;
    }
    
    BOOL flag = false;
    NSMutableArray <SDMemoryCacheMapNode *> *nodeMArray = [NSMutableArray new];
    
    while (!flag) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru->_totalCost > _totalCostLimit) {
                SDMemoryCacheMapNode *node = [_lru removeTailNode];
                if (node) {
                    [nodeMArray addObject:node];
                }
            } else {
                flag = true;
            }
            pthread_mutex_unlock(&_lock);
        } else {
            usleep(10 * 1000);
        }
    }
    
    if (nodeMArray.count > 0) {
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : SDMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [nodeMArray count];
        });
    }
}

- (void)trimCountUnderLimit {
    if (_lru->_totalCount <= _countLimit) {
        return;
    }
    
    BOOL flag = false;
    NSMutableArray <SDMemoryCacheMapNode *> *nodeMArray = [NSMutableArray new];
    while (!flag) {
        if (pthread_mutex_unlock(&_lock) == 0) {
            if (_lru->_totalCount > _countLimit) {
                SDMemoryCacheMapNode * node = [_lru removeTailNode];
                if (node) {
                    [nodeMArray addObject:node];
                }
            } else {
                flag = true;
            }
        } else {
            usleep(10 * 1000);
        }
    }
    
    if (nodeMArray.count > 0) {
        dispatch_queue_t queue = _lru->_releaseOnMainThread ? dispatch_get_main_queue() : SDMemoryCacheGetReleaseQueue();
        dispatch_async(queue, ^{
            [nodeMArray count];
        });
    }
}

@end
