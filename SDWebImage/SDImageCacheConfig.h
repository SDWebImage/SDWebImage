/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

// This class conform to NSCopying, make sure to add the property in `copyWithZone:` as well.
@interface SDImageCacheConfig : NSObject <NSCopying>

/**
 Gets/Sets the default cache config used for shared instance or initialization when it does not provide any cache config. Such as `SDImageCache.sharedImageCache`.
 @note You can modify the property on default cache config, which can be used for later created cache instance. The already created cache instance does not get affected.
 @note You should not pass nil to this value.
 */
@property (nonatomic, class, nonnull) SDImageCacheConfig *defaultCacheConfig;

/**
 * Decompressing images means pre-decoding the image that are downloaded and cached on background queue. This can avoid image view decode it on main queue when rendering. This can improve performance but can consume more memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 */
@property (assign, nonatomic) BOOL shouldDecompressImages;

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
 * Whether or not to remove the expired disk data when application entering the background. (Not works for macOS)
 * Defatuls to YES.
 */
@property (assign, nonatomic) BOOL shouldRemoveExpiredDataWhenEnterBackground;

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

/**
 * The custom file manager for disk cache. Pass nil to let disk cache choose the proper file manager.
 * Defaults to nil.
 * @note This value does not support dynamic changes. Which means further modification on this value after cache initlized has no effect.
 * @note Since `NSFileManager` does not support `NSCopying`. We just pass this by reference during copying. So it's not recommend to set this value on `defaultCacheConfig`.
 */
@property (strong, nonatomic, nullable) NSFileManager *fileManager;

/**
 * The custom memory cache class. Provided class instance must conform to `SDMemoryCache` protocol to allow usage.
 * Defaults to built-in `SDMemoryCache` class.
 * @note This value does not support dynamic changes. Which means further modification on this value after cache initlized has no effect.
 */
@property (assign, nonatomic, nonnull) Class memoryCacheClass;

/**
 * The custom disk cache class. Provided class instance must conform to `SDDiskCache` protocol to allow usage.
 * Defaults to built-in `SDDiskCache` class.
 * @note This value does not support dynamic changes. Which means further modification on this value after cache initlized has no effect.
 */
@property (assign ,nonatomic, nonnull) Class diskCacheClass;

@end
