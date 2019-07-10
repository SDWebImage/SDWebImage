/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import <Foundation/Foundation.h>
#import "SDMemoryCache.h"

@interface SDMemoryLRUCache <KeyType, ObjectType>: NSObject <SDMemoryCache>

@property (nonatomic, strong, nonnull, readonly) SDImageCacheConfig *config;
/**
 * Whether release the key-value pair asynchronously.
 * If it's YES, the key-value pair will asynchronously release.
 * If it's NO, the key-value pair will synchronously release.
 * Default is YES.
 */
@property (nonatomic, assign) BOOL releaseAsynchronously;

/**
 * Whether release the key-value pair on main thread.
 * If it's YES, the key-value pair will release on main queue.
 * If it's NO, the key-value pair will release on a global thread.
 * Default is NO.
 */
@property (nonatomic, assign) BOOL releaseOnMainThread;

@end

