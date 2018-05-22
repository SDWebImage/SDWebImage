/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import "UIImage+WebP.h"
#import "SDImageWebPCoder.h"

@implementation UIImage (WebP)

+ (nullable UIImage *)sd_imageWithWebPData:(nullable NSData *)data {
    return [self sd_imageWithWebPData:data firstFrameOnly:NO];
}

+ (nullable UIImage *)sd_imageWithWebPData:(nullable NSData *)data firstFrameOnly:(BOOL)firstFrameOnly {
    if (!data) {
        return nil;
    }
    SDImageCoderOptions *options = @{SDImageCoderDecodeFirstFrameOnly : @(firstFrameOnly)};
    return [[SDImageWebPCoder sharedCoder] decodedImageWithData:data options:options];
}

@end

#endif
