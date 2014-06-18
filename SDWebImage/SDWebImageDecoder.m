/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * Created by james <https://github.com/mystcolor> on 9/28/11.
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDecoder.h"

/*
 Size in MB, compatible with all iOS devices.
 */
#define kSDWebImageDecoderMaxImageSizeMB 4.f

#define SDWebImageDecoderMaxTotalPixels(bitsPerComponent) ((kSDWebImageDecoderMaxImageSizeMB*1024.*1024.*8.)/bitsPerComponent)

inline static CGSize SDWebImageDecoderConstrainedSize(UIImage *image) {
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    size_t imageBitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    CGFloat imageTotalPixels = imageSize.width * imageSize.height;
    if (imageTotalPixels < SDWebImageDecoderMaxTotalPixels(imageBitsPerComponent)) {
        return CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
    }
    CGFloat ratio = SDWebImageDecoderMaxTotalPixels(imageBitsPerComponent) / imageTotalPixels;
    CGFloat maxWidth = imageSize.width * ratio;
    CGFloat maxHeight = imageSize.height *ratio;
    return CGSizeMake(floorf(maxWidth), floorf(maxHeight));
}

@implementation UIImage (ForceDecode)

+ (UIImage *)decodedAndScaledDownImageToSize:(CGSize)size withImage:(UIImage *)image {
    if (image.images) {
        // Do not decode animated images
        return image;
    }
    
    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    if ((size.width < imageSize.width) && (size.height < imageSize.height)) {
        imageSize = size;
    }

    CGRect imageRect = (CGRect){.origin = CGPointZero, .size = imageSize};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    int infoMask = (bitmapInfo & kCGBitmapAlphaInfoMask);
    BOOL anyNonAlpha = (infoMask == kCGImageAlphaNone ||
                        infoMask == kCGImageAlphaNoneSkipFirst ||
                        infoMask == kCGImageAlphaNoneSkipLast);
    
    // CGBitmapContextCreate doesn't support kCGImageAlphaNone with RGB.
    // https://developer.apple.com/library/mac/#qa/qa1037/_index.html
    if (infoMask == kCGImageAlphaNone && CGColorSpaceGetNumberOfComponents(colorSpace) > 1) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        
        // Set noneSkipFirst.
        bitmapInfo |= kCGImageAlphaNoneSkipFirst;
    }
    // Some PNGs tell us they have alpha but only 3 components. Odd.
    else if (!anyNonAlpha && CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        // Unset the old alpha info.
        bitmapInfo &= ~kCGBitmapAlphaInfoMask;
        bitmapInfo |= kCGImageAlphaPremultipliedFirst;
    }
    
    // It calculates the bytes-per-row based on the bitsPerComponent and width arguments.
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageSize.width,
                                                 imageSize.height,
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 0,
                                                 colorSpace,
                                                 bitmapInfo);
    CGColorSpaceRelease(colorSpace);
    
    // If failed, return undecompressed image
    if (!context) return image;
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    return [UIImage decodedAndScaledDownImageToSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) withImage:image];
}

+ (UIImage *)decodedAndScaledDownImageWithImage:(UIImage *)image {
    return [UIImage decodedAndScaledDownImageToSize:SDWebImageDecoderConstrainedSize(image) withImage:image];
}

@end
