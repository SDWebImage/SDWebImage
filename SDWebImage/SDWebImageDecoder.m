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

+ (UIImage *)decodedImageWithImage:(UIImage *)image
{	
    CGImageRef imageRef = image.CGImage;

    CGRect rectToDraw = CGRectMake(0, 0, 1, 1);

    CGColorSpaceRef colorSpace = CGImageGetColorSpace(imageRef);
    CGContextRef context = CGBitmapContextCreate(NULL, rectToDraw.size.width, rectToDraw.size.height, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpace, CGImageGetBitmapInfo(imageRef));

    // If failed, return undecompressed image
    if (!context) return image;

    UIGraphicsPushContext(context);
    {
        // This causes the UIImage object to be decoded, but the context is the smallest possible
        // So it doesn't duplicate the image in memory. From here on, the image is cached in the internal UIImage cache.
        [image drawInRect:rectToDraw];
    }
    UIGraphicsPopContext();
	
    CGContextRelease(context);

    return image;
}

@end
