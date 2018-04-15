/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageLoadersManager.h"
#import "SDWebImageDownloader.h"

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

@interface SDWebImageLoadersManager ()

@property (strong, nonatomic, nonnull) NSMutableArray<id<SDWebImageLoader>> *mutableLoaders;
@property (nonatomic, strong, nonnull) dispatch_semaphore_t loadersLock;

@end

@implementation SDWebImageLoadersManager

+ (SDWebImageLoadersManager *)sharedManager {
    static dispatch_once_t onceToken;
    static SDWebImageLoadersManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[SDWebImageLoadersManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // initialize with default image loaders
        self.mutableLoaders = [@[[SDWebImageDownloader sharedDownloader]] mutableCopy];
        self.loadersLock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Loader Property

- (void)addLoader:(id<SDWebImageLoader>)loader {
    if ([loader conformsToProtocol:@protocol(SDWebImageLoader)]) {
        LOCK(self.loadersLock);
        [self.mutableLoaders addObject:loader];
        UNLOCK(self.loadersLock);
    }
}

- (void)removeLoader:(id<SDWebImageLoader>)loader {
    LOCK(self.loadersLock);
    [self.mutableLoaders removeObject:loader];
    UNLOCK(self.loadersLock);
}

- (NSArray<id<SDWebImageLoader>> *)loaders {
    NSArray<id<SDWebImageLoader>> *sortedLoaders;
    LOCK(self.loadersLock);
    sortedLoaders = [[[self.mutableLoaders copy] reverseObjectEnumerator] allObjects];
    UNLOCK(self.loadersLock);
    return sortedLoaders;
}

- (void)setLoaders:(NSArray<id<SDWebImageLoader>> *)loaders {
    LOCK(self.loadersLock);
    self.mutableLoaders = [loaders mutableCopy];
    UNLOCK(self.loadersLock);
}

#pragma mark - SDWebImageLoader

- (BOOL)canLoadWithURL:(nullable NSURL *)url {
    for (id<SDWebImageLoader> loader in self.loaders) {
        if ([loader canLoadWithURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (id<SDWebImageOperation>)loadImageWithURL:(NSURL *)url options:(SDWebImageOptions)options context:(SDWebImageContext *)context progress:(SDWebImageLoaderProgressBlock)progressBlock completed:(SDWebImageLoaderCompletedBlock)completedBlock {
    if (!url) {
        return nil;
    }
    for (id<SDWebImageLoader> loader in self.loaders) {
        if ([loader respondsToSelector:@selector(loadImageWithURL:options:context:progress:completed:)]) {
            if ([loader canLoadWithURL:url]) {
                return [loader loadImageWithURL:url options:options context:context progress:progressBlock completed:completedBlock];
            }
        }
    }
    return nil;
}

- (id<SDWebImageOperation>)loadImageDataWithURL:(NSURL *)url options:(SDWebImageOptions)options context:(SDWebImageContext *)context progress:(SDWebImageLoaderProgressBlock)progressBlock completed:(SDWebImageLoaderDataCompletedBlock)completedBlock {
    if (!url) {
        return nil;
    }
    for (id<SDWebImageLoader> loader in self.loaders) {
        if ([loader respondsToSelector:@selector(loadImageDataWithURL:options:context:progress:completed:)]) {
            if ([loader canLoadWithURL:url]) {
                return [loader loadImageDataWithURL:url options:options context:context progress:progressBlock completed:completedBlock];
            }
        }
    }
    return nil;
}

@end
