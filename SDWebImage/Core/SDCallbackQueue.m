/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import "SDCallbackQueue.h"

@interface SDCallbackQueue ()

@property (nonatomic, strong, nonnull) dispatch_queue_t queue;

@end

static inline void SDSafeAsyncMainThread(dispatch_block_t _Nonnull block) {
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

static void SDSafeExecute(dispatch_queue_t queue, dispatch_block_t _Nonnull block, BOOL async) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    dispatch_queue_t currentQueue = dispatch_get_current_queue();
#pragma clang diagnostic pop
    if (queue == currentQueue) {
        block();
        return;
    }
    // Special handle for main queue only
    if (NSThread.isMainThread && queue == dispatch_get_main_queue()) {
        block();
        return;
    }
    if (async) {
        dispatch_async(queue, block);
    } else {
        dispatch_sync(queue, block);
    }
}

@implementation SDCallbackQueue

- (instancetype)initWithDispatchQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        NSCParameterAssert(queue);
        _queue = queue;
        _policy = SDCallbackPolicySafeExecute;
    }
    return self;
}

+ (SDCallbackQueue *)mainQueue {
    SDCallbackQueue *queue = [[SDCallbackQueue alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    queue->_policy = SDCallbackPolicySafeAsyncMainThread;
    return queue;
}

+ (SDCallbackQueue *)currentQueue {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    SDCallbackQueue *queue = [[SDCallbackQueue alloc] initWithDispatchQueue:dispatch_get_current_queue()];
#pragma clang diagnostic pop
    return queue;
}

+ (SDCallbackQueue *)globalQueue {
    SDCallbackQueue *queue = [[SDCallbackQueue alloc] initWithDispatchQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    return queue;
}

- (void)sync:(nonnull dispatch_block_t)block {
    switch (self.policy) {
        case SDCallbackPolicySafeExecute:
            SDSafeExecute(self.queue, block, NO);
            break;
        case SDCallbackPolicyDispatch:
            dispatch_sync(self.queue, block);
            break;
        case SDCallbackPolicyInvoke:
            block();
            break;
        case SDCallbackPolicySafeAsyncMainThread:
            SDSafeAsyncMainThread(block);
            break;
        default:
            NSCAssert(NO, @"unexpected policy %tu", self.policy);
            break;
    }
}

- (void)async:(nonnull dispatch_block_t)block {
    switch (self.policy) {
        case SDCallbackPolicySafeExecute:
            SDSafeExecute(self.queue, block, YES);
            break;
        case SDCallbackPolicyDispatch:
            dispatch_async(self.queue, block);
            break;
        case SDCallbackPolicyInvoke:
            block();
            break;
        case SDCallbackPolicySafeAsyncMainThread:
            SDSafeAsyncMainThread(block);
            break;
        default:
            NSCAssert(NO, @"unexpected policy %tu", self.policy);
            break;
    }
}

@end
