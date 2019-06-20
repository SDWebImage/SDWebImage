//
//  SDMemoryLRUCache.m
//  SDWebImage
//
//  Created by Haixiao Xu on 2019/6/18.
//  Copyright © 2019 Dailymotion. All rights reserved.
//

#import "SDMemoryLRUCache.h"
#import "SDImageCacheConfig.h"
#import "SDInternalMacros.h"
#import <CoreFoundation/CoreFoundation.h>
#import <pthread.h>

static void * SDMemoryCacheContext = &SDMemoryCacheContext;

static inline dispatch_queue_t SDMemoryCacheGetReleaseQueue() {
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

/**
 * A node in deque map.
 */
@interface SDMemoryCacheMapNode : NSObject {
    @package
    __unsafe_unretained SDMemoryCacheMapNode *_pre;
    __unsafe_unretained SDMemoryCacheMapNode *_next;
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
    SDMemoryCacheMapNode *_head;
    SDMemoryCacheMapNode *_tail;
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
        dispatch_async(SDMemoryCacheGetReleaseQueue(), ^{
            CFRelease(dic);
        });
    }
}

@end

@interface SDMemoryLRUCache() {
    pthread_mutex_t _lock;
    SDMemoryCacheMap *_lru;
    dispatch_queue_t _queue;
    NSTimeInterval _autoTrimInterval;
}

@property (strong, nonatomic, nullable) SDImageCacheConfig *config;
@property (assign, nonatomic) NSUInteger maxMemoryCostLimit;
@property (assign, nonatomic) NSUInteger maxMemoryCountLimit;

@end

@implementation SDMemoryLRUCache 

- (void)dealloc {
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) context:SDMemoryCacheContext];
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) context:SDMemoryCacheContext];
    
#if SD_UIKIT
    [_lru removeAll];
    pthread_mutex_destroy(&_lock);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
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
    
    SDImageCacheConfig *config = self.config;
    _maxMemoryCountLimit = config.maxMemoryCount;
    _maxMemoryCostLimit = config.maxMemoryCost;
    
    pthread_mutex_init(&_lock, NULL);
    _lru = [SDMemoryCacheMap new];
    _queue = dispatch_queue_create("com.hackemist.SDImageMemoryCache", DISPATCH_QUEUE_SERIAL);
    // Default auto trim cache interval is 5.0.
    _autoTrimInterval = 5.0;
    
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) options:0 context:SDMemoryCacheContext];
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) options:0 context:SDMemoryCacheContext];
    
#if SD_UIKIT
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}


// Current this seems no use on macOS (macOS use virtual memory and do not clear cache when memory warning). So we only override on iOS/tvOS platform.
#if SD_UIKIT

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self removeAllObjects];
}
#endif

- (void)didEnterBackground:(NSNotification *)notification {
    [self removeAllObjects];
}


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
    
    
    if (_lru->_totalCost > _maxMemoryCostLimit) {
        // Shrink the memory caache totalCost until under limit.
        dispatch_async(_queue, ^{
            [self trimCostUnderLimit];
        });
    }
    
    if (_lru->_totalCount > _maxMemoryCountLimit) {
        // Only remove the tail node.
        SDMemoryCacheMapNode *tailNode = [_lru removeTailNode];
        dispatch_async(SDMemoryCacheGetReleaseQueue(), ^{
            [tailNode class];
        });
    }
    pthread_mutex_unlock(&_lock);
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
    
    return node ? node->_val : nil;
}

- (void)removeObjectForKey:(id)key {
    
    if (!key) {
        return;
    }
    
    pthread_mutex_lock(&_lock);
    SDMemoryCacheMapNode *node = CFDictionaryGetValue(_lru->_dic, (__bridge const void*)(key));
    if (node) {
        [_lru removeNode:node];
        dispatch_async(SDMemoryCacheGetReleaseQueue(), ^{
            [node class];
        });
    }
    pthread_mutex_unlock(&_lock);
}

- (void)removeAllObjects {
    
    pthread_mutex_lock(&_lock);
    [_lru removeAll];
    pthread_mutex_unlock(&_lock);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == SDMemoryCacheContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCost))]) {
            self.maxMemoryCostLimit = self.config.maxMemoryCost;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCount))]) {
            self.maxMemoryCountLimit = self.config.maxMemoryCount;
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
    if (_lru->_totalCost <= _maxMemoryCostLimit) {
        return;
    }
    
    BOOL flag = false;
    NSMutableArray <SDMemoryCacheMapNode *> *nodeMArray = [NSMutableArray new];
    
    while (!flag) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (_lru->_totalCost > _maxMemoryCostLimit) {
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
        dispatch_async(SDMemoryCacheGetReleaseQueue(), ^{
            // Async release in global queue
            [nodeMArray count];
        });
    }
}

- (void)trimCountUnderLimit {
    if (_lru->_totalCount <= _maxMemoryCountLimit) {
        return;
    }
    
    BOOL flag = false;
    NSMutableArray <SDMemoryCacheMapNode *> *nodeMArray = [NSMutableArray new];
    while (!flag) {
        if (pthread_mutex_unlock(&_lock) == 0) {
            if (_lru->_totalCount > _maxMemoryCountLimit) {
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
        dispatch_async(SDMemoryCacheGetReleaseQueue(), ^{
            [nodeMArray count];
        });
    }
}

@end
