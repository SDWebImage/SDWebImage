/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"

/**
 These methods are used to support canceling for UIView image loading, it's designed to be used internal but not external.
 All the stored operations are weak, so it will be dealloced after image loading finished. If you need to store operations, use your own class to keep a strong reference for them.
 */
@interface UIView (WebCacheOperation)

/**
 *  Get the image load operation for key
 *
 *  @param key key for identifying the operations
 *  @return the image load operation
 *  @note If key is nil, means using the NSStringFromClass(self.class) instead, match the behavior of `operation key`
 */
- (nullable id<SDWebImageOperation>)sd_imageLoadOperationForKey:(nullable NSString *)key;

/**
 *  Set the image load operation (storage in a UIView based weak map table)
 *
 *  @param operation the operation, should not be nil or no-op will perform
 *  @param key       key for storing the operation
 *  @note If key is nil, means using the NSStringFromClass(self.class) instead, match the behavior of `operation key`
 */
- (void)sd_setImageLoadOperation:(nullable id<SDWebImageOperation>)operation forKey:(nullable NSString *)key;

/**
 *  Cancel the operation for the current UIView and key
 *
 *  @param key key for identifying the operations
 *  @note If key is nil, means using the NSStringFromClass(self.class) instead, match the behavior of `operation key`
 */
- (void)sd_cancelImageLoadOperationWithKey:(nullable NSString *)key;

/**
 *  Just remove the operation corresponding to the current UIView and key without cancelling them
 *
 *  @param key key for identifying the operations.
 *  @note If key is nil, means using the NSStringFromClass(self.class) instead, match the behavior of `operation key`
 */
- (void)sd_removeImageLoadOperationWithKey:(nullable NSString *)key;

@end
