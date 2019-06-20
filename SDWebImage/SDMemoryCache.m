/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDMemoryCache.h"
#import "SDImageCacheConfig.h"
#import "UIImage+MemoryCacheCost.h"
#import "SDInternalMacros.h"
#import "SDMemoryNSCache.h"
#import "SDMemoryLRUCache.h"

@interface SDMemoryCache <KeyType, ObjectType> ()

@property (nonatomic, strong, nullable) SDImageCacheConfig *config;

@property (nonatomic, strong) id<SDMemoryCache> memCache;

@end

@implementation SDMemoryCache

- (instancetype)init {
    self = [super init];
    if (self) {
        _config = [[SDImageCacheConfig alloc] init];
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithConfig:(SDImageCacheConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    if (self.config.shouldUseLRUMemoryCache) {
        self.memCache = [[SDMemoryLRUCache alloc] initWithConfig:self.config];
    } else {
        self.memCache = [[SDMemoryNSCache alloc] initWithConfig:self.config];
    }
}


- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g {
    [self.memCache setObject:obj forKey:key cost:(NSUInteger)g];
}

- (id)objectForKey:(id)key {
    return [self.memCache objectForKey:key];
}

- (void)removeObjectForKey:(id)key {
    [self.memCache removeObjectForKey:key];
}

- (void)removeAllObjects {
    [self.memCache removeAllObjects];
}

@end
