/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

@interface SDImageCacheConfig : NSObject

/**
 * Whether or not to disable iCloud backup
 * Defaults to YES.
 */
@property (assign, nonatomic) BOOL shouldDisableiCloud;

/**
 * Whether or not to use memory cache
 * Defaults to YES.
 */
@property (assign, nonatomic) BOOL shouldCacheImagesInMemory;

/**
 * The reading options while reading cache from disk.
 * Defaults to 0. You can set this to `NSDataReadingMappedIfSafe` to improve performance.
 */
@property (assign, nonatomic) NSDataReadingOptions diskCacheReadingOptions;

/**
 * The writing options while writing cache to disk.
 * Defaults to `NSDataWritingAtomic`. You can set this to `NSDataWritingWithoutOverwriting` to prevent overwriting an existing file.
 */
@property (assign, nonatomic) NSDataWritingOptions diskCacheWritingOptions;

/**
 * The maximum length of time to keep an image in the cache, in seconds.
 * Defaults to 1 weak.
 */
@property (assign, nonatomic) NSInteger maxCacheAge;

/**
 * The maximum size of the cache, in bytes.
 * Defaults to 0. Which means there is no cache size limit.
 */
@property (assign, nonatomic) NSUInteger maxCacheSize;

/**
 * The maximum "total cost" of the in-memory image cache. The cost function is the number of pixels held in memory.
 * Defaults to 0. Which means there is no memory cost limit.
 */
@property (assign, nonatomic) NSUInteger maxMemoryCost;

/**
 * The maximum number of objects the cache should hold.
 * Defaults to 0. Which means there is no memory count limit.
 */
@property (assign, nonatomic) NSUInteger maxMemoryCount;

@end
