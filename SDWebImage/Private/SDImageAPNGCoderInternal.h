/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDImageAPNGCoder.h"

@interface SDImageAPNGCoder ()

- (float)sd_frameDurationAtIndex:(NSUInteger)index source:(nonnull CGImageSourceRef)source;
- (NSUInteger)sd_imageLoopCountWithSource:(nonnull CGImageSourceRef)source;

@end
