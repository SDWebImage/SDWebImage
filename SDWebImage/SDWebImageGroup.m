/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageGroup.h"
#import <stdatomic.h>

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

typedef void(^SDWebImageGroupNotifyBlock)(dispatch_block_t block);

@interface SDWebImageGroup () {
    atomic_ulong _counter;
}

@property (nonatomic, strong) dispatch_queue_t notifyQueue;
@property (nonatomic, assign) BOOL isAsync;
@property (nonatomic, strong) dispatch_semaphore_t notifyBlocksLock;
@property (nonatomic, strong) NSMutableArray<dispatch_block_t> *notifyBlockArray;

@end

@implementation SDWebImageGroup

- (instancetype)init {
    return [self initWithNotifyQueue:dispatch_get_main_queue() isAsync:NO];
}

- (instancetype)initWithNotifyQueue:(dispatch_queue_t)queue isAsync:(BOOL)isAsync {
    if (self = [super init]) {
        _counter = 0;
        _notifyQueue = queue;
        _isAsync = isAsync;
        _notifyBlocksLock = dispatch_semaphore_create(1);
        _notifyBlockArray = [NSMutableArray array];
    }
    return self;
}

- (void)enter {
    atomic_fetch_add_explicit(&(_counter), 1, memory_order_acquire);
}

- (void)leave {
    unsigned long value = atomic_fetch_sub_explicit(&(_counter), 1, memory_order_release);
    
    if (value == 1) {
        [self notify];
    }
}

- (void)addNotifyWithBlock:(dispatch_block_t)block {
    if (!block) { return; }
    
    LOCK(self.notifyBlocksLock);
    [self.notifyBlockArray addObject:block];
    UNLOCK(self.notifyBlocksLock);
    
    unsigned long value = atomic_load_explicit(&(_counter), memory_order_seq_cst);
    if (value == 0) {
        [self notify];
    }
}

- (void)notify {
    LOCK(self.notifyBlocksLock);
    NSArray<dispatch_block_t> *blockArray = [self.notifyBlockArray copy];
    [self.notifyBlockArray removeAllObjects];
    UNLOCK(self.notifyBlocksLock);
    
    if (blockArray.count == 0) { return; }
    
    const char *mainQueueLabel = dispatch_queue_get_label(dispatch_get_main_queue());
    
    SDWebImageGroupNotifyBlock notifyBlock = ^(dispatch_block_t block) {
        if (dispatch_queue_get_label(self.notifyQueue) == mainQueueLabel && dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == mainQueueLabel) {
            block();
        } else {
            dispatch_sync(self.notifyQueue, block);
        }
    };
    
    if (self.isAsync) {
        notifyBlock = ^(dispatch_block_t block) {
            dispatch_async(self.notifyQueue, block);
        };
    }
    
    [blockArray enumerateObjectsUsingBlock:^(dispatch_block_t  _Nonnull block, NSUInteger idx, BOOL * _Nonnull stop) {
        notifyBlock(block);
    }];
}

@end
