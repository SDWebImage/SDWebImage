/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImagePrefetcher.h"

@interface SDWebImagePrefetcher ()

@property (strong, nonatomic) SDWebImageManager *manager;
@property (strong, nonatomic) NSMutableOrderedSet *prefetchURLs;
@property (strong, nonatomic) NSMutableDictionary *unfinishedOperations;
@property (assign, nonatomic) NSUInteger requestedCount;
@property (assign, nonatomic) NSUInteger skippedCount;
@property (assign, nonatomic) NSUInteger finishedCount;
@property (assign, nonatomic) NSTimeInterval startedTime;
@property (copy, nonatomic) SDWebImagePrefetcherCompletionBlock completionBlock;
@property (copy, nonatomic) SDWebImagePrefetcherProgressBlock progressBlock;

@end

@implementation SDWebImagePrefetcher

+ (instancetype)sharedImagePrefetcher {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    return [self initWithImageManager:[SDWebImageManager new]];
}

- (id)initWithImageManager:(SDWebImageManager *)manager {
    if ((self = [super init])) {
        _manager = manager;
        _options = SDWebImageLowPriority;
        _prefetcherQueue = dispatch_get_main_queue();
        self.maxConcurrentDownloads = 3;
        _unfinishedOperations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setMaxConcurrentDownloads:(NSUInteger)maxConcurrentDownloads {
    self.manager.imageDownloader.maxConcurrentDownloads = maxConcurrentDownloads;
}

- (NSUInteger)maxConcurrentDownloads {
    return self.manager.imageDownloader.maxConcurrentDownloads;
}

- (void)reportStatus {
    NSUInteger total = [self.prefetchURLs count];
    NSLog(@"Finished prefetching (%@ successful, %@ skipped, timeElasped %.2f)", @(total - self.skippedCount), @(self.skippedCount), CFAbsoluteTimeGetCurrent() - self.startedTime);
    if ([self.delegate respondsToSelector:@selector(imagePrefetcher:didFinishWithTotalCount:skippedCount:)]) {
        [self.delegate imagePrefetcher:self
               didFinishWithTotalCount:(total - self.skippedCount)
                          skippedCount:self.skippedCount
         ];
    }
}

- (void)prefetchURLs:(NSArray *)urls {
    [self prefetchURLs:urls progress:nil completed:nil];
}

- (void)prefetchURLs:(NSArray *)urls progress:(SDWebImagePrefetcherProgressBlock)progressBlock completed:(SDWebImagePrefetcherCompletionBlock)completionBlock {
    self.startedTime = CFAbsoluteTimeGetCurrent();
    self.progressBlock = progressBlock;
    self.completionBlock = completionBlock;

    if (urls.count == 0) {
        if (completionBlock) {
            completionBlock(0,0);
        }
    } else {
        // get only the urls that are not currently being prefetched.
        NSMutableOrderedSet *newUrls = [NSMutableOrderedSet orderedSetWithArray:urls];
        [newUrls minusOrderedSet:self.prefetchURLs];

        // add the new urls to the current list.
        [self.prefetchURLs unionOrderedSet:newUrls];

        for (NSURL *url in newUrls) {
            [self startPrefetchingUrl:url];
        }
    }
}


- (void)startPrefetchingUrl:(NSURL *)url {
    self.requestedCount++;
    __weak id<SDWebImageOperation> operation = [self.manager downloadImageWithURL:url options:self.options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
        if (!finished) return;
        self.finishedCount++;

        if (image) {
            if (self.progressBlock) {
                self.progressBlock(self.finishedCount,[self.prefetchURLs count]);
            }
        }
        else {
            if (self.progressBlock) {
                self.progressBlock(self.finishedCount,[self.prefetchURLs count]);
            }

            // Add last failed
            self.skippedCount++;
        }

        if ([self.delegate respondsToSelector:@selector(imagePrefetcher:didPrefetchURL:finishedCount:totalCount:)]) {
            [self.delegate imagePrefetcher:self
                            didPrefetchURL:url
                             finishedCount:self.finishedCount
                                totalCount:self.prefetchURLs.count
             ];
        }
        else if (self.finishedCount == self.requestedCount) {
            [self reportStatus];
            if (self.completionBlock) {
                self.completionBlock(self.finishedCount, self.skippedCount);
                self.completionBlock = nil;
            }
            self.progressBlock = nil;
        }

        @synchronized(self.unfinishedOperations) {
            if ([self.unfinishedOperations objectForKey:url]) {
                [self.unfinishedOperations removeObjectForKey:url];
            }
        }
    }];

    @synchronized(self.unfinishedOperations) {
        if (operation) {
            self.unfinishedOperations[url] = operation;
        }
    }
}

- (void)cancelPrefetchingForURL:(NSURL *)url
{
    id<SDWebImageOperation> operation = self.unfinishedOperations[url];
    if (operation) {
        [self.manager cancelOperations:@[operation]];
    }
}

- (void)cancelPrefetching {
    self.prefetchURLs = nil;
    self.skippedCount = 0;
    self.requestedCount = 0;
    self.finishedCount = 0;
    [self.manager cancelOperations:self.unfinishedOperations.allValues];
    [self.unfinishedOperations removeAllObjects];
}

@end
