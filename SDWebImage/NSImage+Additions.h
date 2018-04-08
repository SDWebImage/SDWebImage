/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

// This category is provided to easily write cross-platform(AppKit/UIKit) code. For common usage, see `UIImage+WebCache`.

#if SD_MAC

@interface NSImage (Additions)

/**
The underlying Core Graphics image object. This will actually `CGImageForProposedRect` with the image size.
 */
@property (nonatomic, readonly, nullable) CGImageRef CGImage;
/**
 The scale factor of the image. This wil actually use image size, and its `CGImage`'s pixel size to calculate the scale factor. Should be greater than or equal to 1.0.
 */
@property (nonatomic, readonly) CGFloat scale;

// These are convenience methods to make AppKit's `NSImage` match UIKit's `UIImage` behavior. The scale factor should be greater than or equal to 1.0.

/**
 Returns an image object with the scale factor. The representation is created from the Core Graphics image object.
 @note The difference between this and `initWithCGImage:size` is that `initWithCGImage:size` will create a `NSCGImageSnapshotRep` but not `NSBitmapImageRep` instance. And it will always `backingScaleFactor` as scale factor.

 @param cgImage A Core Graphics image object
 @param scale The image scale factor
 @return The image object
 */
- (nonnull instancetype)initWithCGImage:(nonnull CGImageRef)cgImage scale:(CGFloat)scale;

/**
 Returns an image object with the scale factor. The representation is created from the image data.
 @note The difference between these this and `initWithData:` is that `initWithData:` will always `backingScaleFactor` as scale factor.

 @param data The image data
 @param scale The image scale factor
 @return The image object
 */
- (nullable instancetype)initWithData:(nonnull NSData *)data scale:(CGFloat)scale;

@end

@interface NSBitmapImageRep (Additions)

// These method's function is the same as `NSImage`'s function. For `NSBitmapImageRep`.
- (nonnull instancetype)initWithCGImage:(nonnull CGImageRef)cgImage scale:(CGFloat)scale;
- (nullable instancetype)initWithData:(nonnull NSData *)data scale:(CGFloat)scale;

@end

#endif
