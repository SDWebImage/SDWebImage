//
//  NSData+WebP.m
//  SDWebImage
//
//  Created by Limboy on 7/3/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import "NSData+WebP.h"

@implementation NSData (WebP)

- (BOOL)sd_isWebP
{
    BOOL isWebP = NO;
    
    uint8_t c;
    [self getBytes:&c length:1];
    
    switch (c)
    {
        case 0x52:  // probably a WebP
            isWebP = YES;
            break;
        default:
            break;
    }
    
    return isWebP;
}


@end
