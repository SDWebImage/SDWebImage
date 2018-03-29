/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+ForceDecode.h"
#import "SDWebImageCoderHelper.h"

@implementation UIImage (ForceDecode)

+ (UIImage *)sd_decodedImageWithImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    return [SDWebImageCoderHelper decodedImageWithImage:image];
}

+ (UIImage *)sd_decodedAndScaledDownImageWithImage:(UIImage *)image {
    if (!image) {
        return nil;
    }
    return [SDWebImageCoderHelper decodedAndScaledDownImageWithImage:image limitBytes:0];
}

@end
