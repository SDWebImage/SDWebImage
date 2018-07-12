/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageLoadersManager.h"
#import "SDWebImageDownloader.h"

@interface SDImageLoadersManager ()

@property (nonatomic, strong, nonnull) dispatch_semaphore_t loadersLock;

@end

@implementation SDImageLoadersManager

+ (SDImageLoadersManager *)sharedManager {
    static dispatch_once_t onceToken;
    static SDImageLoadersManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [[SDImageLoadersManager alloc] init];
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

- (void)addLoader:(id<SDImageLoader>)loader {
    if (![loader conformsToProtocol:@protocol(SDImageLoader)]) {
        return;
    }
    LOCK(self.loadersLock);
    NSMutableArray<id<SDImageLoader>> *mutableLoaders = [self.loaders mutableCopy];
    if (!mutableLoaders) {
        mutableLoaders = [NSMutableArray array];
    }
    [mutableLoaders addObject:loader];
    self.loaders = [mutableLoaders copy];
    UNLOCK(self.loadersLock);
}

- (void)removeLoader:(id<SDImageLoader>)loader {
    if (![loader conformsToProtocol:@protocol(SDImageLoader)]) {
        return;
    }
    LOCK(self.loadersLock);
    NSMutableArray<id<SDImageLoader>> *mutableLoaders = [self.loaders mutableCopy];
    [mutableLoaders removeObject:loader];
    self.loaders = [mutableLoaders copy];
    UNLOCK(self.loadersLock);
}

#pragma mark - SDImageLoader

- (BOOL)canLoadWithURL:(nullable NSURL *)url {
    LOCK(self.loadersLock);
    NSArray<id<SDImageLoader>> *loaders = self.loaders;
    UNLOCK(self.loadersLock);
    for (id<SDImageLoader> loader in loaders.reverseObjectEnumerator) {
        if ([loader canLoadWithURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (id<SDWebImageOperation>)loadImageWithURL:(NSURL *)url options:(SDWebImageOptions)options context:(SDWebImageContext *)context progress:(SDImageLoaderProgressBlock)progressBlock completed:(SDImageLoaderCompletedBlock)completedBlock {
    if (!url) {
        return nil;
    }
    LOCK(self.loadersLock);
    NSArray<id<SDImageLoader>> *loaders = self.loaders;
    UNLOCK(self.loadersLock);
    for (id<SDImageLoader> loader in loaders.reverseObjectEnumerator) {
        if ([loader canLoadWithURL:url]) {
            return [loader loadImageWithURL:url options:options context:context progress:progressBlock completed:completedBlock];
        }
    }
    return nil;
}

@end
