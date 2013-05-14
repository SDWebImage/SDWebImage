//
//  NSData+GIF.m
//  SDWebImage
//
//  Created by Andy LaVoy on 4/28/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import "NSData+GIF.h"

@implementation NSData (GIF)

- (BOOL)sd_isGIF
{
    BOOL isGIF = NO;
    
    uint8_t c;
    [self getBytes:&c length:1];
    
    switch (c)
    {
        case 0x47:  // probably a GIF
            isGIF = YES;
            break;
        default:
            break;
    }
    
    return isGIF;
}

@end
