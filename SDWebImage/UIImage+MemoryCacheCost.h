/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

@interface UIImage (MemoryCacheCost)

/**
 The memory cache cost for specify image used by image cache. The cost function is the pixles count held in memory.
 If you set some associated object to `UIImage`, you can set the custom value to indicate the memory cost.
 
 For `UIImage`, this method return the single frame pixles count when `image.images` is nil for static image. Retuen full frame pixels count when `image.images` is not nil for animated image.
 For `NSImage`, this method return the single frame pixels count because `NSImage` does not store all frames in memory.
 @note Note that because of the limitations of categories this property can get out of sync if you create another instance with CGImage or other methods.
 */
@property (assign, nonatomic) NSUInteger sd_memoryCost;

@end
