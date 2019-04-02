/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDImageGIFCoder.h"

@interface SDImageGIFCoder ()

- (float)sd_frameDurationAtIndex:(NSUInteger)index source:(nonnull CGImageSourceRef)source;

@end
