/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

typedef NSString * SDWebImageLoadingStorageKey NS_EXTENSIBLE_STRING_ENUM;
typedef NSDictionary<SDWebImageLoadingStorageKey, id> SDWebImageLoadingStorage;
typedef NSMutableDictionary<SDWebImageLoadingStorageKey, id> SDWebImageMutableLoadingStorage;
FOUNDATION_EXPORT SDWebImageLoadingStorageKey _Nonnull const SDWebImageLoadingStorageURL;
FOUNDATION_EXPORT SDWebImageLoadingStorageKey _Nonnull const SDWebImageLoadingStorageProgress;

@interface UIView (WebCacheStorage)

- (nullable SDWebImageLoadingStorage *)sd_imageLoadStorageForKey:(nullable NSString *)key;
- (void)sd_setImageLoadStorage:(nullable SDWebImageLoadingStorage *)storage forKey:(nullable NSString *)key;
- (void)sd_removeImageLoadStorageForKey:(nullable NSString *)key;

@end
