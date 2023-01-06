/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import "SDWebImageCompat.h"

/// SDCallbackQueue is a wrapper used to control how the completionBlock should perform on queues, used by our `Cache`/`Manager`/`Loader`.
/// Useful when you call SDWebImage in non-main queue and want to avoid it callback into main queue, which may cause issue.
@interface SDCallbackQueue : NSObject

/// The shared main queue. This is the default value, has the same effect when passing `nil` to `SDWebImageContextCallbackQueue`
@property (nonnull, class, readonly) SDCallbackQueue *mainQueue;

/// The caller current queue. Using `dispatch_get_current_queue`. This is not a dynamic value and only keep the first call time queue.
@property (nonnull, class, readonly) SDCallbackQueue *currentQueue;

/// The global concurrent queue (user-initiated QoS). Using `dispatch_get_global_queue`.
@property (nonnull, class, readonly) SDCallbackQueue *globalQueue;

/// Create the callback queue with a GCD queue
/// - Parameter queue: The GCD queue, should not be NULL
- (nonnull instancetype)initWithDispatchQueue:(nonnull dispatch_queue_t)queue;

/// Submits a block for execution and returns after that block finishes executing.
/// - Parameter block: The block that contains the work to perform.
- (void)sync:(nullable dispatch_block_t)block;

/// Submits a block for execution and returns after that block finishes executing. When the current enqueued queue matching the callback queue, call the block immediately.
/// @warning This will not works when using `dispatch_set_target_queue` or recursive queue context.
/// - Parameter block: The block that contains the work to perform.
- (void)syncSafe:(nullable dispatch_block_t)block;

/// Schedules a block asynchronously for execution.
/// - Parameter block: The block that contains the work to perform.
- (void)async:(nullable dispatch_block_t)block;

/// Schedules a block asynchronously for execution. When the current enqueued queue matching the callback queue, call the block immediately.
/// @warning This will not works when using `dispatch_set_target_queue` or recursive queue context.
/// - Parameter block: The block that contains the work to perform.
- (void)asyncSafe:(nullable dispatch_block_t)block;

@end
