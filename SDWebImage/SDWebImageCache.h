/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"
#import "SDWebImageDefine.h"

typedef NS_ENUM(NSInteger, SDImageCacheType) {
    /**
     * For query and contains op in response, means the image isn't available in the image cache
     * For op in request, this type is not available and take no effect.
     */
    SDImageCacheTypeNone,
    /**
     * For query and contains op in response, means the image was obtained from the disk cache.
     * For op in request, means process only disk cache.
     */
    SDImageCacheTypeDisk,
    /**
     * For query and contains op in response, means the image was obtained from the memory cache.
     * For op in request, means process only memory cache.
     */
    SDImageCacheTypeMemory,
    /**
     * For query and contains op in response, this type is not available and take no effect.
     * For op in request, means process both memory cache and disk cache.
     */
    SDImageCacheTypeBoth
};

typedef void(^SDImageCacheQueryCompletionBlock)(UIImage * _Nullable image, NSData * _Nullable data, SDImageCacheType cacheType);
typedef void(^SDImageCacheContainsCompletionBlock)(SDImageCacheType containsCacheType);

/**
 This is the image cache protocol to provide custom image cache for `SDWebImageManager`.
 Though the best practice to custom image cache, is to write your own class which conform `SDMemoryCache` or `SDDiskCache` protocol for `SDImageCache` class (See more on `SDImageCacheConfig.memoryCacheClass & SDImageCacheConfig.diskCacheClass`).
 However, if your own cache implementation contains more advanced feature beyond `SDImageCache` itself, you can consider to provide this instead. For example, you can even use a cache manager like `SDWebImageCachesManager` to register multiple caches.
 */
@protocol SDWebImageCache <NSObject>

@required
/**
 Query the cached image from image cache for given key. The operation can be used to cancel the query.
 If image is cached in memory, completion is called synchronously, else aynchronously and depends on the options arg (See `SDWebImageQueryDiskSync`)

 @param key The image cache key
 @param options A mask to specify options to use for this query
 @param context A context contains different options to perform specify changes or processes, see `SDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 @param completionBlock The completion block. Will not get called if the operation is cancelled
 @return The operation for this query
 */
- (nullable id<SDWebImageOperation>)queryImageForKey:(nullable NSString *)key
                                             options:(SDWebImageOptions)options
                                             context:(nullable SDWebImageContext *)context
                                          completion:(nullable SDImageCacheQueryCompletionBlock)completionBlock;

/**
 Store the image into image cache for the given key. If cache type is memory only, completion is called synchronously, else aynchronously.

 @param image The image to store
 @param imageData The image data to be used for disk storage
 @param key The image cache key
 @param cacheType The image store op cache type
 @param completionBlock A block executed after the operation is finished
 */
- (void)storeImage:(nullable UIImage *)image
         imageData:(nullable NSData *)imageData
            forKey:(nullable NSString *)key
         cacheType:(SDImageCacheType)cacheType
        completion:(nullable SDWebImageNoParamsBlock)completionBlock;

/**
 Remove the image from image cache for the given key. If cache type is memory only, completion is called synchronously, else aynchronously.

 @param key The image cache key
 @param cacheType The image remove op cache type
 @param completionBlock A block executed after the operation is finished
 */
- (void)removeImageForKey:(nullable NSString *)key
                cacheType:(SDImageCacheType)cacheType
               completion:(nullable SDWebImageNoParamsBlock)completionBlock;

/**
 Check if image cache contains the image for the given key (does not load the image). If image is cached in memory, completion is called synchronously, else aynchronously.

 @param key The image cache key
 @param cacheType The image contains op cache type
 @param completionBlock A block executed after the operation is finished.
 */
- (void)containsImageForKey:(nullable NSString *)key
                  cacheType:(SDImageCacheType)cacheType
                 completion:(nullable SDImageCacheContainsCompletionBlock)completionBlock;

/**
 Clear all the cached images for image cache. If cache type is memory only, completion is called synchronously, else aynchronously.

 @param cacheType The image clear op cache type
 @param completionBlock A block executed after the operation is finished
 */
- (void)clearWithCacheType:(SDImageCacheType)cacheType
                completion:(nullable SDWebImageNoParamsBlock)completionBlock;

@end
