/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"

// These methods are used to support canceling for UIView image loading, it's designed to be used internal but not external.
// All the stored operations are weak, so it will be dalloced after image loading finished. If you need to store operations, use your own class to keep a strong reference for them.
@interface UIView (WebCacheOperation)

/**
 *  Set the image load operation (storage in a UIView based weak map table)
 *
 *  @param operation the operation
 *  @param key       key for storing the operation
 */
- (void)sd_setImageLoadOperation:(nullable id<SDWebImageOperation>)operation forKey:(nullable NSString *)key;

/**
 *  Cancel operation for the current UIView and key
 *
 *  @param key key for identifying the operations
 */
- (void)sd_cancelImageLoadOperationWithKey:(nullable NSString *)key;

/**
 *  Cancel all operations for the current UIView
 */
- (void)sd_cancelAllImageLoadOperations;

/**
 *  Just remove the operations corresponding to the current UIView and key without cancelling them
 *
 *  @param key key for identifying the operations
 */
- (void)sd_removeImageLoadOperationWithKey:(nullable NSString *)key;

/**
 *  Set the image URL for the operation key
 *
 *  @param url            the image URL
 *  @param operationKey   key for storing the image URL
 */
- (void)sd_setImageURL:(nullable NSURL *)url forOperationKey:(nullable NSString *)operationKey;

/**
 *  Get the image URL for the operation key
 *
 *  @param operationKey   key for storing the image URL
 *  @return image URL
 */
- (nullable NSURL *)sd_imageURLWithOperationKey:(nullable NSString *)operationKey;

@end
