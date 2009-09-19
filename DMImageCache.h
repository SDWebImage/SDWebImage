//
//  DMImageCache.h
//  Dailymotion
//
//  Created by Olivier Poitrey on 19/09/09.
//  Copyright 2009 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DMImageCache : NSObject
{
    NSMutableDictionary *cache;
    NSString *diskCachePath;
}

+ (DMImageCache *)sharedImageCache;
- (void)storeImage:(UIImage *)image forKey:(NSString *)key;
- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk;
- (UIImage *)imageFromKey:(NSString *)key;
- (UIImage *)imageFromKey:(NSString *)key fromDisk:(BOOL)fromDisk;
- (void)removeImageForKey:(NSString *)key;
- (void)clearMemory;
- (void)clearDisk;
- (void)cleanDisk;

@end
