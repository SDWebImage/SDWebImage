/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"
#import "SDWebImageDownloaderOperation.h"
#import <ImageIO/ImageIO.h>

NSString *const SDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const SDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";

NSString *const kProgressCallbackKey = @"completed";
NSString *const kCompletedCallbackKey = @"completed";

@interface SDWebImageDownloader ()

@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;

@end

@implementation SDWebImageDownloader

+ (void)initialize
{
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator"))
    {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
#pragma clang diagnostic pop

        // Remove observer in case it was previously added.
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:activityIndicator name:SDWebImageDownloadStopNotification object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SDWebImageDownloadStopNotification object:nil];
    }
}

+ (SDWebImageDownloader *)sharedDownloader
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
        _downloadQueue = NSOperationQueue.new;
        _downloadQueue.maxConcurrentOperationCount = 10;
        _URLCallbacks = NSMutableDictionary.new;
    }
    return self;
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads
{
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSInteger)maxConcurrentDownloads
{
    return _downloadQueue.maxConcurrentOperationCount;
}

- (NSOperation *)downloadImageWithURL:(NSURL *)url options:(SDWebImageDownloaderOptions)options progress:(void (^)(NSUInteger, long long))progressBlock completed:(void (^)(UIImage *, NSError *, BOOL))completedBlock
{
    __block SDWebImageDownloaderOperation *operation;

    dispatch_async(dispatch_get_main_queue(), ^ // NSDictionary isn't thread safe
    {
        BOOL performDownload = NO;

        if (!self.URLCallbacks[url])
        {
            self.URLCallbacks[url] = NSMutableArray.new;
            performDownload = YES;
        }

        // Handle single download of simultaneous download request for the same URL
        {
            NSMutableArray *callbacksForURL = self.URLCallbacks[url];
            NSMutableDictionary *callbacks = NSMutableDictionary.new;
            if (progressBlock) callbacks[kProgressCallbackKey] = progressBlock;
            if (completedBlock) callbacks[kCompletedCallbackKey] = completedBlock;
            [callbacksForURL addObject:callbacks];
            self.URLCallbacks[url] = callbacksForURL;
        }

        if (performDownload)
        {
            // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests
            NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
            operation = [SDWebImageDownloaderOperation.alloc initWithRequest:request options:options progress:^(NSUInteger receivedSize, long long expectedSize)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    NSMutableArray *callbacksForURL = self.URLCallbacks[url];
                    for (NSDictionary *callbacks in callbacksForURL)
                    {
                        SDWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                        if (callback) callback(receivedSize, expectedSize);
                    }
                });
            }
            completed:^(UIImage *image, NSError *error, BOOL finished)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    NSMutableArray *callbacksForURL = self.URLCallbacks[url];
                    [self.URLCallbacks removeObjectForKey:url];
                    for (NSDictionary *callbacks in callbacksForURL)
                    {
                        SDWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                        if (callback) callback(image, error, finished);
                    }
                });
            }];
            [self.downloadQueue addOperation:operation];
        }
    });

    return operation;
}

@end
