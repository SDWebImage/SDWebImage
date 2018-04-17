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
        self.loaders = @[[SDWebImageDownloader sharedDownloader]];
        self.loadersLock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Loader Property

- (void)addLoader:(id<SDWebImageLoader>)loader {
    if (![loader conformsToProtocol:@protocol(SDWebImageLoader)]) {
        return;
    }
    LOCK(self.loadersLock);
    NSMutableArray<id<SDWebImageLoader>> *mutableLoaders = [self.loaders mutableCopy];
    if (!mutableLoaders) {
        mutableLoaders = [NSMutableArray array];
    }
    [mutableLoaders addObject:loader];
    self.loaders = [mutableLoaders copy];
    UNLOCK(self.loadersLock);
}

- (void)removeLoader:(id<SDWebImageLoader>)loader {
    if (![loader conformsToProtocol:@protocol(SDWebImageLoader)]) {
        return;
    }
    LOCK(self.loadersLock);
    NSMutableArray<id<SDWebImageLoader>> *mutableLoaders = [self.loaders mutableCopy];
    [mutableLoaders removeObject:loader];
    self.loaders = [mutableLoaders copy];
    UNLOCK(self.loadersLock);
}

#pragma mark - SDWebImageLoader

- (BOOL)canLoadWithURL:(nullable NSURL *)url {
    LOCK(self.loadersLock);
    NSArray<id<SDWebImageLoader>> *loaders = self.loaders;
    UNLOCK(self.loadersLock);
    for (id<SDWebImageLoader> loader in loaders.reverseObjectEnumerator) {
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
    LOCK(self.loadersLock);
    NSArray<id<SDWebImageLoader>> *loaders = self.loaders;
    UNLOCK(self.loadersLock);
    for (id<SDWebImageLoader> loader in loaders.reverseObjectEnumerator) {
        if ([loader respondsToSelector:@selector(loadImageWithURL:options:context:progress:completed:)]) {
            return [loader loadImageWithURL:url options:options context:context progress:progressBlock completed:completedBlock];
        }
    }
    return nil;
}

@end
