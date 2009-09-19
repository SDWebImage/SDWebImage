//
//  DMImageCache.m
//  Dailymotion
//
//  Created by Olivier Poitrey on 19/09/09.
//  Copyright 2009 Dailymotion. All rights reserved.
//

#import "DMImageCache.h"
#import <CommonCrypto/CommonDigest.h>

static NSInteger kMaxCacheAge = 60*60*24*7; // 1 week

static DMImageCache *instance;

@implementation DMImageCache

#pragma mark NSObject

- (id)init
{
    if (self = [super init])
    {
        cache = [[NSMutableDictionary alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification  
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willTerminate)
                                                     name:UIApplicationWillTerminateNotification  
                                                   object:nil];
        
        // Init the cache
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        diskCachePath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"ImageCache"] retain];
        		
        if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath attributes:nil];
        }
    }

    return self;
}

- (void)dealloc
{
    [cache release];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification  
                                                  object:nil];  

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillTerminateNotification  
                                                  object:nil];  
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning:(void *)object
{
    [self clearMemory];
}

- (void)willTerminate
{
    [self cleanDisk];
}

#pragma mark ImageCache (private)

- (NSString *)cachePathForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];

    return [diskCachePath stringByAppendingPathComponent:filename];
}

#pragma mark ImageCache

+ (DMImageCache *)sharedImageCache
{
    if (instance == nil)
    {
        instance = [[DMImageCache alloc] init];
    }

    return instance;
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key
{
    [self storeImage:image forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    if (image == nil)
    {
        return;
    }

    [cache setObject:image forKey:key];

    if (toDisk)
    {
        [[NSFileManager defaultManager] createFileAtPath:[self cachePathForKey:key] contents:UIImageJPEGRepresentation(image, 1.0) attributes:nil];
    }
}

- (UIImage *)imageFromKey:(NSString *)key
{
    return [self imageFromKey:key fromDisk:YES];
}

- (UIImage *)imageFromKey:(NSString *)key fromDisk:(BOOL)fromDisk
{
    UIImage *image = [cache objectForKey:key];

    if (!image && fromDisk)
    {
        image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfFile:[self cachePathForKey:key]]];
        if (image != nil)
        {
            [cache setObject:image forKey:key];
            [image release];
        }
    }

    return image;
}

- (void)removeImageForKey:(NSString *)key
{
    [cache removeObjectForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
}

- (void)clearMemory
{
    [cache removeAllObjects];
}

- (void)clearDisk
{
    [[NSFileManager defaultManager] removeItemAtPath:diskCachePath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath attributes:nil];    
}

- (void)cleanDisk
{
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-kMaxCacheAge];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[[attrs fileModificationDate] laterDate:expirationDate] isEqualToDate:expirationDate])
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

@end
