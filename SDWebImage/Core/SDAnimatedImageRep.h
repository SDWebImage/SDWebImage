/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_MAC

#import "NSData+ImageContentType.h"

/**
 A subclass of `NSBitmapImageRep` to fix that GIF duration issue because `NSBitmapImageRep` will reset `NSImageCurrentFrameDuration` by using `kCGImagePropertyGIFDelayTime` but not `kCGImagePropertyGIFUnclampedDelayTime`.
 This also fix the GIF loop count issue, which will use the Netscape standard (See http://www6.uniovi.es/gifanim/gifabout.htm)  to only place once when the `kCGImagePropertyGIFLoopCount` is nil. This is what modern browser's behavior.
 Built in GIF coder use this instead of `NSBitmapImageRep` for better GIF rendering. If you do not want this, only enable `SDImageIOCoder`, which just call `NSImage` API and actually use `NSBitmapImageRep` for GIF image.
 This also support APNG format using `SDImageAPNGCoder`. Which provide full alpha-channel support and the correct duration match the `kCGImagePropertyAPNGUnclampedDelayTime`.
 */
@interface SDAnimatedImageRep : NSBitmapImageRep

/// Current animated image format.
/// @note This format is only valid when `animatedImageData` not nil
@property (nonatomic, assign, readonly) SDImageFormat animatedImageFormat;

/// This allows to retrive the compressed data like GIF using `sd_imageData` on parent `NSImage`, without re-encoding (waste CPU and RAM)
/// @note This is typically nonnull when you create with `initWithData:`, even it's marked as weak, because ImageIO retain it
@property (nonatomic, readonly, nullable, weak) NSData *animatedImageData;

@end

#endif
