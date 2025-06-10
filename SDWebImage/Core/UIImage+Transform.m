/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+Transform.h"
#import "NSImage+Compatibility.h"
#import "SDImageGraphics.h"
#import "SDGraphicsImageRenderer.h"
#import "NSBezierPath+SDRoundedCorners.h"
#import "SDInternalMacros.h"
#import <Accelerate/Accelerate.h>
#if SD_UIKIT || SD_MAC
#import <CoreImage/CoreImage.h>
#endif

static inline CGRect SDCGRectFitWithScaleMode(CGRect rect, CGSize size, SDImageScaleMode scaleMode) {
    rect = CGRectStandardize(rect);
    size.width = size.width < 0 ? -size.width : size.width;
    size.height = size.height < 0 ? -size.height : size.height;
    CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    switch (scaleMode) {
        case SDImageScaleModeAspectFit:
        case SDImageScaleModeAspectFill: {
            if (rect.size.width < 0.01 || rect.size.height < 0.01 ||
                size.width < 0.01 || size.height < 0.01) {
                rect.origin = center;
                rect.size = CGSizeZero;
            } else {
                CGFloat scale;
                if (scaleMode == SDImageScaleModeAspectFit) {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.height / size.height;
                    } else {
                        scale = rect.size.width / size.width;
                    }
                } else {
                    if (size.width / size.height < rect.size.width / rect.size.height) {
                        scale = rect.size.width / size.width;
                    } else {
                        scale = rect.size.height / size.height;
                    }
                }
                size.width *= scale;
                size.height *= scale;
                rect.size = size;
                rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
            }
        } break;
        case SDImageScaleModeFill:
        default: {
            rect = rect;
        }
    }
    return rect;
}

static inline UIColor * SDGetColorFromGrayscale(Pixel_88 pixel, CGBitmapInfo bitmapInfo, CGColorSpaceRef cgColorSpace) {
    // Get alpha info, byteOrder info
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    CGFloat w = 0, a = 1;
    
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    switch (alphaInfo) {
        case kCGImageAlphaPremultipliedFirst:
        case kCGImageAlphaFirst: {
            if (byteOrderNormal) {
                // AW
                a = pixel[0] / 255.0;
                w = pixel[1] / 255.0;
            } else {
                // WA
                w = pixel[0] / 255.0;
                a = pixel[1] / 255.0;
            }
        }
            break;
        case kCGImageAlphaPremultipliedLast:
        case kCGImageAlphaLast: {
            if (byteOrderNormal) {
                // WA
                w = pixel[0] / 255.0;
                a = pixel[1] / 255.0;
            } else {
                // AW
                a = pixel[0] / 255.0;
                w = pixel[1] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNone: {
            // W
            w = pixel[0] / 255.0;
        }
            break;
        case kCGImageAlphaNoneSkipLast: {
            if (byteOrderNormal) {
                // WX
                w = pixel[0] / 255.0;
            } else {
                // XW
                a = pixel[1] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNoneSkipFirst: {
            if (byteOrderNormal) {
                // XW
                a = pixel[1] / 255.0;
            } else {
                // WX
                a = pixel[0] / 255.0;
            }
        }
            break;
        case kCGImageAlphaOnly: {
            // A
            a = pixel[0] / 255.0;
        }
            break;
        default:
            break;
    }
#if SD_MAC
    // Mac supports ColorSync, to ensure the same bahvior, we convert color to sRGB
    NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:cgColorSpace];
    CGFloat components[2] = {w, a};
    NSColor *color = [NSColor colorWithColorSpace:colorSpace components:components count:2];
    return [color colorUsingColorSpace:NSColorSpace.genericGamma22GrayColorSpace];
#else
    return [UIColor colorWithWhite:w alpha:a];
#endif
}

static inline UIColor * SDGetColorFromRGBA8(Pixel_8888 pixel, CGBitmapInfo bitmapInfo, CGColorSpaceRef cgColorSpace) {
    // Get alpha info, byteOrder info
    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    CGFloat r = 0, g = 0, b = 0, a = 1;
    
    BOOL byteOrderNormal = NO;
    switch (byteOrderInfo) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder16Little:
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder16Big:
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    switch (alphaInfo) {
        case kCGImageAlphaPremultipliedFirst: {
            if (byteOrderNormal) {
                // ARGB8888-premultiplied
                a = pixel[0] / 255.0;
                r = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                b = pixel[3] / 255.0;
                if (a > 0) {
                    r /= a;
                    g /= a;
                    b /= a;
                }
            } else {
                // BGRA8888-premultiplied
                b = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                r = pixel[2] / 255.0;
                a = pixel[3] / 255.0;
                if (a > 0) {
                    r /= a;
                    g /= a;
                    b /= a;
                }
            }
            break;
        }
        case kCGImageAlphaFirst: {
            if (byteOrderNormal) {
                // ARGB8888
                a = pixel[0] / 255.0;
                r = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                b = pixel[3] / 255.0;
            } else {
                // BGRA8888
                b = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                r = pixel[2] / 255.0;
                a = pixel[3] / 255.0;
            }
        }
            break;
        case kCGImageAlphaPremultipliedLast: {
            if (byteOrderNormal) {
                // RGBA8888-premultiplied
                r = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                b = pixel[2] / 255.0;
                a = pixel[3] / 255.0;
                if (a > 0) {
                    r /= a;
                    g /= a;
                    b /= a;
                }
            } else {
                // ABGR8888-premultiplied
                a = pixel[0] / 255.0;
                b = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                r = pixel[3] / 255.0;
                if (a > 0) {
                    r /= a;
                    g /= a;
                    b /= a;
                }
            }
            break;
        }
        case kCGImageAlphaLast: {
            if (byteOrderNormal) {
                // RGBA8888
                r = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                b = pixel[2] / 255.0;
                a = pixel[3] / 255.0;
            } else {
                // ABGR8888
                a = pixel[0] / 255.0;
                b = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                r = pixel[3] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNone: {
            if (byteOrderNormal) {
                // RGB
                r = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                b = pixel[2] / 255.0;
            } else {
                // BGR
                b = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                r = pixel[2] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNoneSkipLast: {
            if (byteOrderNormal) {
                // RGBX
                r = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                b = pixel[2] / 255.0;
            } else {
                // XBGR
                b = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                r = pixel[3] / 255.0;
            }
        }
            break;
        case kCGImageAlphaNoneSkipFirst: {
            if (byteOrderNormal) {
                // XRGB
                r = pixel[1] / 255.0;
                g = pixel[2] / 255.0;
                b = pixel[3] / 255.0;
            } else {
                // BGRX
                b = pixel[0] / 255.0;
                g = pixel[1] / 255.0;
                r = pixel[2] / 255.0;
            }
        }
            break;
        case kCGImageAlphaOnly: {
            // A
            a = pixel[0] / 255.0;
        }
            break;
        default:
            break;
    }
#if SD_MAC
    // Mac supports ColorSync, to ensure the same bahvior, we convert color to sRGB
    NSColorSpace *colorSpace = [[NSColorSpace alloc] initWithCGColorSpace:cgColorSpace];
    CGFloat components[4] = {r, g, b, a};
    NSColor *color = [NSColor colorWithColorSpace:colorSpace components:components count:4];
    return [color colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
#else
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
#endif
}

#if SD_UIKIT || SD_MAC
// Create-Rule, caller should call CGImageRelease
static inline CGImageRef _Nullable SDCreateCGImageFromCIImage(CIImage * _Nonnull ciImage) {
    CGImageRef imageRef = NULL;
    if (@available(iOS 10, macOS 10.12, tvOS 10, *)) {
        imageRef = ciImage.CGImage;
    }
    if (!imageRef) {
        CIContext *context = [CIContext context];
        imageRef = [context createCGImage:ciImage fromRect:ciImage.extent];
    } else {
        CGImageRetain(imageRef);
    }
    return imageRef;
}
#endif

@implementation UIImage (Transform)

- (void)sd_drawInRect:(CGRect)rect context:(CGContextRef)context scaleMode:(SDImageScaleMode)scaleMode clipsToBounds:(BOOL)clips {
    CGRect drawRect = SDCGRectFitWithScaleMode(rect, self.size, scaleMode);
    if (drawRect.size.width == 0 || drawRect.size.height == 0) return;
    if (clips) {
        if (context) {
            CGContextSaveGState(context);
            CGContextAddRect(context, rect);
            CGContextClip(context);
            [self drawInRect:drawRect];
            CGContextRestoreGState(context);
        }
    } else {
        [self drawInRect:drawRect];
    }
}

- (nullable UIImage *)sd_resizedImageWithSize:(CGSize)size scaleMode:(SDImageScaleMode)scaleMode {
    if (size.width <= 0 || size.height <= 0) return nil;
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        [self sd_drawInRect:CGRectMake(0, 0, size.width, size.height) context:context scaleMode:scaleMode clipsToBounds:NO];
    }];
    return image;
}

- (nullable UIImage *)sd_croppedImageWithRect:(CGRect)rect {
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    
#if SD_UIKIT || SD_MAC
    // CIImage shortcut
    if (self.CIImage) {
        CGRect croppingRect = CGRectMake(rect.origin.x, self.size.height - CGRectGetMaxY(rect), rect.size.width, rect.size.height);
        CIImage *ciImage = [self.CIImage imageByCroppingToRect:croppingRect];
#if SD_UIKIT
        UIImage *image = [UIImage imageWithCIImage:ciImage scale:self.scale orientation:self.imageOrientation];
#else
        UIImage *image = [[UIImage alloc] initWithCIImage:ciImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
        return image;
    }
#endif
    
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(imageRef, rect);
    if (!croppedImageRef) {
        return nil;
    }
#if SD_UIKIT || SD_WATCH
    UIImage *image = [UIImage imageWithCGImage:croppedImageRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:croppedImageRef scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(croppedImageRef);
    return image;
}

- (nullable UIImage *)sd_roundedCornerImageWithRadius:(CGFloat)cornerRadius corners:(SDRectCorner)corners borderWidth:(CGFloat)borderWidth borderColor:(nullable UIColor *)borderColor {
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:self.size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
        
        CGFloat minSize = MIN(self.size.width, self.size.height);
        if (borderWidth < minSize / 2) {
#if SD_UIKIT || SD_WATCH
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, borderWidth, borderWidth) byRoundingCorners:corners cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
#else
            NSBezierPath *path = [NSBezierPath sd_bezierPathWithRoundedRect:CGRectInset(rect, borderWidth, borderWidth) byRoundingCorners:corners cornerRadius:cornerRadius];
#endif
            [path closePath];
            
            CGContextSaveGState(context);
            [path addClip];
            [self drawInRect:rect];
            CGContextRestoreGState(context);
        }
        
        if (borderColor && borderWidth < minSize / 2 && borderWidth > 0) {
            CGFloat strokeInset = (floor(borderWidth * self.scale) + 0.5) / self.scale;
            CGRect strokeRect = CGRectInset(rect, strokeInset, strokeInset);
            CGFloat strokeRadius = cornerRadius > self.scale / 2 ? cornerRadius - self.scale / 2 : 0;
#if SD_UIKIT || SD_WATCH
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:strokeRect byRoundingCorners:corners cornerRadii:CGSizeMake(strokeRadius, strokeRadius)];
#else
            NSBezierPath *path = [NSBezierPath sd_bezierPathWithRoundedRect:strokeRect byRoundingCorners:corners cornerRadius:strokeRadius];
#endif
            [path closePath];
            
            path.lineWidth = borderWidth;
            [borderColor setStroke];
            [path stroke];
        }
    }];
    return image;
}

- (nullable UIImage *)sd_rotatedImageWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize {
    size_t width = self.size.width;
    size_t height = self.size.height;
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0, 0, width, height),
                                                fitSize ? CGAffineTransformMakeRotation(angle) : CGAffineTransformIdentity);

#if SD_UIKIT || SD_MAC
    // CIImage shortcut
    if (self.CIImage) {
        CIImage *ciImage = self.CIImage;
        if (fitSize) {
            CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
            ciImage = [ciImage imageByApplyingTransform:transform];
        } else {
            CIFilter *filter = [CIFilter filterWithName:@"CIStraightenFilter"];
            [filter setValue:ciImage forKey:kCIInputImageKey];
            [filter setValue:@(angle) forKey:kCIInputAngleKey];
            ciImage = filter.outputImage;
        }
#if SD_UIKIT || SD_WATCH
        UIImage *image = [UIImage imageWithCIImage:ciImage scale:self.scale orientation:self.imageOrientation];
#else
        UIImage *image = [[UIImage alloc] initWithCIImage:ciImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
        return image;
    }
#endif
    
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:newRect.size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        CGContextSetShouldAntialias(context, true);
        CGContextSetAllowsAntialiasing(context, true);
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
#if SD_UIKIT || SD_WATCH
        // Use UIKit coordinate system counterclockwise (⟲)
        CGContextRotateCTM(context, -angle);
#else
        CGContextRotateCTM(context, angle);
#endif
        
        [self drawInRect:CGRectMake(-(width * 0.5), -(height * 0.5), width, height)];
    }];
    return image;
}

- (nullable UIImage *)sd_flippedImageWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical {
    size_t width = self.size.width;
    size_t height = self.size.height;

#if SD_UIKIT || SD_MAC
    // CIImage shortcut
    if (self.CIImage) {
        CGAffineTransform transform = CGAffineTransformIdentity;
        // Use UIKit coordinate system
        if (horizontal) {
            CGAffineTransform flipHorizontal = CGAffineTransformMake(-1, 0, 0, 1, width, 0);
            transform = CGAffineTransformConcat(transform, flipHorizontal);
        }
        if (vertical) {
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, height);
            transform = CGAffineTransformConcat(transform, flipVertical);
        }
        CIImage *ciImage = [self.CIImage imageByApplyingTransform:transform];
#if SD_UIKIT
        UIImage *image = [UIImage imageWithCIImage:ciImage scale:self.scale orientation:self.imageOrientation];
#else
        UIImage *image = [[UIImage alloc] initWithCIImage:ciImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
        return image;
    }
#endif
    
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = self.scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:self.size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        // Use UIKit coordinate system
        if (horizontal) {
            CGAffineTransform flipHorizontal = CGAffineTransformMake(-1, 0, 0, 1, width, 0);
            CGContextConcatCTM(context, flipHorizontal);
        }
        if (vertical) {
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, height);
            CGContextConcatCTM(context, flipVertical);
        }
        [self drawInRect:CGRectMake(0, 0, width, height)];
    }];
    return image;
}

#pragma mark - Image Blending

#if SD_UIKIT || SD_MAC
static NSString * _Nullable SDGetCIFilterNameFromBlendMode(CGBlendMode blendMode) {
    // CGBlendMode: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html#//apple_ref/doc/uid/TP30001066-CH212-CJBIJEFG
    // CIFilter: https://developer.apple.com/library/archive/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html#//apple_ref/doc/uid/TP30000136-SW71
    NSString *filterName;
    switch (blendMode) {
        case kCGBlendModeMultiply:
            filterName = @"CIMultiplyBlendMode";
            break;
        case kCGBlendModeScreen:
            filterName = @"CIScreenBlendMode";
            break;
        case kCGBlendModeOverlay:
            filterName = @"CIOverlayBlendMode";
            break;
        case kCGBlendModeDarken:
            filterName = @"CIDarkenBlendMode";
            break;
        case kCGBlendModeLighten:
            filterName = @"CILightenBlendMode";
            break;
        case kCGBlendModeColorDodge:
            filterName = @"CIColorDodgeBlendMode";
            break;
        case kCGBlendModeColorBurn:
            filterName = @"CIColorBurnBlendMode";
            break;
        case kCGBlendModeSoftLight:
            filterName = @"CISoftLightBlendMode";
            break;
        case kCGBlendModeHardLight:
            filterName = @"CIHardLightBlendMode";
            break;
        case kCGBlendModeDifference:
            filterName = @"CIDifferenceBlendMode";
            break;
        case kCGBlendModeExclusion:
            filterName = @"CIExclusionBlendMode";
            break;
        case kCGBlendModeHue:
            filterName = @"CIHueBlendMode";
            break;
        case kCGBlendModeSaturation:
            filterName = @"CISaturationBlendMode";
            break;
        case kCGBlendModeColor:
            // Color blend mode uses the luminance values of the background with the hue and saturation values of the source image.
            filterName = @"CIColorBlendMode";
            break;
        case kCGBlendModeLuminosity:
            filterName = @"CILuminosityBlendMode";
            break;
            
        // macOS 10.5+
        case kCGBlendModeSourceAtop:
        case kCGBlendModeDestinationAtop:
            filterName = @"CISourceAtopCompositing";
            break;
        case kCGBlendModeSourceIn:
        case kCGBlendModeDestinationIn:
            filterName = @"CISourceInCompositing";
            break;
        case kCGBlendModeSourceOut:
        case kCGBlendModeDestinationOut:
            filterName = @"CISourceOutCompositing";
            break;
        case kCGBlendModeNormal: // SourceOver
        case kCGBlendModeDestinationOver:
            filterName = @"CISourceOverCompositing";
            break;
        
        // need special handling
        case kCGBlendModeClear:
            // use clear color instead
            break;
        case kCGBlendModeCopy:
            // use input color instead
            break;
        case kCGBlendModeXOR:
            // unsupported
            break;
        case kCGBlendModePlusDarker:
            // chain filters
            break;
        case kCGBlendModePlusLighter:
            // chain filters
            break;
    }
    return filterName;
}
#endif

- (nullable UIImage *)sd_tintedImageWithColor:(nonnull UIColor *)tintColor {
    return [self sd_tintedImageWithColor:tintColor blendMode:kCGBlendModeSourceIn];
}

- (nullable UIImage *)sd_tintedImageWithColor:(nonnull UIColor *)tintColor blendMode:(CGBlendMode)blendMode {
    BOOL hasTint = CGColorGetAlpha(tintColor.CGColor) > __FLT_EPSILON__;
    if (!hasTint) {
        return self;
    }
    
    // blend mode, see https://en.wikipedia.org/wiki/Alpha_compositing
#if SD_UIKIT || SD_MAC
    // CIImage shortcut
    CIImage *ciImage = self.CIImage;
    if (ciImage) {
        CIImage *colorImage = [CIImage imageWithColor:[[CIColor alloc] initWithColor:tintColor]];
        colorImage = [colorImage imageByCroppingToRect:ciImage.extent];
        NSString *filterName = SDGetCIFilterNameFromBlendMode(blendMode);
        // Some blend mode is not nativelly supported
        if (filterName) {
            CIFilter *filter = [CIFilter filterWithName:filterName];
            [filter setValue:colorImage forKey:kCIInputImageKey];
            [filter setValue:ciImage forKey:kCIInputBackgroundImageKey];
            ciImage = filter.outputImage;
        } else {
            if (blendMode == kCGBlendModeClear) {
                // R = 0
                CIColor *clearColor;
                if (@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)) {
                    clearColor = CIColor.clearColor;
                } else {
                    clearColor = [[CIColor alloc] initWithColor:UIColor.clearColor];
                }
                colorImage = [CIImage imageWithColor:clearColor];
                colorImage = [colorImage imageByCroppingToRect:ciImage.extent];
                ciImage = colorImage;
            } else if (blendMode == kCGBlendModeCopy) {
                // R = S
                ciImage = colorImage;
            } else if (blendMode == kCGBlendModePlusLighter) {
                // R = MIN(1, S + D)
                // S + D
                CIFilter *filter = [CIFilter filterWithName:@"CIAdditionCompositing"];
                [filter setValue:colorImage forKey:kCIInputImageKey];
                [filter setValue:ciImage forKey:kCIInputBackgroundImageKey];
                ciImage = filter.outputImage;
                // MIN
                ciImage = [ciImage imageByApplyingFilter:@"CIColorClamp" withInputParameters:nil];
            } else if (blendMode == kCGBlendModePlusDarker) {
                // R = MAX(0, (1 - D) + (1 - S))
                // (1 - D)
                CIFilter *filter1 = [CIFilter filterWithName:@"CIColorControls"];
                [filter1 setValue:ciImage forKey:kCIInputImageKey];
                [filter1 setValue:@(-0.5) forKey:kCIInputBrightnessKey];
                ciImage = filter1.outputImage;
                // (1 - S)
                CIFilter *filter2 = [CIFilter filterWithName:@"CIColorControls"];
                [filter2 setValue:colorImage forKey:kCIInputImageKey];
                [filter2 setValue:@(-0.5) forKey:kCIInputBrightnessKey];
                colorImage = filter2.outputImage;
                // +
                CIFilter *filter = [CIFilter filterWithName:@"CIAdditionCompositing"];
                [filter setValue:colorImage forKey:kCIInputImageKey];
                [filter setValue:ciImage forKey:kCIInputBackgroundImageKey];
                ciImage = filter.outputImage;
                // MAX
                ciImage = [ciImage imageByApplyingFilter:@"CIColorClamp" withInputParameters:nil];
            } else {
                SD_LOG("UIImage+Transform error: Unsupported blend mode: %d", blendMode);
                ciImage = nil;
            }
        }
        
        if (ciImage) {
#if SD_UIKIT
        UIImage *image = [UIImage imageWithCIImage:ciImage scale:self.scale orientation:self.imageOrientation];
#else
        UIImage *image = [[UIImage alloc] initWithCIImage:ciImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
        return image;
        }
    }
#endif
    
    CGSize size = self.size;
    CGRect rect = { CGPointZero, size };
    CGFloat scale = self.scale;
    
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] init];
    format.scale = scale;
    SDGraphicsImageRenderer *renderer = [[SDGraphicsImageRenderer alloc] initWithSize:size format:format];
    UIImage *image = [renderer imageWithActions:^(CGContextRef  _Nonnull context) {
        [self drawInRect:rect];
        CGContextSetBlendMode(context, blendMode);
        CGContextSetFillColorWithColor(context, tintColor.CGColor);
        CGContextFillRect(context, rect);
    }];
    return image;
}

- (nullable UIColor *)sd_colorAtPoint:(CGPoint)point {
    CGImageRef imageRef = NULL;
    // CIImage compatible
#if SD_UIKIT || SD_MAC
    if (self.CIImage) {
        imageRef = SDCreateCGImageFromCIImage(self.CIImage);
    }
#endif
    if (!imageRef) {
        imageRef = self.CGImage;
        CGImageRetain(imageRef);
    }
    if (!imageRef) {
        return nil;
    }
    
    // Check point
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t x = point.x;
    size_t y = point.y;
    if (x < 0 || y < 0 || x >= width || y >= height) {
        CGImageRelease(imageRef);
        return nil;
    }
    
    // Check pixel format
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    if (@available(iOS 12.0, tvOS 12.0, macOS 10.14, watchOS 5.0, *)) {
        CGImagePixelFormatInfo pixelFormat = (bitmapInfo & kCGImagePixelFormatMask);
        if (pixelFormat != kCGImagePixelFormatPacked || bitsPerComponent > 8) {
            // like RGBA1010102, need bitwise to extract pixel from single uint32_t, we don't support currently
            SD_LOG("Unsupported pixel format: %u, bpc: %zu for CGImage: %@", pixelFormat, bitsPerComponent, imageRef);
            CGImageRelease(imageRef);
            return nil;
        }
    }
    
    // Get pixels
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    if (!provider) {
        CGImageRelease(imageRef);
        return nil;
    }
    CFDataRef data = CGDataProviderCopyData(provider);
    if (!data) {
        CGImageRelease(imageRef);
        return nil;
    }
    
    // Get pixel at point
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    size_t components = CGImageGetBitsPerPixel(imageRef) / bitsPerComponent;
    
    CFRange range = CFRangeMake(bytesPerRow * y + components * x, components);
    if (CFDataGetLength(data) < range.location + range.length) {
        CFRelease(data);
        CGImageRelease(imageRef);
        return nil;
    }
    // Get color space for transform
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    
    // greyscale
    if (components == 2) {
        Pixel_88 pixel = {0};
        CFDataGetBytes(data, range, pixel);
        CFRelease(data);
        CGImageRelease(imageRef);
        // Convert to color
        return SDGetColorFromGrayscale(pixel, bitmapInfo, colorSpace);
    } else if (components == 3 || components == 4) {
        // RGB/RGBA
        Pixel_8888 pixel = {0};
        CFDataGetBytes(data, range, pixel);
        CFRelease(data);
        CGImageRelease(imageRef);
        // Convert to color
        return SDGetColorFromRGBA8(pixel, bitmapInfo, colorSpace);
    } else {
        SD_LOG("Unsupported components: %zu for CGImage: %@", components, imageRef);
        CFRelease(data);
        CGImageRelease(imageRef);
        return nil;
    }
}

- (nullable NSArray<UIColor *> *)sd_colorsWithRect:(CGRect)rect {
    CGImageRef imageRef = NULL;
    // CIImage compatible
#if SD_UIKIT || SD_MAC
    if (self.CIImage) {
        imageRef = SDCreateCGImageFromCIImage(self.CIImage);
    }
#endif
    if (!imageRef) {
        imageRef = self.CGImage;
        CGImageRetain(imageRef);
    }
    if (!imageRef) {
        return nil;
    }
    
    // Check rect
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    if (CGRectGetWidth(rect) <= 0 || CGRectGetHeight(rect) <= 0 || CGRectGetMinX(rect) < 0 || CGRectGetMinY(rect) < 0 || CGRectGetMaxX(rect) > width || CGRectGetMaxY(rect) > height) {
        CGImageRelease(imageRef);
        return nil;
    }
    
    // Check pixel format
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    if (@available(iOS 12.0, tvOS 12.0, macOS 10.14, watchOS 5.0, *)) {
        CGImagePixelFormatInfo pixelFormat = (bitmapInfo & kCGImagePixelFormatMask);
        if (pixelFormat != kCGImagePixelFormatPacked || bitsPerComponent > 8) {
            // like RGBA1010102, need bitwise to extract pixel from single uint32_t, we don't support currently
            SD_LOG("Unsupported pixel format: %u, bpc: %zu for CGImage: %@", pixelFormat, bitsPerComponent, imageRef);
            CGImageRelease(imageRef);
            return nil;
        }
    }
    
    // Get pixels
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    if (!provider) {
        CGImageRelease(imageRef);
        return nil;
    }
    CFDataRef data = CGDataProviderCopyData(provider);
    if (!data) {
        CGImageRelease(imageRef);
        return nil;
    }
    
    // Get pixels with rect
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef);
    size_t components = CGImageGetBitsPerPixel(imageRef) / bitsPerComponent;
    
    size_t start = bytesPerRow * CGRectGetMinY(rect) + components * CGRectGetMinX(rect);
    size_t end = bytesPerRow * (CGRectGetMaxY(rect) - 1) + components * CGRectGetMaxX(rect);
    if (CFDataGetLength(data) < (CFIndex)end) {
        CFRelease(data);
        CGImageRelease(imageRef);
        return nil;
    }
    
    const UInt8 *pixels = CFDataGetBytePtr(data);
    size_t row = CGRectGetMinY(rect);
    size_t col = CGRectGetMaxX(rect);
    
    // Convert to color
    NSMutableArray<UIColor *> *colors = [NSMutableArray arrayWithCapacity:CGRectGetWidth(rect) * CGRectGetHeight(rect)];
    // ColorSpace
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    for (size_t index = start; index < end; index += components) {
        if (index >= row * bytesPerRow + col * components) {
            // Index beyond the end of current row, go next row
            row++;
            index = row * bytesPerRow + CGRectGetMinX(rect) * components;
            index -= components;
            continue;
        }
        UIColor *color;
        if (components == 2) {
            Pixel_88 pixel = {pixels[index], pixel[index+1]};
            color = SDGetColorFromGrayscale(pixel, bitmapInfo, colorSpace);
        } else {
            if (components == 3) {
                Pixel_8888 pixel = {pixels[index], pixels[index+1], pixels[index+2], 0};
                color = SDGetColorFromRGBA8(pixel, bitmapInfo, colorSpace);
            } else if (components == 4) {
                Pixel_8888 pixel = {pixels[index], pixels[index+1], pixels[index+2], pixels[index+3]};
                color = SDGetColorFromRGBA8(pixel, bitmapInfo, colorSpace);
            } else {
                SD_LOG("Unsupported components: %zu for CGImage: %@", components, imageRef);
                break;
            }
        }
        if (color) {
            [colors addObject:color];
        }
    }
    CFRelease(data);
    CGImageRelease(imageRef);
    
    return [colors copy];
}

#pragma mark - Image Effect

// We use vImage to do box convolve for performance and support for watchOS. However, you can just use `CIFilter.CIGaussianBlur`. For other blur effect, use any filter in `CICategoryBlur`
- (nullable UIImage *)sd_blurredImageWithRadius:(CGFloat)blurRadius {
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    if (!hasBlur) {
        return self;
    }
    
    CGFloat scale = self.scale;
    CGFloat inputRadius = blurRadius * scale;
#if SD_UIKIT || SD_MAC
    if (self.CIImage) {
        CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [filter setValue:self.CIImage forKey:kCIInputImageKey];
        [filter setValue:@(inputRadius) forKey:kCIInputRadiusKey];
        CIImage *ciImage = filter.outputImage;
        ciImage = [ciImage imageByCroppingToRect:CGRectMake(0, 0, self.size.width, self.size.height)];
#if SD_UIKIT
        UIImage *image = [UIImage imageWithCIImage:ciImage scale:self.scale orientation:self.imageOrientation];
#else
        UIImage *image = [[UIImage alloc] initWithCIImage:ciImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
        return image;
    }
#endif
    
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    vImage_Buffer effect = {}, scratch = {};
    vImage_Buffer *input = NULL, *output = NULL;
    
    vImage_CGImageFormat format = {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host, //requests a BGRA buffer.
        .version = 0,
        .decode = NULL,
        .renderingIntent = CGImageGetRenderingIntent(imageRef)
    };
    
    vImage_Error err;
    err = vImageBuffer_InitWithCGImage(&effect, &format, NULL, imageRef, kvImageNoFlags); // vImage will convert to format we requests, no need `vImageConvert`
    if (err != kvImageNoError) {
        SD_LOG("UIImage+Transform error: vImageBuffer_InitWithCGImage returned error code %zi for inputImage: %@", err, self);
        return nil;
    }
    err = vImageBuffer_Init(&scratch, effect.height, effect.width, format.bitsPerPixel, kvImageNoFlags);
    if (err != kvImageNoError) {
        SD_LOG("UIImage+Transform error: vImageBuffer_Init returned error code %zi for inputImage: %@", err, self);
        return nil;
    }
    
    input = &effect;
    output = &scratch;
    
    // See: https://developer.apple.com/library/archive/samplecode/UIImageEffects/Introduction/Intro.html
    if (hasBlur) {
        // A description of how to compute the box kernel width from the Gaussian
        // radius (aka standard deviation) appears in the SVG spec:
        // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
        //
        // For larger values of 's' (s >= 2.0), an approximation can be used: Three
        // successive box-blurs build a piece-wise quadratic convolution kernel, which
        // approximates the Gaussian kernel to within roughly 3%.
        //
        // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
        //
        // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
        //
        if (inputRadius - 2.0 < __FLT_EPSILON__) inputRadius = 2.0;
        uint32_t radius = floor(inputRadius * 3.0 * sqrt(2 * M_PI) / 4 + 0.5);
        radius |= 1; // force radius to be odd so that the three box-blur methodology works.
        NSInteger tempSize = vImageBoxConvolve_ARGB8888(input, output, NULL, 0, 0, radius, radius, NULL, kvImageGetTempBufferSize | kvImageEdgeExtend);
        void *temp = malloc(tempSize);
        vImageBoxConvolve_ARGB8888(input, output, temp, 0, 0, radius, radius, NULL, kvImageEdgeExtend);
        vImageBoxConvolve_ARGB8888(output, input, temp, 0, 0, radius, radius, NULL, kvImageEdgeExtend);
        vImageBoxConvolve_ARGB8888(input, output, temp, 0, 0, radius, radius, NULL, kvImageEdgeExtend);
        free(temp);
        
        vImage_Buffer *tmp = input;
        input = output;
        output = tmp;
    }
    
    CGImageRef effectCGImage = NULL;
    effectCGImage = vImageCreateCGImageFromBuffer(input, &format, NULL, NULL, kvImageNoAllocate, NULL);
    if (effectCGImage == NULL) {
        effectCGImage = vImageCreateCGImageFromBuffer(input, &format, NULL, NULL, kvImageNoFlags, NULL);
        free(input->data);
    }
    free(output->data);
#if SD_UIKIT || SD_WATCH
    UIImage *outputImage = [UIImage imageWithCGImage:effectCGImage scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *outputImage = [[UIImage alloc] initWithCGImage:effectCGImage scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(effectCGImage);
    
    return outputImage;
}

#if SD_UIKIT || SD_MAC
- (nullable UIImage *)sd_filteredImageWithFilter:(nonnull CIFilter *)filter {
    CIImage *inputImage;
    if (self.CIImage) {
        inputImage = self.CIImage;
    } else {
        CGImageRef imageRef = self.CGImage;
        if (!imageRef) {
            return nil;
        }
        inputImage = [CIImage imageWithCGImage:imageRef];
    }
    if (!inputImage) return nil;
    
    CIContext *context = [CIContext context];
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CIImage *outputImage = filter.outputImage;
    if (!outputImage) return nil;
    
    CGImageRef imageRef = [context createCGImage:outputImage fromRect:outputImage.extent];
    if (!imageRef) return nil;
    
#if SD_UIKIT
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:self.scale orientation:kCGImagePropertyOrientationUp];
#endif
    CGImageRelease(imageRef);
    
    return image;
}
#endif

@end
