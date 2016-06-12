//
//  NSImage+WebCache.h
//  SDWebImage
//
//  Created by Bogdan on 12/06/16.
//  Copyright © 2016 Dailymotion. All rights reserved.
//

#import "SDWebImageCompat.h"

#if SD_MAC

#import <Cocoa/Cocoa.h>

@interface NSImage (WebCache)

- (NSArray<NSImage *> *)images;
- (BOOL)isGIF;

@end

#endif
