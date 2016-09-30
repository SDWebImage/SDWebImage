/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_MAC

#import <Cocoa/Cocoa.h>

@interface NSImage (WebCache)

- (CGImageRef)CGImage;
- (NSArray<NSImage *> *)images;
- (BOOL)isGIF;

@end

#endif
