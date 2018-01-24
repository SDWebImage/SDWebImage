/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

NS_ASSUME_NONNULL_BEGIN

// A protocol to allow custom disk cache used in SDImageCache.
@protocol SDDiskCache <NSObject>

// All of these method are called from the same global queue to avoid blocking on main queue and thread-safe problem. But it's also recommend to ensure thread-safe yourself using lock or other ways.
@required
/**
 Create a new cache based on the specified path.
 
 @param cachePath Full path of a directory in which the cache will write data.
 Once initialized you should not read and write to this directory.
 
 @return A new cache object, or nil if an error occurs.
 
 @warning If the cache instance for the specified path already exists in memory,
 this method will return it directly, instead of creating a new instance.
 */
- (nullable instancetype)initWithCachePath:(NSString *)cachePath;

/**
 Returns a boolean value that indicates whether a given key is in cache.
 This method may blocks the calling thread until file read finished.
 
 @param key A string identifying the data. If nil, just return NO.
 @return Whether the key is in cache.
 */
- (BOOL)containsDataForKey:(NSString *)key;

/**
 Returns the data associated with a given key.
 This method may blocks the calling thread until file read finished.
 
 @param key A string identifying the data. If nil, just return nil.
 @return The value associated with key, or nil if no value is associated with key.
 */
- (nullable NSData *)dataForKey:(NSString *)key;

/**
 Sets the value of the specified key in the cache.
 This method may blocks the calling thread until file write finished.
 
 @param data The data to be stored in the cache.
 @param key    The key with which to associate the value. If nil, this method has no effect.
 */
- (void)setData:(nullable NSData *)data forKey:(NSString *)key;

/**
 Removes the value of the specified key in the cache.
 This method may blocks the calling thread until file delete finished.
 
 @param key The key identifying the value to be removed. If nil, this method has no effect.
 */
- (void)removeDataForKey:(NSString *)key;

/**
 Empties the cache.
 This method may blocks the calling thread until file delete finished.
 */
- (void)removeAllData;

/**
 Removes the expired data from the cache. You can choose the data to remove base on `ageLimit`, `countLimit` and `sizeLimit` options.
 */
- (void)removeExpiredData;

/**
 The cache path for key

 @param key A string identifying the value
 @return The cache path for key. Or nil if the key can not associate to a path
 */
- (nullable NSString *)cachePathForKey:(NSString *)key;

/**
 Returns the number of data in this cache.
 This method may blocks the calling thread until file read finished.
 
 @return The total data count.
 */
- (NSInteger)totalCount;

/**
 Returns the total size (in bytes) of data in this cache.
 This method may blocks the calling thread until file read finished.
 
 @return The total data size in bytes.
 */
- (NSInteger)totalSize;

/**
 The maximum expiry time of data in cache.
 
 @discussion The default value is DBL_MAX, which means no limit.
 This is not a strict limit — if data goes over the limit, the data could
 be evicted later in background queue.
 */
- (NSTimeInterval)ageLimit;
- (void)setAgeLimit:(NSTimeInterval)ageLimit;

/**
 The maximum number of data the cache should hold.
 
 @discussion The default value is NSUIntegerMax, which means no limit.
 This is not a strict limit—if the cache goes over the limit, some data in the
 cache could be evicted later in backgound thread.
 */
- (NSUInteger)countLimit;
- (void)setCountLimit:(NSUInteger)countLimit;

/**
 The maximum total size that the cache can hold before it starts evicting data.
 
 @discussion The default value is NSUIntegerMax, which means no limit.
 This is not a strict limit — if the cache goes over the limit, some data in the
 cache could be evicted later in background queue.
 */
- (NSUInteger)sizeLimit;
- (void)setSizeLimit:(NSUInteger)sizeLimit;

@optional
// Some configurations are optional because they are tied to implementation detail and does not impact the basic fucntion.

/**
 Custom file manager. if your disk cache does not based on NSFileManager's API, Ignore it.

 @param fileManager fileManager
 */
- (void)setFileManager:(NSFileManager *)fileManager;

/**
 Custom data reading options. If your disk cache does not based on NSData's API, Ignore it.

 @param readingOptions data reading options
 */
- (void)setReadingOptions:(NSDataReadingOptions)readingOptions;

/**
 Custom data writing options. If your disk cache does not based on NSData's API, Ignore it.

 @param writingOptions data writing options
 */
- (void)setWritingOptions:(NSDataWritingOptions)writingOptions;

@end


@interface SDDiskCache : NSObject <SDDiskCache>

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
