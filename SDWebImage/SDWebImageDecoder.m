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

@implementation UIImage (ForceDecode)

+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    if (image.images) {
        // Do not decode animated images
        return image;
    }

    CGImageRef imageRef = image.CGImage;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
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

    CGContextDrawImage(context, imageRect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);

    CGContextRelease(context);

    UIImage *decompressedImage = [UIImage imageWithCGImage:decompressedImageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(decompressedImageRef);
    return decompressedImage;
}

- (UIImage *)imageWithNoOrientation
{
    CGSize size = self.size; //size after rotation
    CGSize sizeInPixels; //size in pixels after rotation
    CGFloat scale = self.scale;
    sizeInPixels.width = size.width*scale;
    sizeInPixels.height = size.height*scale;
    
    int bytesPerRow	= 4*sizeInPixels.width;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 sizeInPixels.width,
                                                 sizeInPixels.height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGColorSpaceRelease(colorSpace);
    
    UIImageOrientation orientation = self.imageOrientation;
    CGImageRef imageRef = self.CGImage;
    CGSize originalSize = {CGImageGetWidth(imageRef),CGImageGetHeight(imageRef)};//size in pixels before rotation
    
    // rotate
    switch (orientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            CGContextRotateCTM(context, M_PI/2);
            CGContextTranslateCTM(context, 0, -originalSize.height);
            break;
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextRotateCTM(context, -M_PI/2);
            CGContextTranslateCTM(context, -originalSize.width, 0);
            break;
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            CGContextRotateCTM(context, M_PI);
            CGContextTranslateCTM(context, -originalSize.width, -originalSize.height);
            break;
        default:
            break;
    }
    
    // flip
    if(orientation==UIImageOrientationLeftMirrored ||
       orientation==UIImageOrientationRightMirrored ||
       orientation==UIImageOrientationUpMirrored ||
       orientation==UIImageOrientationDownMirrored)
        CGContextConcatCTM(context, CGAffineTransformMake(-1, 0, 0, 1, originalSize.width, 0));
    
    CGContextDrawImage(context, CGRectMake(0, 0, originalSize.width, originalSize.height), imageRef);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *img = [[UIImage alloc] initWithCGImage:imgRef scale:scale orientation:0];
    CGImageRelease(imgRef);
    
    return img;
}

@end
