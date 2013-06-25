//
//  SDWebImageManagerCacheDelegate.h
//  SDWebImage
//
//  Created by Anton Katekov on 24.06.13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SDWebImageManagerCacheDelegate <NSObject>

- (NSString*)checksumForUrl:(NSString*)url;
- (void)setChecksum:(NSString*)checksum forUrl:(NSString*)url;
- (void)removeChecksumForUrl:(NSString*)url;
- (BOOL)shouldTrackUpdationForUrl:(NSString*)url;

@end
