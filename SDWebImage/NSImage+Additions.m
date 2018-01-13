/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSImage+Additions.h"

#if SD_MAC

@implementation NSImage (Additions)

- (CGImageRef)CGImage {
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    CGImageRef cgImage = [self CGImageForProposedRect:&imageRect context:NULL hints:nil];
    return cgImage;
}

- (NSArray<NSImage *> *)images {
    return nil;
}

- (CGFloat)scale {
    CGFloat scale = 1;
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *rep = [self bestRepresentationForRect:imageRect context:NULL hints:nil];
    NSInteger pixelsWide = rep.pixelsWide;
    CGFloat width = rep.size.width;
    if (width > 0) {
        scale = pixelsWide / width;
    }
    return scale;
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale {
    NSSize size;
    if (cgImage && scale > 0) {
        NSInteger pixelsWide = CGImageGetWidth(cgImage);
        NSInteger pixelsHigh = CGImageGetHeight(cgImage);
        CGFloat width = pixelsWide / scale;
        CGFloat height = pixelsHigh / scale;
        size = NSMakeSize(width, height);
    } else {
        size = NSZeroSize;
    }
    return [self initWithCGImage:cgImage size:size];
}

@end

#endif
