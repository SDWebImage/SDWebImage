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
    CGImageRef cgImage = [self CGImageForProposedRect:&imageRect context:nil hints:nil];
    return cgImage;
}

- (NSArray<NSImage *> *)images {
    return nil;
}

- (CGFloat)scale {
    CGFloat scale = 1;
    CGFloat width = self.size.width;
    if (width > 0) {
        // Use CGImage to get pixel width, NSImageRep.pixelsWide always double on Retina screen
        NSUInteger pixelWidth = CGImageGetWidth(self.CGImage);
        scale = pixelWidth / width;
    }
    return scale;
}

- (NSBitmapImageRep *)bitmapImageRep {
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        return (NSBitmapImageRep *)imageRep;
    }
    return nil;
}

@end

#endif
