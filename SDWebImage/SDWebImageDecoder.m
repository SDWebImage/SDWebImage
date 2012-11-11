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
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(image.CGImage);
    BOOL imageHasAlphaInfo = (alphaInfo != kCGImageAlphaNone &&
                              alphaInfo != kCGImageAlphaNoneSkipFirst &&
                              alphaInfo != kCGImageAlphaNoneSkipLast);

    UIGraphicsBeginImageContextWithOptions(image.size, !imageHasAlphaInfo, 0);
    CGRect rect = (CGRect){.origin = CGPointZero, .size = image.size};
    [image drawInRect:rect];
    UIImage *decompressedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return decompressedImage;
}

@end
