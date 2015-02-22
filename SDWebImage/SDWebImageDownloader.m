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

static NSString *const kDownloadObserversKey = @"downloadObservers";
static NSString *const kDownloadOperationKey = @"downloadOperation";

@interface SDWebImageDownloader ()

@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (weak, nonatomic) NSOperation *lastAddedOperation;
@property (assign, nonatomic) Class operationClass;
@property (strong, nonatomic) NSMutableDictionary *URLOperations;
@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;
// This queue is used to serialize the handling of the network responses of all the download operation in a single queue
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t barrierQueue;

@end

@implementation SDWebImageDownloader

+ (void)initialize {
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator")) {

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

+ (SDWebImageDownloader *)sharedDownloader {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (id)init {
    if ((self = [super init])) {
        _operationClass = [SDWebImageDownloaderOperation class];
        _executionOrder = SDWebImageDownloaderFIFOExecutionOrder;
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _URLOperations = [NSMutableDictionary new];
        _HTTPHeaders = [NSMutableDictionary dictionaryWithObject:@"image/webp,image/*;q=0.8" forKey:@"Accept"];
        _barrierQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;
    }
    return self;
}

- (void)dealloc {
    [self.downloadQueue cancelAllOperations];
    SDDispatchQueueRelease(_barrierQueue);
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if (value) {
        self.HTTPHeaders[field] = value;
    }
    else {
        [self.HTTPHeaders removeObjectForKey:field];
    }
}

- (NSString *)valueForHTTPHeaderField:(NSString *)field {
    return self.HTTPHeaders[field];
}

- (void)setMaxConcurrentDownloads:(NSInteger)maxConcurrentDownloads {
    _downloadQueue.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSUInteger)currentDownloadCount {
    return _downloadQueue.operationCount;
}

- (NSInteger)maxConcurrentDownloads {
    return _downloadQueue.maxConcurrentOperationCount;
}

- (void)setOperationClass:(Class)operationClass {
    _operationClass = operationClass ?: [SDWebImageDownloaderOperation class];
}

- (void)downloadImageWithURL:(NSURL *)url options:(SDWebImageDownloaderOptions)options observer:(id<SDWebImageDownloaderObserver>)observer {
    __weak SDWebImageDownloader *wself = self;

    [self addObserver:observer forURL:url createCallback:^(){
        NSTimeInterval timeoutInterval = wself.downloadTimeout;
        if (timeoutInterval == 0.0) {
            timeoutInterval = 15.0;
        }

        // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests if told otherwise
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:(options & SDWebImageDownloaderUseNSURLCache ? NSURLRequestUseProtocolCachePolicy : NSURLRequestReloadIgnoringLocalCacheData) timeoutInterval:timeoutInterval];
        request.HTTPShouldHandleCookies = (options & SDWebImageDownloaderHandleCookies);
        request.HTTPShouldUsePipelining = YES;
        if (wself.headersFilter) {
            request.allHTTPHeaderFields = wself.headersFilter(url, [wself.HTTPHeaders copy]);
        }
        else {
            request.allHTTPHeaderFields = wself.HTTPHeaders;
        }
        wself.URLOperations[url][kDownloadOperationKey] = [[wself.operationClass alloc]
            initWithRequest:request
            options:options
            progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                SDWebImageDownloader *sself = wself;
                if (!sself) return;
                NSDictionary *operationForURL = [sself copyOperationForURL:url removeItFromOperations:NO];// makes a copy using a barrier
                NSHashTable *observersForURL = operationForURL[kDownloadObserversKey];
                for (id<SDWebImageDownloaderObserver> observer in observersForURL) {
                    if ([observer respondsToSelector:@selector(progress:receivedSize:expectedSize:)]) {
                        [observer progress:sself.URLOperations[url][kDownloadOperationKey] receivedSize:receivedSize expectedSize:expectedSize];
                    }
                }
            }
            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                SDWebImageDownloader *sself = wself;
                if (!sself) return;
                NSDictionary *operationForURL = [sself copyOperationForURL:url removeItFromOperations:finished];// makes a copy using a barrier and remove if needed
                NSHashTable *observersForURL = operationForURL[kDownloadObserversKey];
                SDWebImageDownloaderOperation *operation = operationForURL[kDownloadOperationKey];
                for (id<SDWebImageDownloaderObserver> observer in observersForURL) {
                    if ([observer respondsToSelector:@selector(completed:image:data:error:finished:)]) {
                        [observer completed:operation image:image data:data error:error finished:finished];
                    }
                }
            }];
        
        SDWebImageDownloaderOperation* operation = wself.URLOperations[url][kDownloadOperationKey];
        
        if (wself.username && wself.password) {
            operation.credential = [NSURLCredential credentialWithUser:wself.username password:wself.password persistence:NSURLCredentialPersistenceForSession];
        }
        
        if (options & SDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        } else if (options & SDWebImageDownloaderLowPriority) {
            operation.queuePriority = NSOperationQueuePriorityLow;
        }

        if (wself.executionOrder == SDWebImageDownloaderLIFOExecutionOrder) { // this is not very good idea, lastAddedOperation may be finished!
            // Emulate LIFO execution order by systematically adding new operations as last operation's dependency
            [wself.lastAddedOperation addDependency:operation];
            wself.lastAddedOperation = operation;
        }
        
        [wself.downloadQueue addOperation:operation];
    }];

    return;
}

- (void)addObserver:(id<SDWebImageDownloaderObserver>)observer forURL:(NSURL *)url createCallback:(SDWebImageNoParamsBlock)createCallback {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if (url == nil || observer == nil) {
        if ([observer respondsToSelector:@selector(completed:image:data:error:finished:)]) {
            [observer completed:nil image:nil data:nil error:nil finished:NO];
        }
        return;
    }

    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL created = NO;
        if (!self.URLOperations[url]) {
            self.URLOperations[url] = [NSMutableDictionary new];
            created = YES;
        }

        // Handle single download of simultaneous download request for the same URL
        NSMutableDictionary *operationForURL = self.URLOperations[url];
        operationForURL[kDownloadObserversKey] = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory capacity:1];
        
        if (created) {
            //operationForURL[kDownloadOperationKey] = nil; // not known yet
            createCallback();
        }
        
    });
}

- (void)cancelDownloadImageWithURL:(NSURL *)url forObserver:(id<SDWebImageDownloaderObserver>)observer
{
    dispatch_barrier_async(self.barrierQueue, ^{
        NSDictionary *operationForURL = self.URLOperations[url];
        if ([operationForURL[kDownloadObserversKey] count] == 1 && [operationForURL[kDownloadObserversKey] containsObject:observer]) {
            // no more observers, cancel download operation
            __block SDWebImageDownloaderOperation* op = operationForURL[kDownloadOperationKey];
            // remove from operations
            [self.URLOperations removeObjectForKey:url];
            // cancel it
            [op cancel];
            // notify observer
            dispatch_main_async_safe(^{
                if ([observer respondsToSelector:@selector(completed:image:data:error:finished:)]) {
                    [observer completed:op image:nil data:nil error:[NSError errorWithDomain:@"" code:NSURLErrorCancelled userInfo:nil] finished:YES];
                }
            });
        }
        else {
            [operationForURL[kDownloadObserversKey] removeObject:observer];
        }
    });
}

- (NSDictionary *)copyOperationForURL:(NSURL *)url removeItFromOperations:(BOOL)remove {
    __block NSDictionary *operationForURL = nil;
    dispatch_sync(self.barrierQueue, ^{
        operationForURL = [self.URLOperations[url] copy];
        if (remove) {
            [self.URLOperations removeObjectForKey:url];
        }
    });
    return operationForURL;
}

- (void)setSuspended:(BOOL)suspended {
    [self.downloadQueue setSuspended:suspended];
}

@end
