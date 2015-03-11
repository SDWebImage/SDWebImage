//
//  UIImage+ADColorImage.m
//  ADColorImage
//
//  Created by Alessandro dos santos pinto on 3/10/15.
//  Copyright (c) 2015 Alessandro dos santos pinto. All rights reserved.
//

#import "UIImage+ADColorImage.h"

BOOL graphicsBeginImageContext(CGSize size, BOOL opaque, float scale)
{
    BOOL result = YES;
    
    if (size.width == 0.0f || size.height == 0.0f)
    {
        [NSException raise:@"Warning" format:@"Invalid format : The view's width and height can't be zero."];
        result = NO;
    }
    else
    {
        // Available for iOS 4 or later.
        UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    }
    
    return result;
}

@implementation UIImage (ADColorImage)

- (UIImage *) imageTinted:(UIColor *)color
{
    UIImage *image = nil;
    CGSize size = self.size;
    CGContextRef context = NULL;
    CGRect area = CGRectMake(0, 0, size.width, size.height);
    float scale = self.scale;
    
    // Starting image context and checks its creation.
    if (graphicsBeginImageContext(size, NO, scale))
    {
        // Redrawing the image in the context.
        [self drawInRect:area];
        
        // Setting the blend mode.
        context = UIGraphicsGetCurrentContext();
        CGContextSetBlendMode(context, kCGBlendModeSourceIn);
        
        // Fills the image with the tint color.
        CGContextSetFillColorWithColor(context, [color CGColor]);
        CGContextFillRect(context, area);
        
        // Gets the final image.
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

@end
