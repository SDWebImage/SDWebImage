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

- (CGFloat)scale {
    CGFloat scale = 1;
    CGFloat width = self.size.width;
    if (width > 0) {
        // Use CGImage to get pixel width, NSImageRep.pixelsWide may be double on Retina screen
        NSUInteger pixelWidth = CGImageGetWidth(self.CGImage);
        scale = pixelWidth / width;
    }
    return scale;
}

- (instancetype)initWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale {
    if (scale < 1) {
        scale = 1;
    }
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage scale:scale];
    NSSize size = NSMakeSize(imageRep.pixelsWide / scale, imageRep.pixelsHigh / scale);
    self = [self initWithSize:size];
    if (self) {
        [self addRepresentation:imageRep];
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (scale < 1) {
        scale = 1;
    }
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithData:data scale:scale];
    if (!imageRep) {
        return nil;
    }
    NSSize size = NSMakeSize(imageRep.pixelsWide / scale, imageRep.pixelsHigh / scale);
    self = [self initWithSize:size];
    if (self) {
        [self addRepresentation:imageRep];
    }
    return self;
}

@end

@implementation NSBitmapImageRep (Additions)

- (instancetype)initWithCGImage:(CGImageRef)cgImage scale:(CGFloat)scale {
    self = [self initWithCGImage:cgImage];
    if (self) {
        if (scale < 1) {
            scale = 1;
        }
        NSSize size = NSMakeSize(self.pixelsWide / scale, self.pixelsHigh / scale);
        self.size = size;
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    self = [self initWithData:data];
    if (self) {
        if (scale < 1) {
            scale = 1;
        }
        NSSize size = NSMakeSize(self.pixelsWide / scale, self.pixelsHigh / scale);
        self.size = size;
    }
    return self;
}

@end

#endif
