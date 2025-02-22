/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import "SDWebImageCompat.h"

/// SDCallbackPolicy controls how we execute the block on the queue, like whether to use `dispatch_async/dispatch_sync`, check if current queue match target queue, or just invoke without any context.
typedef NS_ENUM(NSUInteger, SDCallbackPolicy) {
    /// When the current queue is equal to callback queue, sync/async will just invoke `block` directly without dispatch. Else it use `dispatch_async`/`dispatch_sync` to dispatch block on queue. This is useful for UIKit rendering to ensure all blocks executed in the same runloop
    SDCallbackPolicySafeExecute = 0,
    /// Follow async/sync using the correspond `dispatch_async`/`dispatch_sync` to dispatch block on queue
    SDCallbackPolicyDispatch = 1,
    /// Ignore any async/sync and just directly invoke `block` in current queue (without `dispatch_async`/`dispatch_sync`)
    SDCallbackPolicyInvoke = 2,
    /// Ensure callback in main thread. Do `dispatch_async` if the `NSThread.isMainTrhead == true` ; else do invoke `block`. Never use `dispatch_sync`, suitable for special UI-related code
    SDCallbackPolicySafeAsyncMainThread = 3,
};

/// SDCallbackQueue is a wrapper used to control how the completionBlock should perform on queues, used by our `Cache`/`Manager`/`Loader`.
/// Useful when you call SDWebImage in non-main queue and want to avoid it callback into main queue, which may cause issue.
@interface SDCallbackQueue : NSObject

/// The main queue. This is the default value, has the same effect when passing `nil` to `SDWebImageContextCallbackQueue`
/// The policy defaults to `SDCallbackPolicySafeAsyncMainThread`
@property (nonnull, class, readonly) SDCallbackQueue *mainQueue;

/// The caller current queue. Using `dispatch_get_current_queue`. This is not a dynamic value and only keep the first call time queue.
/// The policy defaults to `SDCallbackPolicySafeExecute`
@property (nonnull, class, readonly) SDCallbackQueue *currentQueue;

/// The global concurrent queue (user-initiated QoS). Using `dispatch_get_global_queue`.
/// The policy defaults to `SDCallbackPolicySafeExecute`
@property (nonnull, class, readonly) SDCallbackQueue *globalQueue;

/// The current queue's callback policy.
@property (nonatomic, assign, readwrite) SDCallbackPolicy policy;

- (nonnull instancetype)init NS_UNAVAILABLE;
+ (nonnull instancetype)new  NS_UNAVAILABLE;
/// Create the callback queue with a GCD queue. The policy defaults to `SDCallbackPolicySafeExecute`
/// - Parameter queue: The GCD queue, should not be NULL
- (nonnull instancetype)initWithDispatchQueue:(nonnull dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

#pragma mark - Execution Entry

/// Submits a block for execution and returns after that block finishes executing.
/// - Parameter block: The block that contains the work to perform.
- (void)sync:(nonnull dispatch_block_t)block API_DEPRECATED("No longer use, may cause deadlock when misused", macos(10.10, 10.10), ios(8.0, 8.0), tvos(9.0, 9.0), watchos(2.0, 2.0));;

/// Schedules a block asynchronously for execution.
/// - Parameter block: The block that contains the work to perform.
- (void)async:(nonnull dispatch_block_t)block;

@end
