/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

// This category is provided to easily write cross-platform code. For common usage, see `UIImage+WebCache`.

#if SD_MAC

@interface NSImage (Additions)

@property (nonatomic, readonly, nullable) CGImageRef CGImage;
@property (nonatomic, readonly, nullable) NSArray<NSImage *> *images;
@property (nonatomic, readonly) CGFloat scale;
@property (nonatomic, readonly, nullable) NSBitmapImageRep *bitmapImageRep;

@end

#endif
