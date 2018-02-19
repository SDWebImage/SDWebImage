/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

typedef NS_ENUM(NSUInteger, SDImageScaleMode) {
    SDImageScaleModeFill = 0,
    SDImageScaleModeAspectFit = 1,
    SDImageScaleModeAspectFill = 2
};

#if SD_UIKIT || SD_WATCH
typedef UIRectCorner SDRectCorner;
#else
typedef NS_OPTIONS(NSUInteger, SDRectCorner) {
    SDRectCornerTopLeft     = 1 << 0,
    SDRectCornerTopRight    = 1 << 1,
    SDRectCornerBottomLeft  = 1 << 2,
    SDRectCornerBottomRight = 1 << 3,
    SDRectCornerAllCorners  = ~0UL
};
#endif

#pragma mark - Useful category

@interface UIColor (Additions)

/**
 Convenience way to get hex string from color. The output should always be 32-bit hex string like `#00000000`.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *sd_hexString;

@end

#if SD_MAC
@interface NSBezierPath (Additions)

/**
 Convenience way to create a bezier path with the specify rouunding corners on macOS. Same as the one on `UIBezierPath`.
 */
+ (nonnull instancetype)sd_bezierPathWithRoundedRect:(NSRect)rect byRoundingCorners:(SDRectCorner)corners cornerRadius:(CGFloat)cornerRadius;

@end
#endif

/**
 Provide some commen method for `UIImage`.
 Image process is based on Core Graphics and vImage.
 */
@interface UIImage (Transform)

#pragma mark - Image Geometry

/**
 Returns a new image which is scaled from this image.
 The image content will be changed with the scale mode.
 
 @param size        The new size to be scaled, values should be positive.
 @param scaleMode   The scale mode for image content.
 @return The new image with the given size.
 */
- (nullable UIImage *)sd_resizedImageWithSize:(CGSize)size scaleMode:(SDImageScaleMode)scaleMode;

/**
 Returns a new image which is cropped from this image.
 
 @param rect     Image's inner rect.
 @return         The new image with the cropping rect.
 */
- (nullable UIImage *)sd_croppedImageWithRect:(CGRect)rect;

/**
 Rounds a new image with a given corner radius and corners.
 
 @param cornerRadius The radius of each corner oval. Values larger than half the
 rectangle's width or height are clamped appropriately to
 half the width or height.
 @param corners      A bitmask value that identifies the corners that you want
 rounded. You can use this parameter to round only a subset
 of the corners of the rectangle.
 @param borderWidth  The inset border line width. Values larger than half the rectangle's
 width or height are clamped appropriately to half the width
 or height.
 @param borderColor  The border stroke color. nil means clear color.
 @return The new image with the round corner.
 */
- (nullable UIImage *)sd_roundedCornerImageWithRadius:(CGFloat)cornerRadius
                                              corners:(SDRectCorner)corners
                                          borderWidth:(CGFloat)borderWidth
                                          borderColor:(nullable UIColor *)borderColor;

/**
 Returns a new rotated image (relative to the center).
 
 @param angle     Rotated radians in counterclockwise.⟲
 @param fitSize   YES: new image's size is extend to fit all content.
                  NO: image's size will not change, content may be clipped.
 @return The new image with the rotation.
 */
- (nullable UIImage *)sd_rotatedImageWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize;

/**
 Returns a new horizontally(vertically) flipped image.
 
 @param horizontal YES to flip the image horizontally. ⇋
 @param vertical YES to flip the image vertically. ⥯
 @return The new image with the flipping.
 */
- (nullable UIImage *)sd_flippedImageWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical;

#pragma mark - Image Blending

/**
 Return a tinted image in alpha channel with the given color.
 
 @param tintColor  The color.
 @return The new image with the tint color.
 */
- (nullable UIImage *)sd_tintedImageWithColor:(nonnull UIColor *)tintColor;

/**
 Return the color at specify pixel. The postion is from the top-left to the bottom-right. And the color is always be RGBA format.

 @param point The position of pixel
 @return The color for specify pixel, or nil if any error occur
 */
- (nullable UIColor *)sd_colorAtPoint:(CGPoint)point;

#pragma mark - Image Effect

/**
 Return a new image applied a blur effect.
 
 @param blurRadius     The radius of the blur in points, 0 means no blur effect.
 
 @return               The new image with blur effect, or nil if an error occurs (e.g. no enough memory).
 */
- (nullable UIImage *)sd_blurredImageWithRadius:(CGFloat)blurRadius;

#if SD_UIKIT || SD_MAC
/**
 Return a new image applied a CIFilter.

 @param filter The CIFilter to be applied to the image.
 @return The new image with the CIFilter, or nil if an error occurs (e.g. no
 enough memory).
 */
- (nullable UIImage *)sd_filteredImageWithFilter:(nonnull CIFilter *)filter;
#endif

@end
