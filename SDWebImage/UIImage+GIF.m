//
//  UIImage+GIF.m
//  LBGIFImage
//
//  Created by Laurin Brandner on 06.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIImage+GIF.h"
#import <ImageIO/ImageIO.h>
#import "objc/runtime.h"

@implementation UIImage (GIF)

+ (UIImage *)sd_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);

    size_t count = CGImageSourceGetCount(source);

    UIImage *staticImage;

    if (count <= 1) {
        staticImage = [[UIImage alloc] initWithData:data];
    } else {
        // we will only retrieve the 1st frame. the full GIF support is available via the FLAnimatedImageView category.
        // this here is only code to allow drawing animated images as static ones
        CGImageRef CGImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        UIImage *frameImage = [UIImage imageWithCGImage:CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        staticImage = [UIImage animatedImageWithImages:@[frameImage] duration:0.0f];
        CGImageRelease(CGImage);
    }

    CFRelease(source);

    return staticImage;
}

- (BOOL)isGIF {
    return (self.images != nil);
}

@end
