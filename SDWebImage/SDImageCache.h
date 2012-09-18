/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDImageCacheDelegate.h"

/**
 * SDImageCache maintains a memory cache and an optional disk cache. Disk cache write operations are performed
 * asynchronous so it doesn’t add unnecessary latency to the UI.
 */
@interface SDImageCache : NSObject
{
    NSMutableDictionary *memCache;
    NSString *diskCachePath;
    NSOperationQueue *cacheInQueue, *cacheOutQueue;
}

/**
 * Returns global shared cache instance
 *
 * @return SDImageCache global instance
 */
+ (SDImageCache *)sharedImageCache;

/**
 * Sets the global maximum cache age
 *
 * @param maxCacheAge The maximum length of time to keep an image in the cache, in seconds
 */
+ (void) setMaxCacheAge:(NSInteger) maxCacheAge;

/**
 * Store an image into memory and disk cache at the given key.
 *
 * @param image The image to store
 * @param key The unique image cache key, usually it's image absolute URL
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;

/**
 * Store an image into memory and optionally disk cache at the given key.
 *
 * @param image The image to store
 * @param key The unique image cache key, usually it's image absolute URL
 * @param toDisk Store the image to disk cache if YES
 */
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 * Store an image into memory and optionally disk cache at the given key.
 *
 * @param image The image to store
 * @param data The image data as returned by the server, this representation will be used for disk storage
 *             instead of converting the given image object into a storable/compressed image format in order
 *             to save quality and CPU
 * @param key The unique image cache key, usually it's image absolute URL
 * @param toDisk Store the image to disk cache if YES
 */
- (void)storeImage:(UIImage *)image imageData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk;

/**
 * Query the memory cache for an image at a given key and fallback to disk cache
 * synchronousely if not found in memory.
 *
 * @warning This method may perform some synchronous IO operations
 *
 * @param key The unique key used to store the wanted image
 */
- (UIImage *)imageFromKey:(NSString *)key;

/**
 * Query the memory cache for an image at a given key and optionnaly fallback to disk cache
 * synchronousely if not found in memory.
 *
 * @warning This method may perform some synchronous IO operations if fromDisk is YES
 *
 * @param key The unique key used to store the wanted image
 * @param fromDisk Try to retrive the image from disk if not found in memory if YES
 */
- (UIImage *)imageFromKey:(NSString *)key fromDisk:(BOOL)fromDisk;


/**
 * Query the disk cache asynchronousely.
 *
 * @param key The unique key used to store the wanted image
 * @param delegate The delegate object to send response to
 * @param info An NSDictionary with some user info sent back to the delegate
 */
- (void)queryDiskCacheForKey:(NSString *)key delegate:(id <SDImageCacheDelegate>)delegate userInfo:(NSDictionary *)info;

/**
 * Remove the image from memory and disk cache synchronousely
 *
 * @param key The unique image cache key
 */
- (void)removeImageForKey:(NSString *)key;

/**
 * Remove the image from memory and optionaly disk cache synchronousely
 *
 * @param key The unique image cache key
 * @param fromDisk Also remove cache entry from disk if YES
 */
- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk;

/**
 * Clear all memory cached images
 */
- (void)clearMemory;

/**
 * Clear all disk cached images
 */
- (void)clearDisk;

/**
 * Remove all expired cached image from disk
 */
- (void)cleanDisk;

/**
 * Get the size used by the disk cache
 */
- (int)getSize;

/**
 * Get the number of images in the disk cache
 */
- (int)getDiskCount;

/**
 * Get the total size of images in memory cache
 */
- (int)getMemorySize;

/**
 * Get the number of images in the memory cache
 */
- (int)getMemoryCount;

@end
