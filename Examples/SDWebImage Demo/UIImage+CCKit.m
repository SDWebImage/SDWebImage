//
//  UIImage+CCKit.m
//  performance
//
//  Created by KudoCC on 16/5/9.
//  Copyright © 2016年 KudoCC. All rights reserved.
//

#import "UIImage+CCKit.h"
#import "UIView+CCKit.h"

@implementation UIImage (CCKit)

- (UIImage *)cc_imageWithSize:(CGSize)size cornerRadius:(CGFloat)radius {
    return [self cc_imageWithSize:size cornerRadius:radius contentMode:UIViewContentModeScaleToFill];
}

- (UIImage *)cc_imageWithSize:(CGSize)size cornerRadius:(CGFloat)radius contentMode:(UIViewContentMode)contentMode {
    return [self cc_imageWithSize:size cornerRadius:radius borderWidth:0 borderColor:nil contentMode:contentMode];
}

- (UIImage *)cc_imageWithSize:(CGSize)size cornerRadius:(CGFloat)radius borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor contentMode:(UIViewContentMode)contentMode {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // add clip area
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.0, 0.0, size.width, size.height) cornerRadius:radius];
    [path addClip];
    
    // draw image
    CGRect frame = [UIView cc_frameOfContentWithContentSize:self.size containerSize:size contentMode:contentMode];
    [self drawInRect:frame];
    
    // draw border
    if (borderWidth > 0 && borderColor) {
        path.lineWidth = borderWidth*2;
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        [path stroke];
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end