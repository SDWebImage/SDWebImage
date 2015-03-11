//
//  UIImage+ADColorImage.h
//  ADColorImage
//
//  Created by Alessandro dos santos pinto on 3/10/15.
//  Copyright (c) 2015 Alessandro dos santos pinto. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ADColorImage)


// Changes the color of a pre defined UIImage
- (UIImage *) imageTinted:(UIColor *)color;

@end
