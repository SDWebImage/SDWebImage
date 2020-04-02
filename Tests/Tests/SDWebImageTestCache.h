/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <SDWebImage/SDMemoryCache.h>
#import <SDWebImage/SDDiskCache.h>
#import <SDWebImage/SDImageCacheDefine.h>

// A really naive implementation of custom memory cache and disk cache
@interface SDWebImageTestMemoryCache : NSObject <SDMemoryCache>

@property (nonatomic, strong, nonnull) SDImageCacheConfig *config;
@property (nonatomic, strong, nonnull) NSCache *cache;

@end

@interface SDWebImageTestDiskCache : NSObject <SDDiskCache>

@property (nonatomic, strong, nonnull) SDImageCacheConfig *config;
@property (nonatomic, copy, nonnull) NSString *cachePath;
@property (nonatomic, strong, nonnull) NSFileManager *fileManager;

@end

// A really naive implementation of custom image cache using memory cache and disk cache
@interface SDWebImageTestCache : NSObject <SDImageCache>

@property (nonatomic, strong, nonnull) SDImageCacheConfig *config;
@property (nonatomic, strong, nonnull) SDWebImageTestMemoryCache *memoryCache;
@property (nonatomic, strong, nonnull) SDWebImageTestDiskCache *diskCache;

- (nullable instancetype)initWithCachePath:(nonnull NSString *)cachePath config:(nonnull SDImageCacheConfig *)config;

@property (nonatomic, class, readonly, nonnull) SDWebImageTestCache *sharedCache;

@end
