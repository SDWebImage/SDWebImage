/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImagePrefetcher.h"
#import "SDAsyncBlockOperation.h"
#import <stdatomic.h>

@interface SDWebImagePrefetchToken () {
    @public
    // Though current implementation, `SDWebImageManager` completion block is always on main queue. But however, there is no guarantee in docs. And we may introduce config to specify custom queue in the future.
    // These value are just used as incrementing counter, keep thread-safe using memory_order_relaxed for performance.
    atomic_ulong _skippedCount;
    atomic_ulong _finishedCount;
    atomic_flag  _isAllFinished;
    
    unsigned long _totalCount;
}

@property (nonatomic, copy, readwrite) NSArray<NSURL *> *urls;
@property (nonatomic, strong) NSPointerArray *operations;
@property (nonatomic, weak) SDWebImagePrefetcher *prefetcher;
@property (nonatomic, copy, nullable) SDWebImagePrefetcherCompletionBlock completionBlock;
@property (nonatomic, copy, nullable) SDWebImagePrefetcherProgressBlock progressBlock;

@end

@interface SDWebImagePrefetcher ()

@property (strong, nonatomic, nonnull) SDWebImageManager *manager;
@property (strong, atomic, nonnull) NSMutableSet<SDWebImagePrefetchToken *> *runningTokens;
@property (strong, nonatomic, nonnull) NSOperationQueue *prefetchQueue;

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
        _delegateQueue = dispatch_get_main_queue();
        _prefetchQueue = [NSOperationQueue new];
        self.maxConcurrentPrefetchCount = 3;
    }
    return self;
}

- (void)setMaxConcurrentPrefetchCount:(NSUInteger)maxConcurrentPrefetchCount {
    self.prefetchQueue.maxConcurrentOperationCount = maxConcurrentPrefetchCount;
}

- (NSUInteger)maxConcurrentPrefetchCount {
    return self.prefetchQueue.maxConcurrentOperationCount;
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
    token.urls = urls;
    token->_skippedCount = 0;
    token->_finishedCount = 0;
    token->_totalCount = token.urls.count;
    atomic_flag_clear(&(token->_isAllFinished));
    token.operations = [NSPointerArray weakObjectsPointerArray];
    token.progressBlock = progressBlock;
    token.completionBlock = completionBlock;
    [self addRunningToken:token];
    [self startPrefetchWithToken:token];
    
    return token;
}

- (void)startPrefetchWithToken:(SDWebImagePrefetchToken * _Nonnull)token {
    NSPointerArray *operations = token.operations;
    for (NSURL *url in token.urls) {
        __weak typeof(self) wself = self;
        SDAsyncBlockOperation *prefetchOperation = [SDAsyncBlockOperation blockOperationWithBlock:^(SDAsyncBlockOperation * _Nonnull asyncOperation) {
             __strong typeof(wself) strongSelf = wself;
             if (!strongSelf) {
                 return;
             }
             id<SDWebImageOperation> operation = [strongSelf.manager loadImageWithURL:url options:strongSelf.options context:strongSelf.context progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                 __strong typeof(wself) sself = wself;
                 if (!sself) {
                     return;
                 }
                 if (!finished) {
                     return;
                 }
                 [asyncOperation complete];
                 
                 atomic_fetch_add_explicit(&(token->_finishedCount), 1, memory_order_relaxed);
                 if (error) {
                     // Add last failed
                     atomic_fetch_add_explicit(&(token->_skippedCount), 1, memory_order_relaxed);
                 }
                 
                 // Current operation finished
                 [sself callProgressBlockForToken:token imageURL:imageURL];
                 
                 if (atomic_load_explicit(&(token->_finishedCount), memory_order_relaxed) == token->_totalCount) {
                     // All finished
                     if (!atomic_flag_test_and_set_explicit(&(token->_isAllFinished), memory_order_relaxed)) {
                         [sself callCompletionBlockForToken:token];
                         [sself removeRunningToken:token];
                     }
                 }
             }];
            @synchronized (token) {
                [operations addPointer:(__bridge void *)operation];
            }
        }];
        [self.prefetchQueue addOperation:prefetchOperation];
    }
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
    NSUInteger tokenFinishedCount = [self tokenFinishedCount];
    NSUInteger tokenTotalCount = [self tokenTotalCount];
    NSUInteger finishedCount = atomic_load_explicit(&(token->_finishedCount), memory_order_relaxed);
    NSUInteger totalCount = token->_totalCount;
    dispatch_async(self.delegateQueue, ^{
        if (shouldCallDelegate) {
            [self.delegate imagePrefetcher:self didPrefetchURL:url finishedCount:tokenFinishedCount totalCount:tokenTotalCount];
        }
        if (token.progressBlock) {
            token.progressBlock(finishedCount, totalCount);
        }
    });
}

- (void)callCompletionBlockForToken:(SDWebImagePrefetchToken *)token {
    if (!token) {
        return;
    }
    BOOL shoulCallDelegate = [self.delegate respondsToSelector:@selector(imagePrefetcher:didFinishWithTotalCount:skippedCount:)] && ([self countOfRunningTokens] == 1); // last one
    NSUInteger tokenTotalCount = [self tokenTotalCount];
    NSUInteger tokenSkippedCount = [self tokenSkippedCount];
    NSUInteger finishedCount = atomic_load_explicit(&(token->_finishedCount), memory_order_relaxed);
    NSUInteger skippedCount = atomic_load_explicit(&(token->_skippedCount), memory_order_relaxed);
    dispatch_async(self.delegateQueue, ^{
        if (shoulCallDelegate) {
            [self.delegate imagePrefetcher:self didFinishWithTotalCount:tokenTotalCount skippedCount:tokenSkippedCount];
        }
        if (token.completionBlock) {
            token.completionBlock(finishedCount, skippedCount);
        }
    });
}

#pragma mark - Helper
- (NSUInteger)tokenTotalCount {
    NSUInteger tokenTotalCount = 0;
    @synchronized (self.runningTokens) {
        for (SDWebImagePrefetchToken *token in self.runningTokens) {
            tokenTotalCount += token->_totalCount;
        }
    }
    return tokenTotalCount;
}

- (NSUInteger)tokenSkippedCount {
    NSUInteger tokenSkippedCount = 0;
    @synchronized (self.runningTokens) {
        for (SDWebImagePrefetchToken *token in self.runningTokens) {
            tokenSkippedCount += atomic_load_explicit(&(token->_skippedCount), memory_order_relaxed);
        }
    }
    return tokenSkippedCount;
}

- (NSUInteger)tokenFinishedCount {
    NSUInteger tokenFinishedCount = 0;
    @synchronized (self.runningTokens) {
        for (SDWebImagePrefetchToken *token in self.runningTokens) {
            tokenFinishedCount += atomic_load_explicit(&(token->_finishedCount), memory_order_relaxed);
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
        for (id operation in self.operations) {
            if ([operation conformsToProtocol:@protocol(SDWebImageOperation)]) {
                [operation cancel];
            }
        }
        self.operations.count = 0;
    }
    self.completionBlock = nil;
    self.progressBlock = nil;
    [self.prefetcher removeRunningToken:self];
}

@end
