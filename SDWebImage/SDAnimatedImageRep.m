/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDAnimatedImageRep.h"

#if SD_MAC

#import "SDImageGIFCoderInternal.h"
#import "SDImageAPNGCoderInternal.h"

@interface SDAnimatedImageRep ()

@property (nonatomic, assign, readonly, nullable) CGImageSourceRef imageSource;

@end

@implementation SDAnimatedImageRep

// `NSBitmapImageRep`'s `imageRepWithData:` is not designed initlizer
+ (instancetype)imageRepWithData:(NSData *)data {
    SDAnimatedImageRep *imageRep = [[SDAnimatedImageRep alloc] initWithData:data];
    return imageRep;
}

// We should override init method for `NSBitmapImageRep` to do initlize about animated image format
- (instancetype)initWithData:(NSData *)data {
    self = [super initWithData:data];
    if (self) {
        CGImageSourceRef imageSource = self.imageSource;
        if (!imageSource) {
            return self;
        }
        NSUInteger frameCount = CGImageSourceGetCount(imageSource);
        if (frameCount <= 1) {
            return self;
        }
        CFStringRef type = CGImageSourceGetType(imageSource);
        if (!type) {
            return self;
        }
        if (CFStringCompare(type, kUTTypeGIF, 0) == kCFCompareEqualTo) {
            // GIF
            // Do nothing because NSBitmapImageRep support it
        } else if (CFStringCompare(type, kUTTypePNG, 0) == kCFCompareEqualTo) {
            // APNG
            // Do initilize about frame count, current frame/duration and loop count
            [self setProperty:NSImageFrameCount withValue:@(frameCount)];
            [self setProperty:NSImageCurrentFrame withValue:@(0)];
            NSUInteger loopCount = [[SDImageAPNGCoder sharedCoder] sd_imageLoopCountWithSource:imageSource];
            [self setProperty:NSImageLoopCount withValue:@(loopCount)];
        }
    }
    return self;
}

// `NSBitmapImageRep` will use `kCGImagePropertyGIFDelayTime` whenever you call `setProperty:withValue:` with `NSImageCurrentFrame` to change the current frame. We override it and use the actual `kCGImagePropertyGIFUnclampedDelayTime` if need.
- (void)setProperty:(NSBitmapImageRepPropertyKey)property withValue:(id)value {
    [super setProperty:property withValue:value];
    if ([property isEqualToString:NSImageCurrentFrame]) {
        // Access the image source
        CGImageSourceRef imageSource = self.imageSource;
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
        if (CFStringCompare(type, kUTTypeGIF, 0) == kCFCompareEqualTo) {
            // GIF
            frameDuration = [[SDImageGIFCoder sharedCoder] sd_frameDurationAtIndex:index source:imageSource];
        } else if (CFStringCompare(type, kUTTypePNG, 0) == kCFCompareEqualTo) {
            // APNG
            frameDuration = [[SDImageAPNGCoder sharedCoder] sd_frameDurationAtIndex:index source:imageSource];
        }
        if (!frameDuration) {
            return;
        }
        // Reset super frame duration with the actual frame duration
        [super setProperty:NSImageCurrentFrameDuration withValue:@(frameDuration)];
    }
}

- (CGImageSourceRef)imageSource {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
    if (_tiffData) {
        return (__bridge CGImageSourceRef)(_tiffData);
    }
#pragma GCC diagnostic pop
    return NULL;
}

@end

#endif
