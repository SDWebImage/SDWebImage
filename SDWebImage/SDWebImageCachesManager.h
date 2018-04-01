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
    SDWebImageCachesManagerOperationPolicyAll, // process all caches
    SDWebImageCachesManagerOperationPolicyHighest, // process the highest priority cache only
    SDWebImageCachesManagerOperationPolicyLowest // process the lowest priority cache only
};

@interface SDWebImageCachesManager : NSObject <SDWebImageCache>

/**
 Returns the global shared caches manager instance.
 */
@property (nonatomic, class, readonly, nonnull) SDWebImageCachesManager *sharedManager;

// These are op policy for cache manager.

/**
 Operation policy for query op. `All` means query all caches serially (one completion called then next begin) until one cache query success.
 Defaults to `All`
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy queryOperationPolicy;

/**
 Operation policy for store op. `All` means store all caches concurrently.
 Defaults to `Highest`
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy storeOperationPolicy;

/**
 Operation policy for remove op. `All` means remove all caches concurrently.
 Defaults to `All`
 */
@property (nonatomic, assign) SDWebImageCachesManagerOperationPolicy removeOperationPolicy;

/**
 Operation policy for clear op. `All` means clear all caches concurrently.
 Defaults to `All`
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
