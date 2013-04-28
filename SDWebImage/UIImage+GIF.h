//
//  UIImage+GIF.h
//  LBGIFImage
//
//  Created by Laurin Brandner on 06.01.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSData+GIF.h"
#import <UIKit/UIKit.h>

@interface UIImage (GIF)

+ (UIImage *)animatedGIFNamed:(NSString *)name;
+ (UIImage *)animatedGIFWithData:(NSData *)data;

- (UIImage *)animatedImageByScalingAndCroppingToSize:(CGSize)size;

@end
