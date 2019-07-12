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
/**
 Key for current loading URL (NSURL *)
 */
FOUNDATION_EXPORT SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerURL;
/**
 Key for current loading progress (NSProgress *)
 */
FOUNDATION_EXPORT SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerProgress;
/**
 Key for current image transition animation (SDWebImageTransition *)
 */
FOUNDATION_EXPORT SDWebImageStateContainerKey _Nonnull const SDWebImageStateContainerTransition;

/**
 These methods are used for WebCache view which have multiple states for image loading, for example, `UIButton` or `UIImageView.highlightedImage`
 It maitain the state container for per-operation, make it possible for control and check each image loading operation's state.
 @note For developer who want to add SDWebImage View Category support for their own stateful class, learn more on Wiki.
 */
@interface UIView (WebCacheState)

/**
 Get the image loading state container for specify operation key

 @param key key for identifying the operations
 @return The image loading state container
 */
- (nullable SDWebImageStateContainer *)sd_imageLoadStateForKey:(nullable NSString *)key;

/**
 Set the image loading state container for specify operation key

 @param state The image loading state container
 @param key key for identifying the operations
 */
- (void)sd_setImageLoadState:(nullable SDWebImageStateContainer *)state forKey:(nullable NSString *)key;

/**
 Rmove the image loading state container for specify operation key

 @param key key for identifying the operations
 */
- (void)sd_removeImageLoadStateForKey:(nullable NSString *)key;

@end
