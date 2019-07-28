/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+Metadata.h"
#import "NSImage+Compatibility.h"
#import "objc/runtime.h"

@implementation UIImage (Metadata)

#if SD_UIKIT || SD_WATCH

- (NSUInteger)sd_imageLoopCount {
    NSUInteger imageLoopCount = 0;
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_imageLoopCount));
    if ([value isKindOfClass:[NSNumber class]]) {
        imageLoopCount = value.unsignedIntegerValue;
    }
    return imageLoopCount;
}

- (void)setSd_imageLoopCount:(NSUInteger)sd_imageLoopCount {
    NSNumber *value = @(sd_imageLoopCount);
    objc_setAssociatedObject(self, @selector(sd_imageLoopCount), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sd_isAnimated {
    return (self.images != nil);
}

#else

- (NSUInteger)sd_imageLoopCount {
    NSUInteger imageLoopCount = 0;
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (bitmapImageRep) {
        imageLoopCount = [[bitmapImageRep valueForProperty:NSImageLoopCount] unsignedIntegerValue];
    }
    return imageLoopCount;
}

- (void)setSd_imageLoopCount:(NSUInteger)sd_imageLoopCount {
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (bitmapImageRep) {
        [bitmapImageRep setProperty:NSImageLoopCount withValue:@(sd_imageLoopCount)];
    }
}

- (BOOL)sd_isAnimated {
    BOOL isGIF = NO;
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    NSBitmapImageRep *bitmapImageRep;
    if ([imageRep isKindOfClass:[NSBitmapImageRep class]]) {
        bitmapImageRep = (NSBitmapImageRep *)imageRep;
    }
    if (bitmapImageRep) {
        NSUInteger frameCount = [[bitmapImageRep valueForProperty:NSImageFrameCount] unsignedIntegerValue];
        isGIF = frameCount > 1 ? YES : NO;
    }
    return isGIF;
}

#endif

- (SDImageFormat)sd_imageFormat {
    SDImageFormat imageFormat = SDImageFormatUndefined;
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_imageFormat));
    if ([value isKindOfClass:[NSNumber class]]) {
        imageFormat = value.integerValue;
        return imageFormat;
    }
    // Check CGImage's UTType, may return nil for non-Image/IO based image
    if (@available(iOS 9.0, tvOS 9.0, macOS 10.11, watchOS 2.0, *)) {
        CFStringRef uttype = CGImageGetUTType(self.CGImage);
        imageFormat = [NSData sd_imageFormatFromUTType:uttype];
    }
    return imageFormat;
}

- (void)setSd_imageFormat:(SDImageFormat)sd_imageFormat {
    objc_setAssociatedObject(self, @selector(sd_imageFormat), @(sd_imageFormat), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setSd_isIncremental:(BOOL)sd_isIncremental {
    objc_setAssociatedObject(self, @selector(sd_isIncremental), @(sd_isIncremental), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sd_isIncremental {
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_isIncremental));
    return value.boolValue;
}

@end
