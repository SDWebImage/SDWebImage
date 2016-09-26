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
    // while downloading huge amount of images
    // autorelease the bitmap context
    // and all vars to help system to free memory
    // when there are memory warning.
    // on iOS7, do not forget to call
    // [[SDImageCache sharedImageCache] clearMemory];
    
    if (image == nil) { // Prevent "CGBitmapContextCreateImage: invalid context 0x0" error
        return nil;
    }
    
    @autoreleasepool{
        // do not decode animated images
        if (image.images != nil) {
            return image;
        }
        
        CGImageRef imageRef = image.CGImage;
        
        CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
        BOOL anyAlpha = (alpha == kCGImageAlphaFirst ||
                         alpha == kCGImageAlphaLast ||
                         alpha == kCGImageAlphaPremultipliedFirst ||
                         alpha == kCGImageAlphaPremultipliedLast);
        if (anyAlpha) {
            return image;
        }
        
        // current
        CGColorSpaceModel imageColorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(imageRef));
        CGColorSpaceRef colorspaceRef = CGImageGetColorSpace(imageRef);
        
        BOOL unsupportedColorSpace = (imageColorSpaceModel == kCGColorSpaceModelUnknown ||
                                      imageColorSpaceModel == kCGColorSpaceModelMonochrome ||
                                      imageColorSpaceModel == kCGColorSpaceModelCMYK ||
                                      imageColorSpaceModel == kCGColorSpaceModelIndexed);
        if (unsupportedColorSpace) {
            colorspaceRef = CGColorSpaceCreateDeviceRGB();
        }
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;


        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     bitsPerComponent,
                                                     bytesPerRow,
                                                     colorspaceRef,
                                                     kCGBitmapByteOrderDefault|kCGImageAlphaNoneSkipLast);
        
        // Draw the image into the context and retrieve the new bitmap image without alpha
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithoutAlpha = [UIImage imageWithCGImage:imageRefWithoutAlpha
                                                         scale:image.scale
                                                   orientation:image.imageOrientation];
        
        if (unsupportedColorSpace) {
            CGColorSpaceRelease(colorspaceRef);
        }
        
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        
        return imageWithoutAlpha;
    }
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
