/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+Transform.h"
#import "NSImage+Additions.h"
#import <Accelerate/Accelerate.h>
#if SD_UIKIT || SD_MAC
#import <CoreImage/CoreImage.h>
#endif

#ifndef SD_SWAP // swap two value
#define SD_SWAP(_a_, _b_)  do { __typeof__(_a_) _tmp_ = (_a_); (_a_) = (_b_); (_b_) = _tmp_; } while (0)
#endif

#if SD_MAC
static CGContextRef SDCGContextCreateARGBBitmapContext(CGSize size, BOOL opaque, CGFloat scale) {
    size_t width = ceil(size.width * scale);
    size_t height = ceil(size.height * scale);
    if (width < 1 || height < 1) return NULL;
    
    //pre-multiplied ARGB, 8-bits per component
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGImageAlphaInfo alphaInfo = (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, space, kCGBitmapByteOrderDefault | alphaInfo);
    CGColorSpaceRelease(space);
    return context;
}
#endif

static void SDGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale) {
#if SD_UIKIT || SD_WATCH
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
#else
    CGContextRef context = SDCGContextCreateARGBBitmapContext(size, opaque, scale);
    if (!context) {
        return;
    }
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
    CGContextRelease(context);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = graphicsContext;
#endif
}

static CGContextRef SDGraphicsGetCurrentContext(void) {
#if SD_UIKIT || SD_WATCH
    return UIGraphicsGetCurrentContext();
#else
    return NSGraphicsContext.currentContext.CGContext;
#endif
}

static void SDGraphicsEndImageContext(void) {
#if SD_UIKIT || SD_WATCH
    UIGraphicsEndImageContext();
#else
    [NSGraphicsContext restoreGraphicsState];
#endif
}

static UIImage * SDGraphicsGetImageFromCurrentImageContext(void) {
#if SD_UIKIT || SD_WATCH
    return UIGraphicsGetImageFromCurrentImageContext();
#else
    CGContextRef context = SDGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    if (!imageRef) {
        return nil;
    }
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
    CGImageRelease(imageRef);
    return image;
#endif
}

static CGRect SDCGRectFitWithScaleMode(CGRect rect, CGSize size, SDImageScaleMode scaleMode) {
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

@implementation UIColor (Additions)

- (NSString *)sd_hexString {
    CGFloat red, green, blue, alpha;
#if SD_UIKIT
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        [self getWhite:&red alpha:&alpha];
        green = red;
        blue = red;
    }
#else
    @try {
        [self getRed:&red green:&green blue:&blue alpha:&alpha];
    }
    @catch (NSException *exception) {
        [self getWhite:&red alpha:&alpha];
        green = red;
        blue = red;
    }
#endif
    
    red = roundf(red * 255.f);
    green = roundf(green * 255.f);
    blue = roundf(blue * 255.f);
    alpha = roundf(alpha * 255.f);
    
    uint hex = ((uint)alpha << 24) | ((uint)red << 16) | ((uint)green << 8) | ((uint)blue);
    
    return [NSString stringWithFormat:@"0x%08x", hex];
}

@end

#if SD_MAC

@implementation NSBezierPath (Additions)

+ (instancetype)sd_bezierPathWithRoundedRect:(NSRect)rect byRoundingCorners:(SDRectCorner)corners cornerRadius:(CGFloat)cornerRadius {
    NSBezierPath *path = [NSBezierPath bezierPath];
    
    CGFloat maxCorner = MIN(NSWidth(rect), NSHeight(rect)) / 2;
    
    CGFloat topLeftRadius = MIN(maxCorner, (corners & SDRectCornerTopLeft) ? cornerRadius : 0);
    CGFloat topRightRadius = MIN(maxCorner, (corners & SDRectCornerTopRight) ? cornerRadius : 0);
    CGFloat bottomLeftRadius = MIN(maxCorner, (corners & SDRectCornerBottomLeft) ? cornerRadius : 0);
    CGFloat bottomRightRadius = MIN(maxCorner, (corners & SDRectCornerBottomRight) ? cornerRadius : 0);
    
    NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
    NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
    NSPoint bottomLeft = NSMakePoint(NSMinX(rect), NSMinY(rect));
    NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
    
    [path moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
    [path appendBezierPathWithArcFromPoint:topLeft toPoint:bottomLeft radius:topLeftRadius];
    [path appendBezierPathWithArcFromPoint:bottomLeft toPoint:bottomRight radius:bottomLeftRadius];
    [path appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight radius:bottomRightRadius];
    [path appendBezierPathWithArcFromPoint:topRight toPoint:topLeft radius:topRightRadius];
    [path closePath];
    
    return path;
}

@end

#endif

@implementation UIImage (Transform)

- (void)sd_drawInRect:(CGRect)rect withScaleMode:(SDImageScaleMode)scaleMode clipsToBounds:(BOOL)clips {
    CGRect drawRect = SDCGRectFitWithScaleMode(rect, self.size, scaleMode);
    if (drawRect.size.width == 0 || drawRect.size.height == 0) return;
    if (clips) {
        CGContextRef context = SDGraphicsGetCurrentContext();
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

- (UIImage *)sd_resizedImageWithSize:(CGSize)size scaleMode:(SDImageScaleMode)scaleMode {
    if (size.width <= 0 || size.height <= 0) return nil;
    SDGraphicsBeginImageContextWithOptions(size, NO, self.scale);
    [self sd_drawInRect:CGRectMake(0, 0, size.width, size.height) withScaleMode:scaleMode clipsToBounds:NO];
    UIImage *image = SDGraphicsGetImageFromCurrentImageContext();
    SDGraphicsEndImageContext();
    return image;
}

- (UIImage *)sd_croppedImageWithRect:(CGRect)rect {
    if (!self.CGImage) return nil;
    rect.origin.x *= self.scale;
    rect.origin.y *= self.scale;
    rect.size.width *= self.scale;
    rect.size.height *= self.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, rect);
    if (!imageRef) {
        return nil;
    }
#if SD_UIKIT || SD_WATCH
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:self.scale];
#endif
    CGImageRelease(imageRef);
    return image;
}

- (UIImage *)sd_roundedCornerImageWithRadius:(CGFloat)cornerRadius corners:(SDRectCorner)corners borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor {
    if (!self.CGImage) return nil;
    SDGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    CGContextRef context = SDGraphicsGetCurrentContext();
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
        CGContextDrawImage(context, rect, self.CGImage);
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
    
    UIImage *image = SDGraphicsGetImageFromCurrentImageContext();
    SDGraphicsEndImageContext();
    return image;
}

- (UIImage *)sd_rotatedImageWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize {
    if (!self.CGImage) return nil;
    size_t width = (size_t)CGImageGetWidth(self.CGImage);
    size_t height = (size_t)CGImageGetHeight(self.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height),
                                                fitSize ? CGAffineTransformMakeRotation(angle) : CGAffineTransformIdentity);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, angle);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), self.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
#if SD_UIKIT || SD_WATCH
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:self.scale];
#endif
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

- (UIImage *)sd_flippedImageWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical {
    if (!self.CGImage) return nil;
    size_t width = (size_t)CGImageGetWidth(self.CGImage);
    size_t height = (size_t)CGImageGetHeight(self.CGImage);
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), self.CGImage);
    UInt8 *data = (UInt8 *)CGBitmapContextGetData(context);
    if (!data) {
        CGContextRelease(context);
        return nil;
    }
    vImage_Buffer src = { data, height, width, bytesPerRow };
    vImage_Buffer dest = { data, height, width, bytesPerRow };
    if (vertical) {
        vImageVerticalReflect_ARGB8888(&src, &dest, kvImageBackgroundColorFill);
    }
    if (horizontal) {
        vImageHorizontalReflect_ARGB8888(&src, &dest, kvImageBackgroundColorFill);
    }
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
#if SD_UIKIT || SD_WATCH
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:self.scale];
#endif
    CGImageRelease(imgRef);
    return img;
}

#pragma mark - Image Blending

- (UIImage *)sd_tintedImageWithColor:(UIColor *)tintColor {
    if (!self.CGImage) return nil;
    if (!tintColor.CGColor) return nil;
    
    BOOL hasTint = CGColorGetAlpha(tintColor.CGColor) > __FLT_EPSILON__;
    if (!hasTint) {
#if SD_UIKIT || SD_WATCH
        return [UIImage imageWithCGImage:self.CGImage scale:self.scale orientation:self.imageOrientation];
#else
        return [[UIImage alloc] initWithCGImage:self.CGImage scale:self.scale];
#endif
    }
    
    CGSize size = self.size;
    CGRect rect = { CGPointZero, size };
    CGFloat scale = self.scale;
    
    // blend mode, see https://en.wikipedia.org/wiki/Alpha_compositing
    CGBlendMode blendMode = kCGBlendModeSourceAtop;
    
    SDGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef context = SDGraphicsGetCurrentContext();
    CGContextDrawImage(context, rect, self.CGImage);
    CGContextSetBlendMode(context, blendMode);
    CGContextSetFillColorWithColor(context, tintColor.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = SDGraphicsGetImageFromCurrentImageContext();
    SDGraphicsEndImageContext();
    
    return image;
}

- (UIColor *)sd_colorAtPoint:(CGPoint)point {
    if (!self) {
        return nil;
    }
    CGImageRef imageRef = self.CGImage;
    if (!imageRef) {
        return nil;
    }
    
    // Check point
    CGFloat width = CGImageGetWidth(imageRef);
    CGFloat height = CGImageGetHeight(imageRef);
    if (point.x < 0 || point.y < 0 || point.x > width || point.y > height) {
        return nil;
    }
    
    // Get pixels
    CGDataProviderRef provider = CGImageGetDataProvider(imageRef);
    if (!provider) {
        return nil;
    }
    CFDataRef data = CGDataProviderCopyData(provider);
    if (!data) {
        return nil;
    }
    
    // Get pixel at point
    size_t bytesPerRow = CGImageGetBytesPerRow(imageRef); // Actually should be ARGB8888, equal to width * 4(alpha) or 3(non-alpha)
    size_t components = CGImageGetBitsPerPixel(imageRef) / CGImageGetBitsPerComponent(imageRef);
    
    CFRange range = CFRangeMake(bytesPerRow * point.y + components * point.x, 4);
    if (CFDataGetLength(data) < range.location + range.length) {
        return nil;
    }
    UInt8 pixel[4] = {0};
    CFDataGetBytes(data, range, pixel);
    
    // Convert to color
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(imageRef);
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGFloat r = 0, g = 0, b = 0, a = 0;
    
    BOOL byteOrderNormal = NO;
    switch (bitmapInfo & kCGBitmapByteOrderMask) {
        case kCGBitmapByteOrderDefault: {
            byteOrderNormal = YES;
        } break;
        case kCGBitmapByteOrder32Little: {
        } break;
        case kCGBitmapByteOrder32Big: {
            byteOrderNormal = YES;
        } break;
        default: break;
    }
    switch (alphaInfo) {
        case kCGImageAlphaPremultipliedFirst:
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
        case kCGImageAlphaPremultipliedLast:
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
        case kCGImageAlphaOnly:
        default:
            break;
    }
    
    return [UIColor colorWithRed:r green:g blue:b alpha:a];
}

#pragma mark - Image Effect

// We use vImage to do box convolve for performance. However, you can just use `CIFilter.CIBoxBlur`. For other blur effect, use any filter in `CICategoryBlur`
- (UIImage *)sd_blurredImageWithRadius:(CGFloat)blurRadius {
    if (self.size.width < 1 || self.size.height < 1) {
        return nil;
    }
    if (!self.CGImage) {
        return nil;
    }
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    if (!hasBlur) {
        return self;
    }
    
    CGFloat scale = self.scale;
    CGImageRef imageRef = self.CGImage;
    
    vImage_Buffer effect = {}, scratch = {};
    vImage_Buffer *input = NULL, *output = NULL;
    
    vImage_CGImageFormat format = {
        .bitsPerComponent = 8,
        .bitsPerPixel = 32,
        .colorSpace = NULL,
        .bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little, //requests a BGRA buffer.
        .version = 0,
        .decode = NULL,
        .renderingIntent = kCGRenderingIntentDefault
    };
    
    vImage_Error err;
    err = vImageBuffer_InitWithCGImage(&effect, &format, NULL, imageRef, kvImagePrintDiagnosticsToConsole);
    if (err != kvImageNoError) {
        NSLog(@"UIImage+Transform error: vImageBuffer_InitWithCGImage returned error code %zi for inputImage: %@", err, self);
        return nil;
    }
    err = vImageBuffer_Init(&scratch, effect.height, effect.width, format.bitsPerPixel, kvImageNoFlags);
    if (err != kvImageNoError) {
        NSLog(@"UIImage+Transform error: vImageBuffer_Init returned error code %zi for inputImage: %@", err, self);
        return nil;
    }
    
    input = &effect;
    output = &scratch;
    
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
        CGFloat inputRadius = blurRadius * scale;
        if (inputRadius - 2.0 < __FLT_EPSILON__) inputRadius = 2.0;
        uint32_t radius = floor((inputRadius * 3.0 * sqrt(2 * M_PI) / 4 + 0.5) / 2);
        radius |= 1; // force radius to be odd so that the three box-blur methodology works.
        int iterations;
        if (blurRadius * scale < 0.5) iterations = 1;
        else if (blurRadius * scale < 1.5) iterations = 2;
        else iterations = 3;
        NSInteger tempSize = vImageBoxConvolve_ARGB8888(input, output, NULL, 0, 0, radius, radius, NULL, kvImageGetTempBufferSize | kvImageEdgeExtend);
        void *temp = malloc(tempSize);
        for (int i = 0; i < iterations; i++) {
            vImageBoxConvolve_ARGB8888(input, output, temp, 0, 0, radius, radius, NULL, kvImageEdgeExtend);
            SD_SWAP(input, output);
        }
        free(temp);
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
    UIImage *outputImage = [[UIImage alloc] initWithCGImage:effectCGImage scale:self.scale];
#endif
    CGImageRelease(effectCGImage);
    
    return outputImage;
}

#if SD_UIKIT || SD_MAC
- (UIImage *)sd_filteredImageWithFilter:(CIFilter *)filter {
    if (!self.CGImage) return nil;
    
    CIContext *context = [CIContext context];
    CIImage *inputImage = [CIImage imageWithCGImage:self.CGImage];
    if (!inputImage) return nil;
    
    [filter setValue:inputImage forKey:kCIInputImageKey];
    CIImage *outputImage = filter.outputImage;
    if (!outputImage) return nil;
    
    CGImageRef imageRef = [context createCGImage:outputImage fromRect:outputImage.extent];
    if (!imageRef) return nil;
    
#if SD_UIKIT
    UIImage *image = [UIImage imageWithCGImage:imageRef scale:self.scale orientation:self.imageOrientation];
#else
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef scale:self.scale];
#endif
    CGImageRelease(imageRef);
    
    return image;
}
#endif

@end
