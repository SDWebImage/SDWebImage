/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTestCache.h"
#import <SDWebImage/SDImageCacheConfig.h>
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
    return [self.cachePath stringByAppendingPathComponent:key];
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
    [self.fileManager removeItemAtPath:self.cachePath error:nil];
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
