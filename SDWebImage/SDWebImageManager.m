/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager.h"
#import <objc/message.h>

@interface SDWebImageCombinedOperation : NSObject <SDWebImageOperation>

@property (assign, nonatomic, getter = isCancelled) BOOL cancelled;
@property (copy, nonatomic) void (^cancelBlock)();

@end

@interface SDWebImageManager ()

@property (strong, nonatomic, readwrite) SDImageCache *imageCache;
@property (strong, nonatomic, readwrite) SDWebImageDownloader *imageDownloader;
@property (strong, nonatomic) NSMutableArray *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;

@end

@implementation SDWebImageManager

+ (id)sharedManager
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    if ((self = [super init]))
    {
        _imageCache = SDImageCache.new;
        _imageDownloader = SDWebImageDownloader.new;
        _failedURLs = NSMutableArray.new;
        _runningOperations = NSMutableArray.new;
    }
    return self;
}


- (NSString *)cacheKeyForURL:(NSURL *)url
{
    if (self.cacheKeyFilter)
    {
        return self.cacheKeyFilter(url);
    }
    else
    {
        return [url absoluteString];
    }
}

- (id<SDWebImageOperation>)downloadWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedWithFinishedBlock)completedBlock
{    
    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, XCode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    if ([url isKindOfClass:NSString.class])
    {
        url = [NSURL URLWithString:(NSString *)url];
    }

    __block SDWebImageCombinedOperation *operation = SDWebImageCombinedOperation.new;
    
    if (!url || !completedBlock || (!(options & SDWebImageRetryFailed) && [self.failedURLs containsObject:url]))
    {
        if (completedBlock) completedBlock(nil, nil, SDImageCacheTypeNone, NO);
        return operation;
    }

    [self.runningOperations addObject:operation];
    NSString *key = [self cacheKeyForURL:url];

    [self.imageCache queryDiskCacheForKey:key done:^(UIImage *image, SDImageCacheType cacheType)
    {
        if (operation.isCancelled) return;

        if (image)
        {
            completedBlock(image, nil, cacheType, YES);
            [self.runningOperations removeObject:operation];
        }
        else
        {
            SDWebImageDownloaderOptions downloaderOptions = 0;
            if (options & SDWebImageLowPriority) downloaderOptions |= SDWebImageDownloaderLowPriority;
            if (options & SDWebImageProgressiveDownload) downloaderOptions |= SDWebImageDownloaderProgressiveDownload;
            __block id<SDWebImageOperation> subOperation = [self.imageDownloader downloadImageWithURL:url options:downloaderOptions progress:progressBlock completed:^(UIImage *downloadedImage, NSData *data, NSError *error, BOOL finished)
            {
                completedBlock(downloadedImage, error, SDImageCacheTypeNone, finished);

                if (error)
                {
                    [self.failedURLs addObject:url];
                }
                else if (downloadedImage && finished)
                {
                    [self.imageCache storeImage:downloadedImage imageData:data forKey:key toDisk:YES];
                }

                if (finished)
                {
                    [self.runningOperations removeObject:operation];
                }
            }];
            operation.cancelBlock = ^{[subOperation cancel];};
        }
    }];

    return operation;
}

- (void)cancelAll
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.runningOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeAllObjects];
    });
}

@end

@implementation SDWebImageCombinedOperation

- (void)setCancelBlock:(void (^)())cancelBlock
{
    if (self.isCancelled)
    {
        if (cancelBlock) cancelBlock();
    }
    else
    {
        _cancelBlock = [cancelBlock copy];
    }
}

- (void)cancel
{
    self.cancelled = YES;
    if (self.cancelBlock)
    {
        self.cancelBlock();
        self.cancelBlock = nil;
    }
}

@end
