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

static void * SDCallbackQueueKey = &SDCallbackQueueKey;
static void SDReleaseBlock(void *context) {
    CFRelease(context);
}

static void SDSafeExecute(SDCallbackQueue *callbackQueue, dispatch_block_t _Nonnull block, BOOL async) {
    // Extendc gcd queue's life cycle
    dispatch_queue_t queue = callbackQueue.queue;
    // Special handle for main queue label only (custom queue can have the same label)
    const char *label = dispatch_queue_get_label(queue);
    if (label && label == dispatch_queue_get_label(dispatch_get_main_queue())) {
        const char *currentLabel = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
        if (label == currentLabel) {
            block();
            return;
        }
    }
    // Check specific to detect queue equal
    void *specific = dispatch_queue_get_specific(queue, SDCallbackQueueKey);
    if (specific && CFGetTypeID(specific) == CFUUIDGetTypeID()) {
        void *currentSpecific = dispatch_get_specific(SDCallbackQueueKey);
        if (currentSpecific && CFGetTypeID(currentSpecific) == CFUUIDGetTypeID() && CFEqual(specific, currentSpecific)) {
            block();
            return;
        }
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
        CFUUIDRef UUID = CFUUIDCreate(kCFAllocatorDefault);
        dispatch_queue_set_specific(queue, SDCallbackQueueKey, (void *)UUID, SDReleaseBlock);
        _queue = queue;
    }
    return self;
}

+ (SDCallbackQueue *)mainQueue {
    static dispatch_once_t onceToken;
    static SDCallbackQueue *queue;
    dispatch_once(&onceToken, ^{
        queue = [[SDCallbackQueue alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    });
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
            SDSafeExecute(self, block, NO);
            break;
        case SDCallbackPolicyDispatch:
            dispatch_sync(self.queue, block);
            break;
        case SDCallbackPolicyInvoke:
            block();
            break;
    }
}

- (void)async:(nonnull dispatch_block_t)block {
    switch (self.policy) {
        case SDCallbackPolicySafeExecute:
            SDSafeExecute(self, block, YES);
            break;
        case SDCallbackPolicyDispatch:
            dispatch_async(self.queue, block);
            break;
        case SDCallbackPolicyInvoke:
            block();
            break;
    }
}

@end
