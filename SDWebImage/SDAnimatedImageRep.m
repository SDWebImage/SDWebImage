/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDAnimatedImageRep.h"

#if SD_MAC

#import "SDWebImageGIFCoder.h"

@interface SDWebImageGIFCoder ()

- (float)sd_frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source;

@end

@implementation SDAnimatedImageRep {
    CGImageSourceRef _imageSource;
}

- (void)dealloc {
    if (_imageSource) {
        CFRelease(_imageSource);
        _imageSource = NULL;
    }
}

// `NSBitmapImageRep`'s `imageRepWithData:` is not designed initlizer
+ (instancetype)imageRepWithData:(NSData *)data {
    SDAnimatedImageRep *imageRep = [[SDAnimatedImageRep alloc] initWithData:data];
    return imageRep;
}

// We should override init method for `NSBitmapImageRep` to do initlize about animated image format
- (instancetype)initWithData:(NSData *)data {
    self = [super initWithData:data];
    if (self) {
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
        if (!imageSource) {
            return self;
        }
        _imageSource = imageSource;
    }
    return self;
}

// `NSBitmapImageRep` will use `kCGImagePropertyGIFDelayTime` whenever you call `setProperty:withValue:` with `NSImageCurrentFrame` to change the current frame. We override it and use the actual `kCGImagePropertyGIFUnclampedDelayTime` if need.
- (void)setProperty:(NSBitmapImageRepPropertyKey)property withValue:(id)value {
    [super setProperty:property withValue:value];
    if ([property isEqualToString:NSImageCurrentFrame]) {
        // Access the image source
        CGImageSourceRef imageSource = _imageSource;
        if (!imageSource) {
            return;
        }
        // Check format type
        CFStringRef type = CGImageSourceGetType(imageSource);
        if (!type) {
            return;
        }
        NSUInteger index = [value unsignedIntegerValue];
        float frameDuration = 0;
        // Through we currently process GIF only, in the 5.x we support APNG so we keep the extensibility
        if (CFStringCompare(type, kUTTypeGIF, 0) == kCFCompareEqualTo) {
            frameDuration = [[SDWebImageGIFCoder sharedCoder] sd_frameDurationAtIndex:index source:imageSource];
        }
        if (!frameDuration) {
            return;
        }
        // Reset super frame duration with the actual frame duration
        [super setProperty:NSImageCurrentFrameDuration withValue:@(frameDuration)];
    }
}

@end

#endif
