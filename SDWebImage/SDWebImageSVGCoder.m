//
//  SDWebImageSVGCoder.m
//  SDWebImage
//
//  Created by Noah on 2018/10/26.
//

#ifdef SD_SVG

#import "SDWebImageSVGCoder.h"
#if __has_include(<SVGKit/SVGKit.h>)
#import <SVGKit/SVGKit.h>
#else
#import "SVGKit.h"
#endif

@implementation SDWebImageSVGCoder

+ (instancetype)sharedCoder {
    static SDWebImageSVGCoder *coder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        coder = [[SDWebImageSVGCoder alloc] init];
    });
    return coder;
}

#pragma mark - Decode
- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return ([NSData sd_imageFormatForImageData:data] == SDImageFormatSVG);
}

- (nullable UIImage *)decodedImageWithData:(nullable NSData *)data {
    SVGKImage *image = [[SVGKImage alloc] initWithData:data];
    if (image.hasSize) {
        return image.UIImage;
    }
    return nil;
}

- (nullable UIImage *)decompressedImageWithImage:(nullable UIImage *)image data:(NSData *__autoreleasing  _Nullable * _Nonnull)data options:(nullable NSDictionary<NSString *,NSObject *> *)optionsDict {
    // SVG do not decompress
    return image;
}

#pragma mark - Encode
- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return NO;
}

- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image format:(SDImageFormat)format {
    return nil;
}

@end

#endif
