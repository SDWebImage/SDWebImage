/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCacheConfig.h"
#import "SDMemoryCache.h"
#import "SDDiskCache.h"

static SDImageCacheConfig * _defaultCacheConfig;
static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

@implementation SDImageCacheConfig

+ (SDImageCacheConfig *)defaultCacheConfig {
    if (!_defaultCacheConfig) {
        _defaultCacheConfig = [SDImageCacheConfig new];
    }
    return _defaultCacheConfig;
}

+ (void)setDefaultCacheConfig:(SDImageCacheConfig *)config {
    if (!config) {
        return;
    }
    _defaultCacheConfig = config;
}

- (instancetype)init {
    if (self = [super init]) {
        _shouldDecompressImages = YES;
        _shouldDisableiCloud = YES;
        _shouldCacheImagesInMemory = YES;
        _shouldRemoveExpiredDataWhenEnterBackground = YES;
        _diskCacheReadingOptions = 0;
        _diskCacheWritingOptions = NSDataWritingAtomic;
        _maxCacheAge = kDefaultCacheMaxCacheAge;
        _maxCacheSize = 0;
        _memoryCacheClass = [SDMemoryCache class];
        _diskCacheClass = [SDDiskCache class];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SDImageCacheConfig *config = [[[self class] allocWithZone:zone] init];
    config.shouldDecompressImages = self.shouldDecompressImages;
    config.shouldDisableiCloud = self.shouldDisableiCloud;
    config.shouldCacheImagesInMemory = self.shouldCacheImagesInMemory;
    config.shouldRemoveExpiredDataWhenEnterBackground = self.shouldRemoveExpiredDataWhenEnterBackground;
    config.diskCacheReadingOptions = self.diskCacheReadingOptions;
    config.diskCacheWritingOptions = self.diskCacheWritingOptions;
    config.maxCacheAge = self.maxCacheAge;
    config.maxCacheSize = self.maxCacheSize;
    config.maxMemoryCost = self.maxMemoryCost;
    config.maxMemoryCount = self.maxMemoryCount;
    config.fileManager = self.fileManager; // NSFileManager does not conform to NSCopying, just pass the reference
    config.memoryCacheClass = self.memoryCacheClass;
    config.diskCacheClass = self.diskCacheClass;
    
    return config;
}

@end
