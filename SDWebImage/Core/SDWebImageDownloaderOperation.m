/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderOperation.h"
#import "SDWebImageError.h"
#import "SDInternalMacros.h"
#import "SDWebImageDownloaderResponseModifier.h"
#import "SDWebImageDownloaderDecryptor.h"
#import "SDImageCacheDefine.h"
#import "SDCallbackQueue.h"

BOOL SDWebImageDownloaderOperationGetCompleted(id<SDWebImageDownloaderOperation> operation); // Private currently, mark open if needed

// A handler to represent individual request
@interface SDWebImageDownloaderOperationToken : NSObject

@property (nonatomic, copy, nullable) SDWebImageDownloaderCompletedBlock completedBlock;
@property (nonatomic, copy, nullable) SDWebImageDownloaderProgressBlock progressBlock;
@property (nonatomic, copy, nullable) SDImageCoderOptions *decodeOptions;

@end

@implementation SDWebImageDownloaderOperationToken

- (BOOL)isEqual:(id)other {
    if (nil == other) {
      return NO;
    }
    if (self == other) {
      return YES;
    }
    if (![other isKindOfClass:[self class]]) {
      return NO;
    }
    SDWebImageDownloaderOperationToken *object = (SDWebImageDownloaderOperationToken *)other;
    // warn: only compare decodeOptions, ignore pointer, use `removeObjectIdenticalTo`
    BOOL result = [self.decodeOptions isEqualToDictionary:object.decodeOptions];
    return result;
}

@end

@interface SDWebImageDownloaderOperation ()

@property (strong, nonatomic, nonnull) NSMutableArray<SDWebImageDownloaderOperationToken *> *callbackTokens;

@property (assign, nonatomic, readwrite) SDWebImageDownloaderOptions options;
@property (copy, nonatomic, readwrite, nullable) SDWebImageContext *context;

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (strong, nonatomic, nullable) NSMutableData *imageData;
@property (copy, nonatomic, nullable) NSData *cachedData; // for `SDWebImageDownloaderIgnoreCachedResponse`
@property (assign, nonatomic) NSUInteger expectedSize; // may be 0
@property (assign, nonatomic) NSUInteger receivedSize;
@property (strong, nonatomic, nullable, readwrite) NSURLResponse *response;
@property (strong, nonatomic, nullable) NSError *responseError;
@property (assign, nonatomic) double previousProgress; // previous progress percent

@property (strong, nonatomic, nullable) id<SDWebImageDownloaderResponseModifier> responseModifier; // modify original URLResponse
@property (strong, nonatomic, nullable) id<SDWebImageDownloaderDecryptor> decryptor; // decrypt image data

// This is weak because it is injected by whoever manages this session. If this gets nil-ed out, we won't be able to run
// the task associated with this operation
@property (weak, nonatomic, nullable) NSURLSession *unownedSession;
// This is set if we're using not using an injected NSURLSession. We're responsible of invalidating this one
@property (strong, nonatomic, nullable) NSURLSession *ownedSession;

@property (strong, nonatomic, readwrite, nullable) NSURLSessionTask *dataTask;

@property (strong, nonatomic, readwrite, nullable) NSURLSessionTaskMetrics *metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

@property (strong, nonatomic, nonnull) NSOperationQueue *coderQueue; // the serial operation queue to do image decoding

@property (strong, nonatomic, nonnull) NSMapTable<SDImageCoderOptions *, UIImage *> *imageMap; // each variant of image is weak-referenced to avoid too many re-decode during downloading
#if SD_UIKIT
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
#endif

@end

@implementation SDWebImageDownloaderOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (nonnull instancetype)init {
    return [self initWithRequest:nil inSession:nil options:0];
}

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(SDWebImageDownloaderOptions)options {
    return [self initWithRequest:request inSession:session options:options context:nil];
}

- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                                options:(SDWebImageDownloaderOptions)options
                                context:(nullable SDWebImageContext *)context {
    if ((self = [super init])) {
        _request = [request copy];
        _options = options;
        _context = [context copy];
        _callbackTokens = [NSMutableArray new];
        _responseModifier = context[SDWebImageContextDownloadResponseModifier];
        _decryptor = context[SDWebImageContextDownloadDecryptor];
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        _unownedSession = session;
        _coderQueue = [[NSOperationQueue alloc] init];
        _coderQueue.maxConcurrentOperationCount = 1;
        _coderQueue.name = @"com.hackemist.SDWebImageDownloaderOperation.coderQueue";
        _imageMap = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:1];
#if SD_UIKIT
        _backgroundTaskId = UIBackgroundTaskInvalid;
#endif
    }
    return self;
}

- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock {
    return [self addHandlersForProgress:progressBlock completed:completedBlock decodeOptions:nil];
}

- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock
                        decodeOptions:(nullable SDImageCoderOptions *)decodeOptions {
    if (!completedBlock && !progressBlock && !decodeOptions) return nil;
    SDWebImageDownloaderOperationToken *token = [SDWebImageDownloaderOperationToken new];
    token.completedBlock = completedBlock;
    token.progressBlock = progressBlock;
    token.decodeOptions = decodeOptions;
    @synchronized (self) {
        [self.callbackTokens addObject:token];
    }
    
    return token;
}

- (BOOL)cancel:(nullable id)token {
    if (![token isKindOfClass:SDWebImageDownloaderOperationToken.class]) return NO;
    
    BOOL shouldCancel = NO;
    @synchronized (self) {
        NSArray *tokens = self.callbackTokens;
        if (tokens.count == 1 && [tokens indexOfObjectIdenticalTo:token] != NSNotFound) {
            shouldCancel = YES;
        }
    }
    if (shouldCancel) {
        // Cancel operation running and callback last token's completion block
        [self cancel];
    } else {
        // Only callback this token's completion block
        @synchronized (self) {
            [self.callbackTokens removeObjectIdenticalTo:token];
        }
        [self callCompletionBlockWithToken:token image:nil imageData:nil error:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Operation cancelled by user during sending the request"}] finished:YES];
    }
    return shouldCancel;
}

- (void)start {
    @synchronized (self) {
        if (self.isCancelled) {
            if (!self.isFinished) self.finished = YES;
            // Operation cancelled by user before sending the request
            [self callCompletionBlocksWithError:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Operation cancelled by user before sending the request"}]];
            [self reset];
            return;
        }

#if SD_UIKIT
        Class UIApplicationClass = NSClassFromString(@"UIApplication");
        BOOL hasApplication = UIApplicationClass && [UIApplicationClass respondsToSelector:@selector(sharedApplication)];
        if (hasApplication && [self shouldContinueWhenAppEntersBackground]) {
            __weak typeof(self) wself = self;
            UIApplication * app = [UIApplicationClass performSelector:@selector(sharedApplication)];
            self.backgroundTaskId = [app beginBackgroundTaskWithExpirationHandler:^{
                [wself cancel];
            }];
        }
#endif
        NSURLSession *session = self.unownedSession;
        if (!session) {
            NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            sessionConfig.timeoutIntervalForRequest = 15;
            
            /**
             *  Create the session for this task
             *  We send nil as delegate queue so that the session creates a serial operation queue for performing all delegate
             *  method calls and completion handler calls.
             */
            session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                    delegate:self
                                               delegateQueue:nil];
            self.ownedSession = session;
        }
        
        if (self.options & SDWebImageDownloaderIgnoreCachedResponse) {
            // Grab the cached data for later check
            NSURLCache *URLCache = session.configuration.URLCache;
            if (!URLCache) {
                URLCache = [NSURLCache sharedURLCache];
            }
            NSCachedURLResponse *cachedResponse;
            // NSURLCache's `cachedResponseForRequest:` is not thread-safe, see https://developer.apple.com/documentation/foundation/nsurlcache#2317483
            @synchronized (URLCache) {
                cachedResponse = [URLCache cachedResponseForRequest:self.request];
            }
            if (cachedResponse) {
                self.cachedData = cachedResponse.data;
                self.response = cachedResponse.response;
            }
        }
        
        if (!session.delegate) {
            // Session been invalid and has no delegate at all
            [self callCompletionBlocksWithError:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorInvalidDownloadOperation userInfo:@{NSLocalizedDescriptionKey : @"Session delegate is nil and invalid"}]];
            [self reset];
            return;
        }
        
        self.dataTask = [session dataTaskWithRequest:self.request];
        self.executing = YES;
    }

    if (self.dataTask) {
        if (self.options & SDWebImageDownloaderHighPriority) {
            self.dataTask.priority = NSURLSessionTaskPriorityHigh;
        } else if (self.options & SDWebImageDownloaderLowPriority) {
            self.dataTask.priority = NSURLSessionTaskPriorityLow;
        } else {
            self.dataTask.priority = NSURLSessionTaskPriorityDefault;
        }
        [self.dataTask resume];
        NSArray<SDWebImageDownloaderOperationToken *> *tokens;
        @synchronized (self) {
            tokens = [self.callbackTokens copy];
        }
        for (SDWebImageDownloaderOperationToken *token in tokens) {
            if (token.progressBlock) {
                token.progressBlock(0, NSURLResponseUnknownLength, self.request.URL);
            }
        }
        __block typeof(self) strongSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:strongSelf];
        });
    } else {
        if (!self.isFinished) self.finished = YES;
        [self callCompletionBlocksWithError:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorInvalidDownloadOperation userInfo:@{NSLocalizedDescriptionKey : @"Task can't be initialized"}]];
        [self reset];
    }
}

- (void)cancel {
    @synchronized (self) {
        [self cancelInternal];
    }
}

- (void)cancelInternal {
    if (self.isFinished) return;
    [super cancel];
    
    __block typeof(self) strongSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:strongSelf];
    });

    if (self.dataTask) {
        // Cancel the URLSession, `URLSession:task:didCompleteWithError:` delegate callback will be ignored
        [self.dataTask cancel];
        self.dataTask = nil;
    }
    
    // NSOperation disallow setFinished=YES **before** operation's start method been called
    // We check for the initialized status, which is isExecuting == NO && isFinished = NO
    // Ony update for non-intialized status, which is !(isExecuting == NO && isFinished = NO), or if (self.isExecuting || self.isFinished) {...}
    if (self.isExecuting || self.isFinished) {
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    // Operation cancelled by user during sending the request
    [self callCompletionBlocksWithError:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorCancelled userInfo:@{NSLocalizedDescriptionKey : @"Operation cancelled by user during sending the request"}]];

    [self reset];
}

- (void)done {
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset {
    @synchronized (self) {
        [self.callbackTokens removeAllObjects];
        self.dataTask = nil;
        
        if (self.ownedSession) {
            [self.ownedSession invalidateAndCancel];
            self.ownedSession = nil;
        }
        
#if SD_UIKIT
        if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
            // If backgroundTaskId != UIBackgroundTaskInvalid, sharedApplication is always exist
            UIApplication * app = [UIApplication performSelector:@selector(sharedApplication)];
            [app endBackgroundTask:self.backgroundTaskId];
            self.backgroundTaskId = UIBackgroundTaskInvalid;
        }
#endif
    }
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isAsynchronous {
    return YES;
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    
    // Check response modifier, if return nil, will marked as cancelled.
    BOOL valid = YES;
    if (self.responseModifier && response) {
        response = [self.responseModifier modifiedResponseWithResponse:response];
        if (!response) {
            valid = NO;
            self.responseError = [NSError errorWithDomain:SDWebImageErrorDomain
                                                     code:SDWebImageErrorInvalidDownloadResponse
                                                 userInfo:@{NSLocalizedDescriptionKey : @"Download marked as failed because response is nil"}];
        }
    }
    
    NSInteger expected = (NSInteger)response.expectedContentLength;
    expected = expected > 0 ? expected : 0;
    self.expectedSize = expected;
    self.response = response;
    
    // Check status code valid (defaults [200,400))
    NSInteger statusCode = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)response).statusCode : 0;
    BOOL statusCodeValid = YES;
    if (valid && statusCode > 0 && self.acceptableStatusCodes) {
        statusCodeValid = [self.acceptableStatusCodes containsIndex:statusCode];
    }
    if (!statusCodeValid) {
        valid = NO;
        self.responseError = [NSError errorWithDomain:SDWebImageErrorDomain
                                                 code:SDWebImageErrorInvalidDownloadStatusCode
                                             userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Download marked as failed because of invalid response status code %ld", (long)statusCode],
                                                        SDWebImageErrorDownloadStatusCodeKey : @(statusCode),
                                                        SDWebImageErrorDownloadResponseKey : response}];
    }
    // Check content type valid (defaults nil)
    NSString *contentType = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)response).MIMEType : nil;
    BOOL contentTypeValid = YES;
    if (valid && contentType.length > 0 && self.acceptableContentTypes) {
        contentTypeValid = [self.acceptableContentTypes containsObject:contentType];
    }
    if (!contentTypeValid) {
        valid = NO;
        self.responseError = [NSError errorWithDomain:SDWebImageErrorDomain
                                                 code:SDWebImageErrorInvalidDownloadContentType
                                             userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Download marked as failed because of invalid response content type %@", contentType],
                                                        SDWebImageErrorDownloadContentTypeKey : contentType,
                                                        SDWebImageErrorDownloadResponseKey : response}];
    }
    //'304 Not Modified' is an exceptional one
    //URLSession current behavior will return 200 status code when the server respond 304 and URLCache hit. But this is not a standard behavior and we just add a check
    if (valid && statusCode == 304 && !self.cachedData) {
        valid = NO;
        self.responseError = [NSError errorWithDomain:SDWebImageErrorDomain
                                                 code:SDWebImageErrorCacheNotModified
                                             userInfo:@{NSLocalizedDescriptionKey: @"Download response status code is 304 not modified and ignored",
                                                        SDWebImageErrorDownloadResponseKey : response}];
    }
    
    if (valid) {
        NSArray<SDWebImageDownloaderOperationToken *> *tokens;
        @synchronized (self) {
            tokens = [self.callbackTokens copy];
        }
        for (SDWebImageDownloaderOperationToken *token in tokens) {
            if (token.progressBlock) {
                token.progressBlock(0, expected, self.request.URL);
            }
        }
    } else {
        // Status code invalid and marked as cancelled. Do not call `[self.dataTask cancel]` which may mass up URLSession life cycle
        disposition = NSURLSessionResponseCancel;
    }
    __block typeof(self) strongSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadReceiveResponseNotification object:strongSelf];
    });
    
    if (completionHandler) {
        completionHandler(disposition);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (!self.imageData) {
        self.imageData = [[NSMutableData alloc] initWithCapacity:self.expectedSize];
    }
    [self.imageData appendData:data];
    
    self.receivedSize = self.imageData.length;
    NSArray<SDWebImageDownloaderOperationToken *> *tokens;
    @synchronized (self) {
        tokens = [self.callbackTokens copy];
    }
    if (self.expectedSize == 0) {
        // Unknown expectedSize, immediately call progressBlock and return
        for (SDWebImageDownloaderOperationToken *token in tokens) {
            if (token.progressBlock) {
                token.progressBlock(self.receivedSize, self.expectedSize, self.request.URL);
            }
        }
        return;
    }
    
    // Get the finish status
    BOOL finished = (self.receivedSize >= self.expectedSize);
    // Get the current progress
    double currentProgress = (double)self.receivedSize / (double)self.expectedSize;
    double previousProgress = self.previousProgress;
    double progressInterval = currentProgress - previousProgress;
    // Check if we need callback progress
    if (!finished && (progressInterval < self.minimumProgressInterval)) {
        return;
    }
    self.previousProgress = currentProgress;
    
    // Using data decryptor will disable the progressive decoding, since there are no support for progressive decrypt
    BOOL supportProgressive = (self.options & SDWebImageDownloaderProgressiveLoad) && !self.decryptor;
    // When multiple thumbnail decoding use different size, this progressive decoding will cause issue because each callback assume called with different size's image, can not share the same decoding part
    // We currently only pick the first thumbnail size, see #3423 talks
    // Progressive decoding Only decode partial image, full image in `URLSession:task:didCompleteWithError:`
    if (supportProgressive && !finished) {
        // Get the image data
        NSData *imageData = self.imageData;
        
        // keep maximum one progressive decode process during download
        if (self.coderQueue.operationCount == 0) {
            // NSOperation have autoreleasepool, don't need to create extra one
            @weakify(self);
            [self.coderQueue addOperationWithBlock:^{
                @strongify(self);
                if (!self) {
                    return;
                }
                // When cancelled or transfer finished (`didCompleteWithError`), cancel the progress callback, only completed block is called and enough
                @synchronized (self) {
                    if (self.isCancelled || SDWebImageDownloaderOperationGetCompleted(self)) {
                        return;
                    }
                }
                UIImage *image = SDImageLoaderDecodeProgressiveImageData(imageData, self.request.URL, NO, self, [[self class] imageOptionsFromDownloaderOptions:self.options], self.context);
                if (image) {
                    // We do not keep the progressive decoding image even when `finished`=YES. Because they are for view rendering but not take full function from downloader options. And some coders implementation may not keep consistent between progressive decoding and normal decoding.
                    
                    [self callCompletionBlocksWithImage:image imageData:nil error:nil finished:NO];
                }
            }];
        }
    }
    
    for (SDWebImageDownloaderOperationToken *token in tokens) {
        if (token.progressBlock) {
            token.progressBlock(self.receivedSize, self.expectedSize, self.request.URL);
        }
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler {
    
    NSCachedURLResponse *cachedResponse = proposedResponse;

    if (!(self.options & SDWebImageDownloaderUseNSURLCache)) {
        // Prevents caching of responses
        cachedResponse = nil;
    }
    if (completionHandler) {
        completionHandler(cachedResponse);
    }
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    // If we already cancel the operation or anything mark the operation finished, don't callback twice
    if (self.isFinished) return;
    
    NSArray<SDWebImageDownloaderOperationToken *> *tokens;
    @synchronized (self) {
        tokens = [self.callbackTokens copy];
        self.dataTask = nil;
        __block typeof(self) strongSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:strongSelf];
            if (!error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadFinishNotification object:strongSelf];
            }
        });
    }
    
    // make sure to call `[self done]` to mark operation as finished
    if (error) {
        // custom error instead of URLSession error
        if (self.responseError) {
            error = self.responseError;
        }
        [self callCompletionBlocksWithError:error];
        [self done];
    } else {
        if (tokens.count > 0) {
            NSData *imageData = self.imageData;
            self.imageData = nil;
            // data decryptor
            if (imageData && self.decryptor) {
                imageData = [self.decryptor decryptedDataWithData:imageData response:self.response];
            }
            if (imageData) {
                /**  if you specified to only use cached data via `SDWebImageDownloaderIgnoreCachedResponse`,
                 *  then we should check if the cached data is equal to image data
                 */
                if (self.options & SDWebImageDownloaderIgnoreCachedResponse && [self.cachedData isEqualToData:imageData]) {
                    self.responseError = [NSError errorWithDomain:SDWebImageErrorDomain
                                                             code:SDWebImageErrorCacheNotModified
                                                         userInfo:@{NSLocalizedDescriptionKey : @"Downloaded image is not modified and ignored",
                                                                    SDWebImageErrorDownloadResponseKey : self.response}];
                    // call completion block with not modified error
                    [self callCompletionBlocksWithError:self.responseError];
                    [self done];
                } else {
                    // decode the image in coder queue, cancel all previous decoding process
                    [self.coderQueue cancelAllOperations];
                    @weakify(self);
                    for (SDWebImageDownloaderOperationToken *token in tokens) {
                        [self.coderQueue addOperationWithBlock:^{
                            @strongify(self);
                            if (!self) {
                                return;
                            }
                            UIImage *image;
                            // check if we already decode this variant of image for current callback
                            if (token.decodeOptions) {
                                image = [self.imageMap objectForKey:token.decodeOptions];
                            }
                            if (!image) {
                                // check if we already use progressive decoding, use that to produce faster decoding
                                id<SDProgressiveImageCoder> progressiveCoder = SDImageLoaderGetProgressiveCoder(self);
                                SDWebImageOptions options = [[self class] imageOptionsFromDownloaderOptions:self.options];
                                SDWebImageContext *context;
                                if (token.decodeOptions) {
                                    SDWebImageMutableContext *mutableContext = [NSMutableDictionary dictionaryWithDictionary:self.context];
                                    SDSetDecodeOptionsToContext(mutableContext, &options, token.decodeOptions);
                                    context = [mutableContext copy];
                                } else {
                                    context = self.context;
                                }
                                if (progressiveCoder) {
                                    image = SDImageLoaderDecodeProgressiveImageData(imageData, self.request.URL, YES, self, options, context);
                                } else {
                                    image = SDImageLoaderDecodeImageData(imageData, self.request.URL, options, context);
                                }
                                if (image && token.decodeOptions) {
                                    [self.imageMap setObject:image forKey:token.decodeOptions];
                                }
                            }
                            CGSize imageSize = image.size;
                            if (imageSize.width == 0 || imageSize.height == 0) {
                                NSString *description = image == nil ? @"Downloaded image decode failed" : @"Downloaded image has 0 pixels";
                                NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorBadImageData userInfo:@{NSLocalizedDescriptionKey : description}];
                                [self callCompletionBlockWithToken:token image:nil imageData:nil error:error finished:YES];
                            } else {
                                [self callCompletionBlockWithToken:token image:image imageData:imageData error:nil finished:YES];
                            }
                        }];
                    }
                    // call [self done] after all completed block was dispatched
                    dispatch_block_t doneBlock = ^{
                        @strongify(self);
                        if (!self) {
                            return;
                        }
                        [self done];
                    };
                    if (@available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)) {
                        // seems faster than `addOperationWithBlock`
                        [self.coderQueue addBarrierBlock:doneBlock];
                    } else {
                        // serial queue, this does the same effect in semantics
                        [self.coderQueue addOperationWithBlock:doneBlock];
                    }
                }
            } else {
                [self callCompletionBlocksWithError:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorBadImageData userInfo:@{NSLocalizedDescriptionKey : @"Image data is nil"}]];
                [self done];
            }
        } else {
            [self done];
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (!(self.options & SDWebImageDownloaderAllowInvalidSSLCertificates)) {
            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
        } else {
            credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            disposition = NSURLSessionAuthChallengeUseCredential;
        }
    } else {
        if (challenge.previousFailureCount == 0) {
            if (self.credential) {
                credential = self.credential;
                disposition = NSURLSessionAuthChallengeUseCredential;
            } else {
                // Web Server like Nginx can set `ssl_verify_client` to optional but not always on
                // We'd better use default handling here
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    
    if (completionHandler) {
        completionHandler(disposition, credential);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0)) {
    self.metrics = metrics;
}

#pragma mark Helper methods
+ (SDWebImageOptions)imageOptionsFromDownloaderOptions:(SDWebImageDownloaderOptions)downloadOptions {
    SDWebImageOptions options = 0;
    if (downloadOptions & SDWebImageDownloaderScaleDownLargeImages) options |= SDWebImageScaleDownLargeImages;
    if (downloadOptions & SDWebImageDownloaderDecodeFirstFrameOnly) options |= SDWebImageDecodeFirstFrameOnly;
    if (downloadOptions & SDWebImageDownloaderPreloadAllFrames) options |= SDWebImagePreloadAllFrames;
    if (downloadOptions & SDWebImageDownloaderAvoidDecodeImage) options |= SDWebImageAvoidDecodeImage;
    if (downloadOptions & SDWebImageDownloaderMatchAnimatedImageClass) options |= SDWebImageMatchAnimatedImageClass;
    
    return options;
}

- (BOOL)shouldContinueWhenAppEntersBackground {
    return SD_OPTIONS_CONTAINS(self.options, SDWebImageDownloaderContinueInBackground);
}

- (void)callCompletionBlocksWithError:(nullable NSError *)error {
    [self callCompletionBlocksWithImage:nil imageData:nil error:error finished:YES];
}

- (void)callCompletionBlocksWithImage:(nullable UIImage *)image
                            imageData:(nullable NSData *)imageData
                                error:(nullable NSError *)error
                             finished:(BOOL)finished {
    NSArray<SDWebImageDownloaderOperationToken *> *tokens;
    @synchronized (self) {
        tokens = [self.callbackTokens copy];
    }
    for (SDWebImageDownloaderOperationToken *token in tokens) {
        SDWebImageDownloaderCompletedBlock completedBlock = token.completedBlock;
        if (completedBlock) {
            SDCallbackQueue *queue = self.context[SDWebImageContextCallbackQueue];
            [(queue ?: SDCallbackQueue.mainQueue) async:^{
                completedBlock(image, imageData, error, finished);
            }];
        }
    }
}

- (void)callCompletionBlockWithToken:(nonnull SDWebImageDownloaderOperationToken *)token
                               image:(nullable UIImage *)image
                           imageData:(nullable NSData *)imageData
                               error:(nullable NSError *)error
                            finished:(BOOL)finished {
    SDWebImageDownloaderCompletedBlock completedBlock = token.completedBlock;
    if (completedBlock) {
        SDCallbackQueue *queue = self.context[SDWebImageContextCallbackQueue];
        [(queue ?: SDCallbackQueue.mainQueue) async:^{
            completedBlock(image, imageData, error, finished);
        }];
    }
}

@end
