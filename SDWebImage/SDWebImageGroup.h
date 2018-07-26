/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>

@interface SDWebImageGroup : NSObject

/**
 * The group to simulate the behavior of `dispatch_group_t`, the difference is
 * `dispatch_group_notify` is async when call block, `SDWebImageGroup` support
 * sync/async, default is sync, you should be careful to prevent dead lock.
 *
 * @param queue         The queue to which the notify block is submitted when group completes.
 * @param isAsync       Sync/Async to call notify block, default is sync. Be careful to prevent dead lock.
 */
- (nonnull instancetype)initWithNotifyQueue:(nullable dispatch_queue_t)queue
                                    isAsync:(BOOL)isAsync NS_DESIGNATED_INITIALIZER;

/**
 * Explicity indicates that a block has enterd the group.
 */
- (void)enter;

/**
 * Explicitly indicates that a block in the group has completed.
 */
- (void)leave;

/**
 * Schedules a block object to be submitted to a queue when a group of previously submitted block objects have completed.
 */
- (void)addNotifyWithBlock:(dispatch_block_t)block;

@end
