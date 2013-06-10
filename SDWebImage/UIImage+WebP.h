//
//  UIImage+WebP.h
//  SDWebImage
//
//  Created by Olivier Poitrey on 07/06/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#ifdef SD_WEBP
#import <UIKit/UIKit.h>

@interface UIImage (WebP)

+ (UIImage *)sd_imageWithWebPData:(NSData *)data;

@end
#endif
