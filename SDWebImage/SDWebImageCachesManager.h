/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCache.h"

typedef NS_ENUM(NSUInteger, SDWebImageCachesManagerOperationPolicy) {
    SDWebImageCachesManagerOperationPolicySerial, // process all caches serially (from the highest priority to the lowest priority cache by order)
    SDWebImageCachesManagerOperationPolicyConcurrent, // process all caches concurrently
    SDWebImageCachesManagerOperationPolicyHighestOnly, // process the highest priority cache only
    SDWebImageCachesManagerOperationPolicyLowestOnly // process the lowest priority cache only
};

@interface SDWebImageCachesManager : NSObject <SDWebImageCache>

/**
 Returns the global shared caches manager instance.
 */
@property (nonatomic, class, readonly, nonnull) SDWebImageCachesManager *sharedManager;

// These are op policy for cache manager.

/**
 Operation policy for query op.
 Defaults to `Serial`, means query all caches serially (one completion called then next begin) until one cache query success (`image` != nil).
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy queryOperationPolicy;

/**
 Operation policy for store op.
 Defaults to `HighestOnly`, means store to the highest priority cache only.
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy storeOperationPolicy;

/**
 Operation policy for remove op.
 Defaults to `Concurrent`, means remove all caches concurrently.
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy removeOperationPolicy;

/**
 Operation policy for contains op.
 Defaults to `Serial`, means check all caches serially (one completion called then next begin) until one cache check success (`containsCacheType` != None).
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy containsOperationPolicy;

/**
 Operation policy for clear op.
 Defaults to `Concurrent`, means clear all caches concurrently.
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy clearOperationPolicy;

/**
 All caches in caches manager. The caches array is a priority queue, which means the later added cache will have the highest priority
 */
@property (atomic, copy, readwrite, nullable) NSArray<id<SDWebImageCache>> *caches;

/**
 Add a new cache to the end of caches array. Which has the highest priority.
 
 @param cache cache
 */
- (void)addCache:(nonnull id<SDWebImageCache>)cache;

/**
 Remove a cache in the caches array.
 
 @param cache cache
 */
- (void)removeCache:(nonnull id<SDWebImageCache>)cache;

@end
