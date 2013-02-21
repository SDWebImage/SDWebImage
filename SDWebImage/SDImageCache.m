/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCache.h"
#import "SDWebImageDecoder.h"
#import <CommonCrypto/CommonDigest.h>
#import "SDWebImageDecoder.h"
#import <mach/mach.h>
#import <mach/mach_host.h>

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

@interface SDImageCache ()

@property (strong, nonatomic) NSCache *memCache;
@property (strong, nonatomic) NSString *diskCachePath;
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t ioQueue;

@end


@implementation SDImageCache

+ (SDImageCache *)sharedImageCache
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    return [self initWithNamespace:@"default"];
}

- (id)initWithNamespace:(NSString *)ns
{
    if ((self = [super init]))
    {
        NSString *fullNamespace = [@"com.hackemist.SDWebImageCache." stringByAppendingString:ns];

        // Create IO serial queue
        _ioQueue = dispatch_queue_create("com.hackemist.SDWebImageCache", DISPATCH_QUEUE_SERIAL);

        // Init default values
        _maxCacheAge = kDefaultCacheMaxCacheAge;

        // Init the memory cache
        _memCache = [[NSCache alloc] init];
        _memCache.name = fullNamespace;

        // Init the disk cache
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];

#if TARGET_OS_IPHONE
        // Subscribe to app events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
#endif
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SDDispatchQueueRelease(_ioQueue);
}

#pragma mark SDImageCache (private)

- (NSString *)cachePathForKey:(NSString *)key
{
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];

    return [self.diskCachePath stringByAppendingPathComponent:filename];
}

#pragma mark ImageCache

- (void)storeImage:(UIImage *)image imageData:(NSData *)imageData forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    if (!image || !key)
    {
        return;
    }

    [self.memCache setObject:image forKey:key cost:image.size.height * image.size.width * image.scale];

    if (toDisk)
    {
        dispatch_async(self.ioQueue, ^
        {
            NSData *data = imageData;

            if (!data)
            {
                if (image)
                {
#if TARGET_OS_IPHONE
                    data = UIImageJPEGRepresentation(image, (CGFloat)1.0);
#else
                    data = [NSBitmapImageRep representationOfImageRepsInArray:image.representations usingType: NSJPEGFileType properties:nil];
#endif
                }
            }

            if (data)
            {
                // Can't use defaultManager another thread
                NSFileManager *fileManager = NSFileManager.new;

                if (![fileManager fileExistsAtPath:_diskCachePath])
                {
                    [fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                }

                [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
            }
        });
    }
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key
{
    [self storeImage:image imageData:nil forKey:key toDisk:YES];
}

- (void)storeImage:(UIImage *)image forKey:(NSString *)key toDisk:(BOOL)toDisk
{
    [self storeImage:image imageData:nil forKey:key toDisk:toDisk];
}

- (UIImage *)imageFromMemoryCacheForKey:(NSString *)key
{
    return [self.memCache objectForKey:key];
}

- (UIImage *)imageFromDiskCacheForKey:(NSString *)key
{
    // First check the in-memory cache...
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image)
    {
        return image;
    }
    
    // Second check the disk cache...
    UIImage *diskImage = [UIImage decodedImageWithImage:SDScaledImageForPath(key, [NSData dataWithContentsOfFile:[self cachePathForKey:key]])];
    
    if (diskImage)
    {
        CGFloat cost = diskImage.size.height * diskImage.size.width * diskImage.scale;
        [self.memCache setObject:diskImage forKey:key cost:cost];
    }
    
    return diskImage;
}

- (void)queryDiskCacheForKey:(NSString *)key done:(void (^)(UIImage *image, SDImageCacheType cacheType))doneBlock
{
    if (!doneBlock) return;

    if (!key)
    {
        doneBlock(nil, SDImageCacheTypeNone);
        return;
    }

    // First check the in-memory cache...
    UIImage *image = [self imageFromMemoryCacheForKey:key];
    if (image)
    {
        doneBlock(image, SDImageCacheTypeMemory);
        return;
    }

    dispatch_async(self.ioQueue, ^
    {
        UIImage *diskImage = [UIImage decodedImageWithImage:SDScaledImageForPath(key, [NSData dataWithContentsOfFile:[self cachePathForKey:key]])];

        if (diskImage)
        {
            CGFloat cost = diskImage.size.height * diskImage.size.width * diskImage.scale;
            [self.memCache setObject:diskImage forKey:key cost:cost];
        }

        dispatch_async(dispatch_get_main_queue(), ^
        {
            doneBlock(diskImage, SDImageCacheTypeDisk);
        });
    });
}

- (void)removeImageForKey:(NSString *)key
{
    [self removeImageForKey:key fromDisk:YES];
}

- (void)removeImageForKey:(NSString *)key fromDisk:(BOOL)fromDisk
{
    if (key == nil)
    {
        return;
    }

    [self.memCache removeObjectForKey:key];

    if (fromDisk)
    {
        dispatch_async(self.ioQueue, ^
        {
            [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
        });
    }
}

- (void)clearMemory
{
    [self.memCache removeAllObjects];
}

- (void)clearDisk
{
    dispatch_async(self.ioQueue, ^
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.diskCachePath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    });
}

- (void)cleanDisk
{
    dispatch_async(self.ioQueue, ^
    {
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        // convert NSString path to NSURL path
        NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        // build an enumerator by also prefetching file properties we want to read
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:diskCacheURL
                                                                     includingPropertiesForKeys:@[ NSURLIsDirectoryKey, NSURLContentModificationDateKey ]
                                                                                        options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                   errorHandler:NULL];
        for (NSURL *fileURL in fileEnumerator)
        {
            // skip folder
            NSNumber *isDirectory;
            [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
            if ([isDirectory boolValue])
            {
                continue;
            }
            
            // compare file date with the max age
            NSDate *fileModificationDate;
            [fileURL getResourceValue:&fileModificationDate forKey:NSURLContentModificationDateKey error:NULL];
            if ([[fileModificationDate laterDate:expirationDate] isEqualToDate:expirationDate])
            {
                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
            }
        }
    });
}

-(int)getSize
{
    int size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (int)getDiskCount
{
    int count = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        count += 1;
    }
    
    return count;
}

@end
