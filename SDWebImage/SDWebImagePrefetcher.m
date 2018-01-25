/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImagePrefetcher.h"
#import <libkern/OSAtomic.h>

@interface SDWebImagePrefetchToken () {
    @public
    int64_t _skippedCount;
    int64_t _finishedCount;
}

@property (nonatomic, copy, readwrite) NSArray<NSURL *> *urls;
@property (nonatomic, assign) int64_t totalCount;
@property (nonatomic, strong) NSMutableArray<id<SDWebImageOperation>> *operations;
@property (nonatomic, weak) SDWebImagePrefetcher *prefetcher;
@property (nonatomic, copy, nullable) SDWebImagePrefetcherCompletionBlock completionBlock;
@property (nonatomic, copy, nullable) SDWebImagePrefetcherProgressBlock progressBlock;

@end

@interface SDWebImagePrefetcher ()

@property (strong, nonatomic, nonnull) SDWebImageManager *manager;
@property (strong, atomic, nonnull) NSMutableSet<SDWebImagePrefetchToken *> *runningTokens;

@end

@implementation SDWebImagePrefetcher

+ (nonnull instancetype)sharedImagePrefetcher {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (nonnull instancetype)init {
    return [self initWithImageManager:[SDWebImageManager new]];
}

- (nonnull instancetype)initWithImageManager:(SDWebImageManager *)manager {
    if ((self = [super init])) {
        _manager = manager;
        _runningTokens = [NSMutableSet set];
        _options = SDWebImageLowPriority;
        _prefetcherQueue = dispatch_get_main_queue();
        self.maxConcurrentDownloads = 3;
    }
    return self;
}

- (void)setMaxConcurrentDownloads:(NSUInteger)maxConcurrentDownloads {
    self.manager.imageDownloader.maxConcurrentDownloads = maxConcurrentDownloads;
}

- (NSUInteger)maxConcurrentDownloads {
    return self.manager.imageDownloader.maxConcurrentDownloads;
}

#pragma mark - Prefetch
- (nullable SDWebImagePrefetchToken *)prefetchURLs:(nullable NSArray<NSURL *> *)urls {
    return [self prefetchURLs:urls progress:nil completed:nil];
}

- (nullable SDWebImagePrefetchToken *)prefetchURLs:(nullable NSArray<NSURL *> *)urls
                                          progress:(nullable SDWebImagePrefetcherProgressBlock)progressBlock
                                         completed:(nullable SDWebImagePrefetcherCompletionBlock)completionBlock {
    if (!urls || urls.count == 0) {
        if (completionBlock) {
            completionBlock(0, 0);
        }
        return nil;
    }
    SDWebImagePrefetchToken *token = [SDWebImagePrefetchToken new];
    token.prefetcher = self;
    token->_skippedCount = 0;
    token->_finishedCount = 0;
    token.urls = urls;
    token.totalCount = urls.count;
    token.operations = [NSMutableArray arrayWithCapacity:urls.count];
    token.progressBlock = progressBlock;
    token.completionBlock = completionBlock;
    [self addRunningToken:token];
    
    for (NSURL *url in urls) {
        __weak typeof(self) wself = self;
        id<SDWebImageOperation> operation = [self.manager loadImageWithURL:url options:self.options progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
            __strong typeof(wself) sself = wself;
            if (!sself) {
                return;
            }
            if (!finished) {
                return;
            }
            OSAtomicIncrement64(&(token->_finishedCount));
            if (error) {
                // Add last failed
                OSAtomicIncrement64(&(token->_skippedCount));
            }
            
            // Current operation finished
            [sself callProgressBlockForToken:token imageURL:imageURL];
            
            if (token->_finishedCount + token->_skippedCount == token.totalCount) {
                // All finished
                [sself callCompletionBlockForToken:token];
                [sself removeRunningToken:token];
            }
        } context:self.context];
        [token.operations addObject:operation];
    }
    
    return token;
}

#pragma mark - Cancel
- (void)cancelPrefetching {
    @synchronized(self.runningTokens) {
        NSSet<SDWebImagePrefetchToken *> *copiedTokens = [self.runningTokens copy];
        [copiedTokens makeObjectsPerformSelector:@selector(cancel)];
        [self.runningTokens removeAllObjects];
    }
}

- (void)callProgressBlockForToken:(SDWebImagePrefetchToken *)token imageURL:(NSURL *)url {
    if (!token) {
        return;
    }
    BOOL shouldCallDelegate = [self.delegate respondsToSelector:@selector(imagePrefetcher:didPrefetchURL:finishedCount:totalCount:)];
    dispatch_queue_async_safe(self.prefetcherQueue, ^{
        if (shouldCallDelegate) {
            [self.delegate imagePrefetcher:self didPrefetchURL:url finishedCount:[self tokenFinishedCount] totalCount:[self tokenTotalCount]];
        }
        if (token.progressBlock) {
            token.progressBlock((NSUInteger)token->_finishedCount, (NSUInteger)token.totalCount);
        }
    });
}

- (void)callCompletionBlockForToken:(SDWebImagePrefetchToken *)token {
    if (!token) {
        return;
    }
    BOOL shoulCallDelegate = [self.delegate respondsToSelector:@selector(imagePrefetcher:didFinishWithTotalCount:skippedCount:)] && ([self countOfRunningTokens] == 1); // last one
    dispatch_queue_async_safe(self.prefetcherQueue, ^{
        if (shoulCallDelegate) {
            [self.delegate imagePrefetcher:self didFinishWithTotalCount:[self tokenTotalCount] skippedCount:[self tokenSkippedCount]];
        }
        if (token.completionBlock) {
            token.completionBlock((NSUInteger)token->_finishedCount, (NSUInteger)token->_skippedCount);
        }
    });
}

#pragma mark - Helper
- (NSUInteger)tokenTotalCount {
    NSUInteger tokenTotalCount = 0;
    @synchronized (self.runningTokens) {
        for (SDWebImagePrefetchToken *token in self.runningTokens) {
            tokenTotalCount += token.totalCount;
        }
    }
    return tokenTotalCount;
}

- (NSUInteger)tokenSkippedCount {
    NSUInteger tokenSkippedCount = 0;
    @synchronized (self.runningTokens) {
        for (SDWebImagePrefetchToken *token in self.runningTokens) {
            tokenSkippedCount += token->_skippedCount;
        }
    }
    return tokenSkippedCount;
}

- (NSUInteger)tokenFinishedCount {
    NSUInteger tokenFinishedCount = 0;
    @synchronized (self.runningTokens) {
        for (SDWebImagePrefetchToken *token in self.runningTokens) {
            tokenFinishedCount += token->_finishedCount;
        }
    }
    return tokenFinishedCount;
}

- (void)addRunningToken:(SDWebImagePrefetchToken *)token {
    if (!token) {
        return;
    }
    @synchronized (self.runningTokens) {
        [self.runningTokens addObject:token];
    }
}

- (void)removeRunningToken:(SDWebImagePrefetchToken *)token {
    if (!token) {
        return;
    }
    @synchronized (self.runningTokens) {
        [self.runningTokens removeObject:token];
    }
}

- (NSUInteger)countOfRunningTokens {
    NSUInteger count = 0;
    @synchronized (self.runningTokens) {
        count = self.runningTokens.count;
    }
    return count;
}

@end

@implementation SDWebImagePrefetchToken

- (void)cancel {
    @synchronized (self) {
        for (id<SDWebImageOperation> operation in self.operations) {
            [operation cancel];
        }
    }
    [self.prefetcher removeRunningToken:self];
}

@end
