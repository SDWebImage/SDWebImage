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

/**
 NSImage currently only support animated via GIF imageRep unlike UIImage.
 The getter of this property will get the loop count from GIF imageRep
 The setter of this property will set the loop count from GIF imageRep
 */
@property (nonatomic, assign) NSUInteger sd_imageLoopCount;

- (CGImageRef)CGImage;
- (NSArray<NSImage *> *)images;
- (BOOL)isGIF;

@end

#endif
