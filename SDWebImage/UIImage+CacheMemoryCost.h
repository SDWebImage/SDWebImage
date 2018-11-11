/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>

@interface UIImage (CacheMemoryCost)

/**
 * The image memory cost calculation, this property would be used in memory cache of `SDImageCache`.
 * The default value is pixels of `image` or `images`.
 * If you set some associated object to `UIImage`, you can set the custom value to indicate the memory cost.
 * If you set a new value after `UIImage` be cached to memory cache, you need to reinsert into cache with new value cost by yourself.
 */
@property (assign, nonatomic) NSUInteger sd_memoryCost;

@end
