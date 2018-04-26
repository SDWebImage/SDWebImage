/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Laurin Brandner
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+GIF.h"
#import "SDImageGIFCoder.h"

@implementation UIImage (GIF)

+ (nullable UIImage *)sd_animatedGIFWithData:(nullable NSData *)data {
    return [self sd_animatedGIFWithData:data firstFrameOnly:NO];
}

+ (nullable UIImage *)sd_animatedGIFWithData:(nullable NSData *)data firstFrameOnly:(BOOL)firstFrameOnly {
    if (!data) {
        return nil;
    }
    SDImageCoderOptions *options = @{SDImageCoderDecodeFirstFrameOnly : @(firstFrameOnly)};
    return [[SDImageGIFCoder sharedCoder] decodedImageWithData:data options:options];
}

@end
