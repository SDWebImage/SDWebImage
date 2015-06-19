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
#import <KVOController/FBKVOController.h>

static NSString *const kProgressCallbackKey = @"progress";
static NSString *const kCompletedCallbackKey = @"completed";
static NSString *const kOptionsCallbackKey = @"options";

@interface SDWebImageDownloader ()

@property (strong, nonatomic) NSOperationQueue *downloadQueue;
@property (strong, nonatomic) NSOperationQueue *downloadQueueExtraHighPriority;
@property (weak, nonatomic) NSOperation *lastAddedOperation;
@property (assign, nonatomic) Class operationClass;
@property (strong, nonatomic) NSMutableDictionary *URLCallbacks;
@property (strong, nonatomic) NSMutableDictionary *HTTPHeaders;
@property (strong, nonatomic) FBKVOController *kvoController;

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
        _shouldDecompressImages = YES;
        _executionOrder = SDWebImageDownloaderFIFOExecutionOrder;
        _downloadQueue = [NSOperationQueue new];
        _downloadQueueExtraHighPriority = [NSOperationQueue new];
        _URLCallbacks = [NSMutableDictionary new];
        _HTTPHeaders = [NSMutableDictionary dictionaryWithObject:@"image/webp,image/*;q=0.8" forKey:@"Accept"];
        _barrierQueue = dispatch_queue_create("com.hackemist.SDWebImageDownloaderBarrierQueue", DISPATCH_QUEUE_CONCURRENT);
        _downloadTimeout = 15.0;
        [self setMaxConcurrentDownloads:6];
        self.kvoController = [FBKVOController controllerWithObserver:self];
        [self observeOperationCount];
    }
    return self;
}

- (void) observeOperationCount {
    [self.kvoController observe:_downloadQueueExtraHighPriority keyPath:@"operationCount" options:NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        if([change[NSKeyValueChangeNewKey] isKindOfClass:[NSNumber class]]) {
            NSInteger newValue = [change[NSKeyValueChangeNewKey] integerValue];
            NSInteger isSuspended = _downloadQueue.isSuspended;
            
            if (newValue == 0 && isSuspended) {
                [_downloadQueue setSuspended:NO];
            } else if (newValue != 0 && !isSuspended) {
                [_downloadQueue setSuspended:YES];
            }
        }
    }];
}
- (void)dealloc {
    [self.downloadQueue cancelAllOperations];
    [self.downloadQueueExtraHighPriority cancelAllOperations];
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
    _downloadQueueExtraHighPriority.maxConcurrentOperationCount = maxConcurrentDownloads;
}

- (NSUInteger)currentDownloadCount {
    return _downloadQueue.operationCount + _downloadQueueExtraHighPriority.operationCount;
}

- (NSInteger)maxConcurrentDownloads {
    return _downloadQueue.maxConcurrentOperationCount;
}

- (void)setOperationClass:(Class)operationClass {
    _operationClass = operationClass ?: [SDWebImageDownloaderOperation class];
}

- (NSOperationQueue *) operationQueueForOptions: (SDWebImageDownloaderOptions) options {
    if(options & SDWebImageDownloaderExtraHighPriority) {
        return _downloadQueueExtraHighPriority;
    } else {
        return _downloadQueue;
    }
}

- (id <SDWebImageOperation>)downloadImageWithURL:(NSURL *)url options:(SDWebImageDownloaderOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageDownloaderCompletedBlock)completedBlock {
    __block SDWebImageDownloaderOperation *operation;
    __weak __typeof(self)wself = self;

    
    [self addProgressCallback:progressBlock options:options andCompletedBlock:completedBlock forURL:url createCallback:^{
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
        operation = [[wself.operationClass alloc] initWithRequest:request
                                                          options:options
                                                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                                             SDWebImageDownloader *sself = wself;
                                                             if (!sself) return;
                                                             __block NSArray *callbacksForURL;
                                                             dispatch_sync(sself.barrierQueue, ^{
                                                                 callbacksForURL = [sself.URLCallbacks[url] copy];
                                                             });
                                                             for (NSDictionary *callbacks in callbacksForURL) {
                                                                 SDWebImageDownloaderProgressBlock callback = callbacks[kProgressCallbackKey];
                                                                 if (callback) callback(receivedSize, expectedSize);
                                                             }
                                                         }
                                                        completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                            SDWebImageDownloader *sself = wself;
                                                            if (!sself) return;
                                                            __block NSArray *callbacksForURL;
                                                            dispatch_barrier_sync(sself.barrierQueue, ^{
                                                                callbacksForURL = [sself.URLCallbacks[url] copy];
                                                                
                                                                
                                                                if ([callbacksForURL count] > 1) {
                                                                    
                                                                    __block BOOL found = NO;
                                                                    
                                                                    __block NSUInteger indexToRemove = 0;
                                                                    
                                                                    //Try to find the first URL with extra high option
                                                                    [callbacksForURL enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                                                                        
                                                                        SDWebImageDownloaderOptions currentOptions = [obj[kOptionsCallbackKey] integerValue];
                                                                        
                                                                        if(currentOptions & SDWebImageDownloaderExtraHighPriority) {
                                                                            callbacksForURL = [NSArray arrayWithObject:obj];
                                                                            
                                                                            //We found an object with high prio. Just use this!
                                                                            *stop = YES;
                                                                            found = YES;
                                                                            indexToRemove = idx;
                                                                        }
                                                                    }];
                                                                    
                                                                    if(!found) {
                                                                        //just use the first object
                                                                        callbacksForURL = [NSArray arrayWithObject:[callbacksForURL firstObject]];
                                                                    }
                                                                    
                                                                    if(finished) {
                                                                        //Now we have to remove this object
                                                                        NSMutableArray *newCallbacksForURLToSave = [NSMutableArray arrayWithArray:[sself.URLCallbacks[url] copy]];
                                                                        
                                                                        [newCallbacksForURLToSave removeObjectAtIndex:indexToRemove];
                                                                        
                                                                        [sself.URLCallbacks setObject:newCallbacksForURLToSave forKey:url];
                                                                    }
                                                                } else {
                                                                    if (finished) {
                                                                        [sself.URLCallbacks removeObjectForKey:url];
                                                                    }
                                                                }
                                                            });
                                                            
                                                            
                                                            
                                                            for (NSDictionary *callbacks in callbacksForURL) {
                                                                SDWebImageDownloaderCompletedBlock callback = callbacks[kCompletedCallbackKey];
                                                                if (callback) callback(image, data, error, finished);
                                                            }
                                                        }
                                                        cancelled:^{
                                                            SDWebImageDownloader *sself = wself;
                                                            if (!sself) return;
                                                            dispatch_barrier_async(sself.barrierQueue, ^{
                                                                __block NSArray *callbacksForURL = [sself.URLCallbacks[url] copy];
                                                                
                                                                
                                                                if ([callbacksForURL count] > 1) {
                                                                    
                                                                    __block BOOL found = NO;
                                                                    
                                                                    __block NSUInteger indexToRemove = 0;
                                                                    
                                                                    //Try to find the first URL with extra high option
                                                                    [callbacksForURL enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                                                                        
                                                                        SDWebImageDownloaderOptions currentOptions = [obj[kOptionsCallbackKey] integerValue];
                                                                        
                                                                        if(currentOptions & SDWebImageDownloaderExtraHighPriority) {
                                                                            callbacksForURL = [NSArray arrayWithObject:obj];
                                                                            
                                                                            //We found an object with high prio. Just use this!
                                                                            *stop = YES;
                                                                            found = YES;
                                                                            indexToRemove = idx;
                                                                        }
                                                                    }];
                                                                    
                                                                    if(!found) {
                                                                        //just use the first object
                                                                        callbacksForURL = [NSArray arrayWithObject:[callbacksForURL firstObject]];
                                                                    }
                                                                    
                                                                    //Now we have to remove this object
                                                                    NSMutableArray *newCallbacksForURLToSave = [NSMutableArray arrayWithArray:[sself.URLCallbacks[url] copy]];
                                                                        
                                                                    [newCallbacksForURLToSave removeObjectAtIndex:indexToRemove];
                                                                        
                                                                    [sself.URLCallbacks setObject:newCallbacksForURLToSave forKey:url];
                                                                    
                                                                } else {
                                                                    [sself.URLCallbacks removeObjectForKey:url];
                                                                }
                                                            });
                                                        }];
        operation.shouldDecompressImages = wself.shouldDecompressImages;
        
        if (wself.username && wself.password) {
            operation.credential = [NSURLCredential credentialWithUser:wself.username password:wself.password persistence:NSURLCredentialPersistenceForSession];
        }
        
        if (options & SDWebImageDownloaderHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityHigh;
        } else if (options & SDWebImageDownloaderLowPriority) {
            operation.queuePriority = NSOperationQueuePriorityLow;
        } else if (options & SDWebImageDownloaderExtraHighPriority) {
            operation.queuePriority = NSOperationQueuePriorityVeryHigh;
        }
        
        [[self operationQueueForOptions:options] addOperation:operation];
    }];
    
    return operation;
}


- (void)addProgressCallback:(SDWebImageDownloaderProgressBlock)progressBlock options:(SDWebImageDownloaderOptions)options andCompletedBlock:(SDWebImageDownloaderCompletedBlock)completedBlock forURL:(NSURL *)url createCallback:(SDWebImageNoParamsBlock)createCallback {
    // The URL will be used as the key to the callbacks dictionary so it cannot be nil. If it is nil immediately call the completed block with no image or data.
    if (url == nil) {
        if (completedBlock != nil) {
            completedBlock(nil, nil, nil, NO);
        }
        return;
    }
    
    dispatch_barrier_sync(self.barrierQueue, ^{
        BOOL first = NO;
        if (!self.URLCallbacks[url]) {
            self.URLCallbacks[url] = [NSMutableArray new];
            first = YES;
        }
        
        // Handle single download of simultaneous download request for the same URL
        NSMutableArray *callbacksForURL = self.URLCallbacks[url];
        NSMutableDictionary *callbacks = [NSMutableDictionary new];
        if (progressBlock) callbacks[kProgressCallbackKey] = [progressBlock copy];
        if (completedBlock) callbacks[kCompletedCallbackKey] = [completedBlock copy];
        callbacks[kOptionsCallbackKey] = [NSNumber numberWithInteger:options];
        [callbacksForURL addObject:callbacks];
        
        self.URLCallbacks[url] = callbacksForURL;
        
        createCallback();
    });
}

- (void)setSuspended:(BOOL)suspended {
    [_downloadQueue setSuspended:suspended];
    [_downloadQueueExtraHighPriority setSuspended:suspended];
}


@end
