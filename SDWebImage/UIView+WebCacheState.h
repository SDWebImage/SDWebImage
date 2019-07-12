/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

typedef NSString * SDWebImageStateContainerKey NS_EXTENSIBLE_STRING_ENUM;
typedef NSDictionary<SDWebImageStateContainerKey, id> SDWebImageStateContainer;
typedef NSMutableDictionary<SDWebImageStateContainerKey, id> SDWebImageMutableStateContainer;
FOUNDATION_EXPORT SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerURL;
FOUNDATION_EXPORT SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerProgress;
FOUNDATION_EXPORT SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerTransition;

@interface UIView (WebCacheState)

- (nullable SDWebImageStateContainer *)sd_imageLoadStateForKey:(nullable NSString *)key;
- (void)sd_setImageLoadState:(nullable SDWebImageStateContainer *)state forKey:(nullable NSString *)key;
- (void)sd_removeImageLoadStateForKey:(nullable NSString *)key;

@end
