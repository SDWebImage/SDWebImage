/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import "UIImage+WebP.h"
#import "SDWebImageWebPCoder.h"
#import "UIImage+MultiFormat.h"

@implementation UIImage (WebP)

- (NSInteger)sd_webpLoopCount {
    return self.sd_imageLoopCount;
}

+ (nullable UIImage *)sd_imageWithWebPData:(nullable NSData *)data {
    if (!data) {
        return nil;
    }
    return [[SDWebImageWebPCoder sharedCoder] decodedImageWithData:data];
}

@end

#endif
