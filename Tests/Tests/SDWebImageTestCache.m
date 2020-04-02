/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTestCache.h"
#import <SDWebImage/SDWebImage.h>
#import "SDFileAttributeHelper.h"

static NSString * const SDWebImageTestDiskCacheExtendedAttributeName = @"com.hackemist.SDWebImageTestDiskCache";

@implementation SDWebImageTestMemoryCache

- (nonnull instancetype)initWithConfig:(nonnull SDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

- (nullable id)objectForKey:(nonnull id)key {
    return [self.cache objectForKey:key];
}

- (void)removeAllObjects {
    [self.cache removeAllObjects];
}

- (void)removeObjectForKey:(nonnull id)key {
    [self.cache removeObjectForKey:key];
}

- (void)setObject:(nullable id)object forKey:(nonnull id)key {
    [self.cache setObject:object forKey:key];
}

- (void)setObject:(nullable id)object forKey:(nonnull id)key cost:(NSUInteger)cost {
    [self.cache setObject:object forKey:key cost:cost];
}

@end

@implementation SDWebImageTestDiskCache

- (nullable NSString *)cachePathForKey:(nonnull NSString *)key {
    return [self.cachePath stringByAppendingPathComponent:key.lastPathComponent];
}

- (BOOL)containsDataForKey:(nonnull NSString *)key {
    return [self.fileManager fileExistsAtPath:[self cachePathForKey:key]];
}

- (nullable NSData *)dataForKey:(nonnull NSString *)key {
    return [self.fileManager contentsAtPath:[self cachePathForKey:key]];
}

- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePath config:(nonnull SDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        self.cachePath = cachePath;
        self.config = config;
        self.fileManager = config.fileManager ? config.fileManager : [NSFileManager new];
        [self.fileManager createDirectoryAtPath:self.cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return self;
}

- (void)removeAllData {
    for (NSString *path in [self.fileManager subpathsAtPath:self.cachePath]) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:path];
        [self.fileManager removeItemAtPath:filePath error:nil];
    }
}

- (void)removeDataForKey:(nonnull NSString *)key {
    [self.fileManager removeItemAtPath:[self cachePathForKey:key] error:nil];
}

- (void)removeExpiredData {
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.config.maxDiskAge];
    for (NSString *fileName in [self.fileManager enumeratorAtPath:self.cachePath]) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:fileName];
        NSDate *modificationDate = [[self.fileManager attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileModificationDate];
        if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [self.fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

- (void)setData:(nullable NSData *)data forKey:(nonnull NSString *)key {
    [self.fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
}

- (NSUInteger)totalCount {
    return [self.fileManager contentsOfDirectoryAtPath:self.cachePath error:nil].count;
}

- (NSUInteger)totalSize {
    NSUInteger size = 0;
    for (NSString *fileName in [self.fileManager enumeratorAtPath:self.cachePath]) {
        NSString *filePath = [self.cachePath stringByAppendingPathComponent:fileName];
        size += [[[self.fileManager attributesOfItemAtPath:filePath error:nil] objectForKey:NSFileSize] unsignedIntegerValue];
    }
    return size;
}

- (nullable NSData *)extendedDataForKey:(nonnull NSString *)key {
    NSString *cachePathForKey = [self cachePathForKey:key];
    return [SDFileAttributeHelper extendedAttribute:SDWebImageTestDiskCacheExtendedAttributeName atPath:cachePathForKey traverseLink:NO error:nil];
}

- (void)setExtendedData:(nullable NSData *)extendedData forKey:(nonnull NSString *)key {
    NSString *cachePathForKey = [self cachePathForKey:key];
    if (!extendedData) {
        [SDFileAttributeHelper removeExtendedAttribute:SDWebImageTestDiskCacheExtendedAttributeName atPath:cachePathForKey traverseLink:NO error:nil];
    } else {
        [SDFileAttributeHelper setExtendedAttribute:SDWebImageTestDiskCacheExtendedAttributeName value:extendedData atPath:cachePathForKey traverseLink:NO overwrite:YES error:nil];
    }
}

@end

@implementation SDWebImageTestCache

+ (SDWebImageTestCache *)sharedCache {
    static dispatch_once_t onceToken;
    static SDWebImageTestCache *cache;
    dispatch_once(&onceToken, ^{
        NSString *cachePath = [[self userCacheDirectory] stringByAppendingPathComponent:@"SDWebImageTestCache"];
        SDImageCacheConfig *config = SDImageCacheConfig.defaultCacheConfig;
        cache = [[SDWebImageTestCache alloc] initWithCachePath:cachePath config:config];
    });
    return cache;
}

- (instancetype)initWithCachePath:(NSString *)cachePath config:(SDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.memoryCache = [[SDWebImageTestMemoryCache alloc] initWithConfig:config];
        self.diskCache = [[SDWebImageTestDiskCache alloc] initWithCachePath:cachePath config:config];
    }
    return self;
}

- (void)clearWithCacheType:(SDImageCacheType)cacheType completion:(nullable SDWebImageNoParamsBlock)completionBlock {
    switch (cacheType) {
        case SDImageCacheTypeNone:
            break;
        case SDImageCacheTypeMemory:
            [self.memoryCache removeAllObjects];
            break;
        case SDImageCacheTypeDisk:
            [self.diskCache removeAllData];
            break;
        case SDImageCacheTypeAll:
            [self.memoryCache removeAllObjects];
            [self.diskCache removeAllData];
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock();
    }
}

- (void)containsImageForKey:(nullable NSString *)key cacheType:(SDImageCacheType)cacheType completion:(nullable SDImageCacheContainsCompletionBlock)completionBlock {
    SDImageCacheType containsCacheType = SDImageCacheTypeNone;
    switch (cacheType) {
        case SDImageCacheTypeNone:
            break;
        case SDImageCacheTypeMemory:
            containsCacheType = [self.memoryCache objectForKey:key] ? SDImageCacheTypeMemory : SDImageCacheTypeNone;
            break;
        case SDImageCacheTypeDisk:
            containsCacheType = [self.diskCache containsDataForKey:key] ? SDImageCacheTypeDisk : SDImageCacheTypeNone;
            break;
        case SDImageCacheTypeAll:
            if ([self.memoryCache objectForKey:key]) {
                containsCacheType = SDImageCacheTypeMemory;
            } else if ([self.diskCache containsDataForKey:key]) {
                containsCacheType = SDImageCacheTypeDisk;
            }
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock(containsCacheType);
    }
}

- (nullable id<SDWebImageOperation>)queryImageForKey:(nullable NSString *)key options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context completion:(nullable SDImageCacheQueryCompletionBlock)completionBlock {
    return [self queryImageForKey:key options:options context:context cacheType:SDImageCacheTypeAll completion:completionBlock];
}

- (nullable id<SDWebImageOperation>)queryImageForKey:(nullable NSString *)key options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context cacheType:(SDImageCacheType)cacheType completion:(nullable SDImageCacheQueryCompletionBlock)completionBlock {
    UIImage *image;
    NSData *data;
    SDImageCacheType resultCacheType = SDImageCacheTypeNone;
    switch (cacheType) {
        case SDImageCacheTypeNone:
            break;
        case SDImageCacheTypeMemory:
            image = [self.memoryCache objectForKey:key];
            if (image) {
                resultCacheType = SDImageCacheTypeMemory;
            }
            break;
        case SDImageCacheTypeDisk:
            data = [self.diskCache dataForKey:key];
            image = [UIImage sd_imageWithData:data];
            if (data) {
                resultCacheType = SDImageCacheTypeDisk;
            }
            break;
        case SDImageCacheTypeAll:
            image = [self.memoryCache objectForKey:key];
            if (image) {
                resultCacheType = SDImageCacheTypeMemory;
            } else {
                data = [self.diskCache dataForKey:key];
                image = [UIImage sd_imageWithData:data];
                if (data) {
                    resultCacheType = SDImageCacheTypeDisk;
                }
            }
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock(image, data, resultCacheType);
    }
    return nil;
}

- (void)removeImageForKey:(nullable NSString *)key cacheType:(SDImageCacheType)cacheType completion:(nullable SDWebImageNoParamsBlock)completionBlock {
    switch (cacheType) {
        case SDImageCacheTypeNone:
            break;
        case SDImageCacheTypeMemory:
            [self.memoryCache removeObjectForKey:key];
            break;
        case SDImageCacheTypeDisk:
            [self.diskCache removeDataForKey:key];
            break;
        case SDImageCacheTypeAll:
            [self.memoryCache removeObjectForKey:key];
            [self.diskCache removeDataForKey:key];
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock();
    }
}

- (void)storeImage:(nullable UIImage *)image imageData:(nullable NSData *)imageData forKey:(nullable NSString *)key cacheType:(SDImageCacheType)cacheType completion:(nullable SDWebImageNoParamsBlock)completionBlock {
    switch (cacheType) {
        case SDImageCacheTypeNone:
            break;
        case SDImageCacheTypeMemory:
            [self.memoryCache setObject:image forKey:key];
            break;
        case SDImageCacheTypeDisk:
            [self.diskCache setData:imageData forKey:key];
            break;
        case SDImageCacheTypeAll:
            [self.memoryCache setObject:image forKey:key];
            [self.diskCache setData:imageData forKey:key];
            break;
        default:
            break;
    }
    if (completionBlock) {
        completionBlock();
    }
}

+ (nullable NSString *)userCacheDirectory {
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return paths.firstObject;
}

@end
