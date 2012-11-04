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

const char *kDiskIOQueueName = "com.hackemist.SDWebImageDiskCache";
static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

@interface SDImageCache ()

@property (strong, nonatomic) NSCache *memCache;
@property (strong, nonatomic) NSString *diskCachePath;

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

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
        UIDevice *device = [UIDevice currentDevice];
        if ([device respondsToSelector:@selector(isMultitaskingSupported)] && device.multitaskingSupported)
        {
            // When in background, clean memory in order to have less chance to be killed
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(clearMemory)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
        }
#endif
#endif
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);

        dispatch_async(queue, ^
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
                if (![[NSFileManager defaultManager] fileExistsAtPath:_diskCachePath])
                {
                    [[NSFileManager defaultManager] createDirectoryAtPath:_diskCachePath
                                              withIntermediateDirectories:YES
                                                               attributes:nil
                                                                    error:NULL];
                }

                NSString *path = [self cachePathForKey:key];
                dispatch_io_t ioChannel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, [path UTF8String], O_RDWR | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH, queue, nil);
                dispatch_data_t dispatchData = dispatch_data_create(data.bytes, data.length, queue, ^{[data self];});

                dispatch_io_write(ioChannel, 0, dispatchData, queue, ^(bool done, dispatch_data_t dispatchedData, int error)
                {
                    if (error != 0)
                    {
                        NSLog(@"SDWebImageCache: Error writing image from disk cache: errno=%d", error);
                    }
                    if(done)
                    {
                        dispatch_io_close(ioChannel, 0);
                    }
                });

                dispatch_release(dispatchData);
                dispatch_release(ioChannel);
            }
        });
        dispatch_release(queue);
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

- (void)queryDiskCacheForKey:(NSString *)key done:(void (^)(UIImage *image))doneBlock
{
    if (!doneBlock) return;

    if (!key)
    {
        doneBlock(nil);
        return;
    }

    // First check the in-memory cache...
    UIImage *image = [self.memCache objectForKey:key];
    if (image)
    {
        doneBlock(image);
        return;
    }

    NSString *path = [self cachePathForKey:key];
    dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
    dispatch_io_t ioChannel = dispatch_io_create_with_path(DISPATCH_IO_STREAM, path.UTF8String, O_RDONLY, 0, queue, nil);
    dispatch_io_read(ioChannel, 0, SIZE_MAX, queue, ^(bool done, dispatch_data_t dispatchedData, int error)
    {
        if (error)
        {
            if (error != 2)
            {
                NSLog(@"SDWebImageCache: Error reading image from disk cache: errno=%d", error);
            }
            doneBlock(nil);
            return;
        }

        dispatch_data_apply(dispatchedData, (dispatch_data_applier_t)^(dispatch_data_t region, size_t offset, const void *buffer, size_t size)
        {
            UIImage *diskImage = SDScaledImageForPath(key, [NSData dataWithBytes:buffer length:size]);

            if (image)
            {
                UIImage *decodedImage = [UIImage decodedImageWithImage:diskImage];
                if (decodedImage)
                {
                    diskImage = decodedImage;
                }

                [self.memCache setObject:diskImage forKey:key cost:image.size.height * image.size.width * image.scale];
            }

            doneBlock(diskImage);

            return true;
        });
    });

    dispatch_release(queue);
    dispatch_release(ioChannel);

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
        dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
        dispatch_async(queue, ^
        {
            [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
        });
        dispatch_release(queue);
    }
}

- (void)clearMemory
{
    [self.memCache removeAllObjects];
}

- (void)clearDisk
{
    dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
    dispatch_async(queue, ^
    {
        [[NSFileManager defaultManager] removeItemAtPath:self.diskCachePath error:nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    });
    dispatch_release(queue);
}

- (void)cleanDisk
{
    dispatch_queue_t queue = dispatch_queue_create(kDiskIOQueueName, nil);
    dispatch_async(queue, ^
    {
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
        for (NSString *fileName in fileEnumerator)
        {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
            if ([[[attrs fileModificationDate] laterDate:expirationDate] isEqualToDate:expirationDate])
            {
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
        }
    });
    dispatch_release(queue);
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
