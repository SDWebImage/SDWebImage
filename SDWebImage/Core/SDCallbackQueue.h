/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import "SDWebImageDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDCallbackQueue : NSObject

@property (nonnull, class, readonly) SDCallbackQueue *mainQueue;

@property (nonnull, class, readonly) SDCallbackQueue *callerQueue;

@property (nonnull, class, readonly) SDCallbackQueue *globalQueue;

+ (SDCallbackQueue *)dispatchQueue:(dispatch_queue_t)queue;

- (void)sync:(SDWebImageNoParamsBlock)block;

- (void)async:(SDWebImageNoParamsBlock)block;

- (void)asyncSafe:(SDWebImageNoParamsBlock)block;

@end

NS_ASSUME_NONNULL_END
