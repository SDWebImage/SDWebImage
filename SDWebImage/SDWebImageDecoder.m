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
#import <ImageIO/ImageIO.h>

@implementation UIImage (ForceDecode)

+ (UIImage *)decodedImageWithImage:(UIImage *)image {
    if (image.images) {
        // Do not decode animated images
        return image;
    }
    
    // new decompression method
    NSData *data = UIImagePNGRepresentation(image);
    return [self decodedImageWithImage:image data:data];
}

+ (UIImage *)decodedImageWithImage:(UIImage *)image data:(NSData *)data {
    if (image.images) {
        // Do not decode animated images
        return image;
    }
    
    // new decompression method
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, (__bridge CFDictionaryRef)@{(id)kCGImageSourceShouldCacheImmediately: @YES});
    
    UIImage *decompressedImage = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(cgImage);
    CFRelease(source);
    return decompressedImage;
}

@end
