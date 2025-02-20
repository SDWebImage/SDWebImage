/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "NSData+ImageContentType.h"
#import "SDImageCoder.h"

/**
 UIImage category for image metadata, including animation, loop count, format, incremental, etc.
 */
@interface UIImage (Metadata)

/**
 * UIKit:
 * For static image format, this value is always 0.
 * For animated image format, 0 means infinite looping.
 * Note that because of the limitations of categories this property can get out of sync if you create another instance with CGImage or other methods.
 * AppKit:
 * NSImage currently only support animated via `NSBitmapImageRep`(GIF) or `SDAnimatedImageRep`(APNG/GIF/WebP) unlike UIImage.
 * The getter of this property will get the loop count from animated imageRep
 * The setter of this property will set the loop count from animated imageRep
 * SDAnimatedImage:
 * Returns `animatedImageLoopCount`
 */
@property (nonatomic, assign) NSUInteger sd_imageLoopCount;

/**
 * UIKit:
 * Returns the `images`'s count by unapply the patch for the different frame durations. Which matches the real visible frame count when displaying on UIImageView.
 * See more in `SDImageCoderHelper.animatedImageWithFrames`.
 * Returns 1 for static image.
 * AppKit:
 * Returns the underlaying `NSBitmapImageRep` or `SDAnimatedImageRep` frame count.
 * Returns 1 for static image.
 * SDAnimatedImage:
 * Returns `animatedImageFrameCount` for animated image, 1 for static image.
 */
@property (nonatomic, assign, readonly) NSUInteger sd_imageFrameCount;

/**
 * UIKit:
 * Check the `images` array property.
 * AppKit:
 * NSImage currently only support animated via GIF imageRep unlike UIImage. It will check the imageRep's frame count > 1.
 * SDAnimatedImage:
 * Check `animatedImageFrameCount` > 1
 */
@property (nonatomic, assign, readonly) BOOL sd_isAnimated;

/**
 * UIKit:
 * Check the `isSymbolImage` property. Also check the system PDF(iOS 11+) && SVG(iOS 13+) support.
 * AppKit:
 * NSImage supports PDF && SVG && EPS imageRep, check the imageRep class.
 * SDAnimatedImage:
 * Returns `NO`
 */
@property (nonatomic, assign, readonly) BOOL sd_isVector;

/**
 * The image format represent the original compressed image data format.
 * If you don't manually specify a format, this information is retrieve from CGImage using `CGImageGetUTType`, which may return nil for non-CG based image. At this time it will return `SDImageFormatUndefined` as default value.
 * @note Note that because of the limitations of categories this property can get out of sync if you create another instance with CGImage or other methods.
 * @note For `SDAnimatedImage`, returns `animatedImageFormat` when animated, or fallback when static.
 */
@property (nonatomic, assign) SDImageFormat sd_imageFormat;

/**
 A bool value indicating whether the image is during incremental decoding and may not contains full pixels.
 */
@property (nonatomic, assign) BOOL sd_isIncremental;

/**
 A bool value indicating that the image is transformed from original image, so the image data may not always match original download one.
 */
@property (nonatomic, assign) BOOL sd_isTransformed;

/**
 A bool value indicating that the image is using thumbnail decode with smaller size, so the image data may not always match original download one.
 @note This just check `sd_decodeOptions[.decodeThumbnailPixelSize] > CGSize.zero`
 */
@property (nonatomic, assign, readonly) BOOL sd_isThumbnail;

/**
 A dictionary value contains the decode options when decoded from SDWebImage loading system (say, `SDImageCacheDecodeImageData/SDImageLoaderDecode[Progressive]ImageData`)
 It may not always available and only image decoding related options will be saved. (including [.decodeScaleFactor, .decodeThumbnailPixelSize, .decodePreserveAspectRatio, .decodeFirstFrameOnly])
 @note This is used to identify and check the image is from thumbnail decoding, and the callback's data **will be nil** (because this time the data saved to disk does not match the image return to you. If you need full size data, query the cache with full size url key)
 @warning You should not store object inside which keep strong reference to image itself, which will cause retain cycle.
 @warning This API exist only because of current SDWebImageDownloader bad design which does not callback the context we call it. There will be refactor in future (API break), use with caution.
 */
@property (nonatomic, copy) SDImageCoderOptions *sd_decodeOptions;

/**
 A bool value indicating that the image is using HDR
 @note Only valid for CGImage based, for CIImage based, the returned value is not correct.
 */
@property (nonatomic, assign, readonly) BOOL sd_isHighDynamicRange;

@end
