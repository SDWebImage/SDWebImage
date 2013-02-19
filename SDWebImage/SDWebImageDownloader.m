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

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";

@interface SDWebImageDownloader ()

@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (weak, nonatomic) NSOperation *lastAddedOperation;
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;
@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;
// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t workingQueue;
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t barrierQueue;

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
        _queueMode = SDWebImageDownloaderFILOQueueMode;
        _downloadQueue = NSOperationQueue.new;
        _downloadQueue.maxConcurrentOperationCount = 2;
        _URLCallbacks = NSMutableDictionary.new;
        _HTTPHeaders = [NSMutableDictionary dictionaryWithObject:@"image/*" forKey:@"Accept"];
        _workingQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloader", DISPATCH_QUEUE_SERIAL);
        _barrierQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)dealloc
{
    [self.downloadQueue cancelAllOperations];
    SDDispatchQueueRelease(_workingQueue);
    SDDispatchQueueRelease(_barrierQueue);
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
    if (value)
    {
        self.HTTPHeaders[field] = value;
    }
    else
    {
        [self.HTTPHeaders removeObjectForKey:field];
    }
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field
{
    return self.HTTPHeaders[field];
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads
{
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSInteger)maxConcurrentDownloads
{
    return _downloadQueue.maxConcurrentOperationCount;
}

- (id<SDWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(SDWebImageDownloaderOptions)options progress:(void (^)(NSUInteger, long long))progressBlock completed:(void (^)(UIImage *, NSData *, NSError *, BOOL))completedBlock
{
    __block SDWebImageDownloaderOperation *operation;
    __weak SDWebImageDownloader *wself = self;

    [self addProgressCallback:progressBlock andCompletedBlock:completedBlock forURL:url createCallback:^
    {
        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests
        NSMutableURLRequest *request = [NSMutableURLRequest.alloc initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPShouldUsePipelining = YES;
        request.allHTTPHeaderFields = wself.HTTPHeaders;
        operation = [SDWebImageDownloaderOperation.alloc initWithRequest:request queue:wself.workingQueue options:options progress:^(NSUInteger receivedSize, long long expectedSize)
        {
            if (!wself) return;
            SDWebImageDownloader *sself = wself;
            NSArray *callbacksForURL = [sself callbacksForURL:url];
            for (NSDictionary *callbacks in callbacksForURL)
            {
                SDWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                if (callback) callback(receivedSize, expectedSize);
            }
        }
        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
        {
            if (!wself) return;
            SDWebImageDownloader *sself = wself;
            NSArray *callbacksForURL = [sself callbacksForURL:url];
            if (finished)
            {
                [sself removeCallbacksForURL:url];
            }
            for (NSDictionary *callbacks in callbacksForURL)
            {
                SDWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                if (callback) callback(image, data, error, finished);
            }
        }
        cancelled:^
        {
            if (!wself) return;
            SDWebImageDownloader *sself = wself;
            [sself callbacksForURL:url];
            [sself removeCallbacksForURL:url];
        }];
        [wself.downloadQueue addOperation:operation];
        if (wself.queueMode == SDWebImageDownloaderLIFOQueueMode)
        {
            // Emulate LIFO queue mode by systematically adding new operations as last operation's dependency
            [wself.lastAddedOperation addDependency:operation];
            wself.lastAddedOperation = operation;
        }
    }];

    return operation;
}

- (void)addProgressCallback:(void (^)(NSUInteger, long long))progressBlock andCompletedBlock:(void (^)(UIImage *, NSData *data, NSError *, BOOL))completedBlock forURL:(NSURL *)url createCallback:(void (^)())createCallback
{
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if(url == nil)
    {
        if (completedBlock != nil)
        {
            completedBlock(nil, nil, nil, NO);
        }
        return;
    }
    
    dispatch_barrier_sync(self.barrierQueue, ^
    {
        BOOL first = NO;
        if (!self.URLCallbacks[url])
        {
            self.URLCallbacks[url] = NSMutableArray.new;
            first = YES;
        }

        // Handle single download of simultaneous download request for the same URL
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        NSMutableDictionary *callbacks = NSMutableDictionary.new;
        if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
        [callbacksForURL addObject:callbacks];
        self.URLCallbacks[url] = callbacksForURL;

        if (first)
        {
            createCallback();
        }
    });
}

- (NSArray *)callbacksForURL:(NSURL *)url
{
    __block NSArray *callbacksForURL;
    dispatch_sync(self.barrierQueue, ^
    {
        callbacksForURL = self.URLCallbacks[url];
    });
    return callbacksForURL;
}

- (void)removeCallbacksForURL:(NSURL *)url
{
    dispatch_barrier_async(self.barrierQueue, ^
    {
        [self.URLCallbacks removeObjectForKey:url];
    });
}

@end
