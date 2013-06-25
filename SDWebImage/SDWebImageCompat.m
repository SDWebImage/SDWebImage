//
//  SDWebImageCompat.c
//  SDWebImage
//
//  Created by Anton Katekov on 24.06.13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//
#import "SDWebImageCompat.h"
#import <UIKit/UIKit.h>

UIImage *SDScaledImageForPath(NSString *path, NSObject *imageOrData)
{
    if (!imageOrData)
    {
        return nil;
    }
    
    UIImage *image = nil;
    if ([imageOrData isKindOfClass:[NSData class]])
    {
        image = [[UIImage alloc] initWithData:(NSData *)imageOrData];
    }
    else if ([imageOrData isKindOfClass:[UIImage class]])
    {
        image = SDWIReturnRetained((UIImage *)imageOrData);
    }
    else
    {
        return nil;
    }
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        CGFloat scale = 1.0;
        if (path.length >= 8)
        {
            // Search @2x. at the end of the string, before a 3 to 4 extension length (only if key len is 8 or more @2x. + 4 len ext)
            NSRange range = [path rangeOfString:@"@2x." options:0 range:NSMakeRange(path.length - 8, 5)];
            if (range.location != NSNotFound)
            {
                scale = 2.0;
            }
        }
        
        UIImage *scaledImage = [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:UIImageOrientationUp];
        SDWISafeRelease(image)
        image = scaledImage;
    }
    
    return SDWIReturnAutoreleased(image);
}
