/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <ImageIO/ImageIO.h>
#import "SDWebImageCompat.h"
#import "SDImageFrame.h"

typedef NS_ENUM(NSUInteger, SDImageCoderDecodeSolution) {
    /// automatically choose the solution based on image format, hardware, OS version. This keep balance for compatibility and performance. Default after SDWebImage 5.13.0
    SDImageCoderDecodeSolutionAutomatic,
    /// always use CoreGraphics to draw on bitmap context and trigger decode. Best compatibility. Default before SDWebImage 5.13.0
    SDImageCoderDecodeSolutionCoreGraphics,
    /// available on iOS/tvOS 15+, use UIKit's new CGImageDecompressor/CMPhoto to decode. Best performance. If failed, will fallback to CoreGraphics as well
    SDImageCoderDecodeSolutionUIKit
};

/**
 Provide some common helper methods for building the image decoder/encoder.
 */
@interface SDImageCoderHelper : NSObject

/**
 Return an animated image with frames array.
 For UIKit, this will apply the patch and then create animated UIImage. The patch is because that `+[UIImage animatedImageWithImages:duration:]` just use the average of duration for each image. So it will not work if different frame has different duration. Therefore we repeat the specify frame for specify times to let it work.
 For AppKit, NSImage does not support animates other than GIF. This will try to encode the frames to GIF format and then create an animated NSImage for rendering. Attention the animated image may loss some detail if the input frames contain full alpha channel because GIF only supports 1 bit alpha channel. (For 1 pixel, either transparent or not)

 @param frames The frames array. If no frames or frames is empty, return nil
 @return A animated image for rendering on UIImageView(UIKit) or NSImageView(AppKit)
 */
+ (UIImage * _Nullable)animatedImageWithFrames:(NSArray<SDImageFrame *> * _Nullable)frames;

/**
 Return frames array from an animated image.
 For UIKit, this will unapply the patch for the description above and then create frames array. This will also work for normal animated UIImage.
 For AppKit, NSImage does not support animates other than GIF. This will try to decode the GIF imageRep and then create frames array.

 @param animatedImage A animated image. If it's not animated, return nil
 @return The frames array
 */
+ (NSArray<SDImageFrame *> * _Nullable)framesFromAnimatedImage:(UIImage * _Nullable)animatedImage NS_SWIFT_NAME(frames(from:));

/**
 Return the shared device-dependent RGB color space. This follows The Get Rule.
 On iOS, it's created with deviceRGB (if available, use sRGB).
 On macOS, it's from the screen colorspace (if failed, use deviceRGB)
 Because it's shared, you should not retain or release this object.
 
 @return The device-dependent RGB color space
 */
+ (CGColorSpaceRef _Nonnull)colorSpaceGetDeviceRGB CF_RETURNS_NOT_RETAINED;

/**
 Check whether CGImage contains alpha channel.
 
 @param cgImage The CGImage
 @return Return YES if CGImage contains alpha channel, otherwise return NO
 */
+ (BOOL)CGImageContainsAlpha:(_Nonnull CGImageRef)cgImage;

/**
 Create a decoded CGImage by the provided CGImage. This follows The Create Rule and you are response to call release after usage.
 It will detect whether image contains alpha channel, then create a new bitmap context with the same size of image, and draw it. This can ensure that the image do not need extra decoding after been set to the imageView.
 @note This actually call `CGImageCreateDecoded:orientation:` with the Up orientation.

 @param cgImage The CGImage
 @return A new created decoded image
 */
+ (CGImageRef _Nullable)CGImageCreateDecoded:(_Nonnull CGImageRef)cgImage CF_RETURNS_RETAINED;

/**
 Create a decoded CGImage by the provided CGImage and orientation. This follows The Create Rule and you are response to call release after usage.
 It will detect whether image contains alpha channel, then create a new bitmap context with the same size of image, and draw it. This can ensure that the image do not need extra decoding after been set to the imageView.
 
 @param cgImage The CGImage
 @param orientation The EXIF image orientation.
 @return A new created decoded image
 */
+ (CGImageRef _Nullable)CGImageCreateDecoded:(_Nonnull CGImageRef)cgImage orientation:(CGImagePropertyOrientation)orientation CF_RETURNS_RETAINED;

/**
 Create a scaled CGImage by the provided CGImage and size. This follows The Create Rule and you are response to call release after usage.
 It will detect whether the image size matching the scale size, if not, stretch the image to the target size.
 @note If you need to keep aspect ratio, you can calculate the scale size by using `scaledSizeWithImageSize` first.
 
 @param cgImage The CGImage
 @param size The scale size in pixel.
 @return A new created scaled image
 */
+ (CGImageRef _Nullable)CGImageCreateScaled:(_Nonnull CGImageRef)cgImage size:(CGSize)size CF_RETURNS_RETAINED;

/** Scale the image size based on provided scale size, whether or not to preserve aspect ratio, whether or not to scale up.
 @note For example, if you implements thumnail decoding, pass `shouldScaleUp` to NO to avoid the calculated size larger than image size.
 
 @param imageSize The image size (in pixel or point defined by caller)
 @param scaleSize The scale size (in pixel or point defined by caller)
 @param preserveAspectRatio Whether or not to preserve aspect ratio
 @param shouldScaleUp Whether or not to scale up (or scale down only)
 */
+ (CGSize)scaledSizeWithImageSize:(CGSize)imageSize scaleSize:(CGSize)scaleSize preserveAspectRatio:(BOOL)preserveAspectRatio shouldScaleUp:(BOOL)shouldScaleUp;

/**
 Return the decoded image by the provided image. This one unlike `CGImageCreateDecoded:`, will not decode the image which contains alpha channel or animated image. On iOS 15+, this may use `UIImage.preparingForDisplay()` to use CMPhoto for better performance than the old solution.
 @param image The image to be decoded
 @return The decoded image
 */
+ (UIImage * _Nullable)decodedImageWithImage:(UIImage * _Nullable)image;

/**
 Return the decoded and probably scaled down image by the provided image. If the image pixels bytes size large than the limit bytes, will try to scale down. Or just works as `decodedImageWithImage:`, never scale up.
 @warning You should not pass too small bytes, the suggestion value should be larger than 1MB. Even we use Tile Decoding to avoid OOM, however, small bytes will consume much more CPU time because we need to iterate more times to draw each tile.

 @param image The image to be decoded and scaled down
 @param bytes The limit bytes size. Provide 0 to use the build-in limit.
 @return The decoded and probably scaled down image
 */
+ (UIImage * _Nullable)decodedAndScaledDownImageWithImage:(UIImage * _Nullable)image limitBytes:(NSUInteger)bytes;

/**
 Control the default force decode solution. Available solutions  in `SDImageCoderDecodeSolution`.
 @note Defaults to `SDImageCoderDecodeSolutionAutomatic`, which prefers to use UIKit for JPEG/HEIF, and fallback on CoreGraphics. If you want control on your hand, set the other solution.
 */
@property (class, readwrite) SDImageCoderDecodeSolution defaultDecodeSolution;

/**
 Control the default limit bytes to scale down largest images.
 This value must be larger than 4 Bytes (at least 1x1 pixel). Defaults to 60MB on iOS/tvOS, 90MB on macOS, 30MB on watchOS.
 */
@property (class, readwrite) NSUInteger defaultScaleDownLimitBytes;

#if SD_UIKIT || SD_WATCH
/**
 Convert an EXIF image orientation to an iOS one.

 @param exifOrientation EXIF orientation
 @return iOS orientation
 */
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(CGImagePropertyOrientation)exifOrientation NS_SWIFT_NAME(imageOrientation(from:));

/**
 Convert an iOS orientation to an EXIF image orientation.

 @param imageOrientation iOS orientation
 @return EXIF orientation
 */
+ (CGImagePropertyOrientation)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation;
#endif

@end
