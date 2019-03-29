/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDMemoryCache.h"
#import "SDImageCacheConfig.h"
#import "UIImage+MemoryCacheCost.h"
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
    /**
     * Auto check and trim cache cost time interval, default is 5.0.
     */
    NSTimeInterval _time;
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

@interface SDMemoryCache ()

@property (nonatomic, strong, nullable) SDImageCacheConfig *config;

@property (nonatomic, strong, nonnull) dispatch_semaphore_t weakCacheLock; // a lock to keep the access to `weakCache` thread-safe

@end

@implementation SDMemoryCache

- (void)dealloc {
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) context:SDMemoryCacheContext];
    [_config removeObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) context:SDMemoryCacheContext];
#if SD_UIKIT
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

    
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCost)) options:0 context:SDMemoryCacheContext];
    [config addObserver:self forKeyPath:NSStringFromSelector(@selector(maxMemoryCount)) options:0 context:SDMemoryCacheContext];
    
#if SD_UIKIT
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
#endif
}

// Current this seems no use on macOS (macOS use virtual memory and do not clear cache when memory warning). So we only override on iOS/tvOS platform.
#if SD_UIKIT
- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    // Only remove cache, but keep weak cache
}

// `setObject:forKey:` just call this with 0 cost. Override this is enough
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    
}

- (id)objectForKey:(id)key {
    
    return nil;
}

- (void)removeObjectForKey:(id)key {
   
}

- (void)removeAllObjects {
    
}

- (void)setObject:(nullable id)object forKey:(nonnull id)key {
    
}

#endif

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == SDMemoryCacheContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCost))]) {
           
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(maxMemoryCount))]) {
            
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
