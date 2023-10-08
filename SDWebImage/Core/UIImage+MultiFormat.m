/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+MultiFormat.h"
#import "SDImageCodersManager.h"
#import "SDAnimatedImageRep.h"
#import "UIImage+Metadata.h"

@implementation UIImage (MultiFormat)

+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data {
    return [self sd_imageWithData:data scale:1];
}

+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data scale:(CGFloat)scale {
    return [self sd_imageWithData:data scale:scale firstFrameOnly:NO];
}

+ (nullable UIImage *)sd_imageWithData:(nullable NSData *)data scale:(CGFloat)scale firstFrameOnly:(BOOL)firstFrameOnly {
    if (!data) {
        return nil;
    }
    SDImageCoderOptions *options = @{SDImageCoderDecodeScaleFactor : @(MAX(scale, 1)), SDImageCoderDecodeFirstFrameOnly : @(firstFrameOnly)};
    return [[SDImageCodersManager sharedManager] decodedImageWithData:data options:options];
}

- (nullable NSData *)sd_imageData {
#if SD_MAC
    NSRect imageRect = NSMakeRect(0, 0, self.size.width, self.size.height);
    NSImageRep *imageRep = [self bestRepresentationForRect:imageRect context:nil hints:nil];
    // Check weak animated data firstly
    if ([imageRep isKindOfClass:[SDAnimatedImageRep class]]) {
        SDAnimatedImageRep *animatedImageRep = (SDAnimatedImageRep *)imageRep;
        NSData *imageData = [animatedImageRep animatedImageData];
        if (imageData) {
            return imageData;
        }
    }
#endif
    return [self sd_imageDataAsFormat:self.sd_imageFormat];
}

- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat {
    return [self sd_imageDataAsFormat:imageFormat compressionQuality:1];
}

- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat compressionQuality:(double)compressionQuality {
    return [self sd_imageDataAsFormat:imageFormat compressionQuality:compressionQuality firstFrameOnly:NO];
}

- (nullable NSData *)sd_imageDataAsFormat:(SDImageFormat)imageFormat compressionQuality:(double)compressionQuality firstFrameOnly:(BOOL)firstFrameOnly {
    SDImageCoderOptions *options = @{SDImageCoderEncodeCompressionQuality : @(compressionQuality), SDImageCoderEncodeFirstFrameOnly : @(firstFrameOnly)};
    return [[SDImageCodersManager sharedManager] encodedDataWithImage:self format:imageFormat options:options];
}

@end
