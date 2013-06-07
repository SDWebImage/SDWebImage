//
//  UIImage+MultiFormat.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import "UIImage+MultiFormat.h"
#import "UIImage+GIF.h"
#import "UIImage+WebP.h"

@implementation UIImage (MultiFormat)

+ (UIImage *)sd_imageWithData:(NSData *)data
{
    UIImage *image;

    if ([data sd_isGIF])
    {
        image = [UIImage sd_animatedGIFWithData:data];
    }
    else
    {
        image = [[UIImage alloc] initWithData:data];
    }

    if (!image) // TODO: detect webp signature
    {
        image = [UIImage sd_imageWithWebPData:data];
    }

    return image;
}

@end
