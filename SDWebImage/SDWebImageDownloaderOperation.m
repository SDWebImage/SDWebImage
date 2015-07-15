/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderOperation.h"
#import "SDWebImageDecoder.h"
#import "UIImage+MultiFormat.h"
#import <ImageIO/ImageIO.h>
#import "SDWebImageManager.h"

NSString *const SDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const SDWebImageDownloadReceiveResponseNotification = @"SDWebImageDownloadReceiveResponseNotification";
NSString *const SDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";
NSString *const SDWebImageDownloadFinishNotification = @"SDWebImageDownloadFinishNotification";

@interface SDWebImageDownloaderOperation () <NSURLConnectionDataDelegate>

@property (copy, nonatomic) SDWebImageDownloaderProgressBlock progressBlock;
@property (copy, nonatomic) SDWebImageDownloaderCompletedBlock completedBlock;
@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;
@property (strong, nonatomic) NSMutableData *imageData;
@property (strong, nonatomic) NSThread *thread;
@property (strong, nonatomic) NSURLConnection *connection;

@end

// logs debug helper
//#define LOG_DOWNLOAD_OPERATIONS
#if defined(NDEBUG) || !defined(LOG_DOWNLOAD_OPERATIONS)

#define DebugLogEvent(str) do { } while (0)

#else

#define DebugLogEvent(str) do { [self debugLogEvent:str]; } while (0)

@implementation SDWebImageDownloaderOperation (Debugging)

- (void)debugLogEvent:(NSString *)event
// Called by the implementation to log events.
{
    assert(event != nil);
    
    // Synchronisation is necessary because multiple threads might be adding
    // events concurrently.
    @synchronized (self) {
        NSLog(@"%@: %@", self, event);
    }
}

@end

#endif // debugging helper


@implementation SDWebImageDownloaderOperation {
    size_t width, height;
    UIImageOrientation orientation;
    BOOL responseFromCached;
}

@synthesize executing = _executing;
@synthesize finished = _finished;

- (id)initWithRequest:(NSURLRequest *)request
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock {
    if ((self = [super init])) {
        assert(request != nil);
        assert(completedBlock != nil);
        _request = request;
        _shouldDecompressImages = YES;
        _shouldUseCredentialStorage = YES;
        _options = options;
        _progressBlock = [progressBlock copy];
        _completedBlock = [completedBlock copy];
        _executing = NO;
        _finished = NO;
        _expectedSize = 0;
        _imageData = nil;
        responseFromCached = YES; // Initially wrong until `connection:willCacheResponse:` is called or not called
        _connection = nil;
        _thread = nil;
        width = height = 0;
    }
    return self;
}

- (void)start {
   @autoreleasepool {
       DebugLogEvent(@"> start");
#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
       __block UIBackgroundTaskIdentifier backgroundTaskId = UIBackgroundTaskInvalid;
#endif
    
        // synchronize with cancel call
        @synchronized(self) {
            // do finish immediately if cancelled
            if (self.isCancelled) {
                DebugLogEvent(@" -start.cancelled");
                [self done];
                return;
            }

            // signal start of the execution
            self.executing = YES;
            self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
            self.thread = [NSThread currentThread];
            DebugLogEvent(@" -start.beforeConnectionStart");
        } // @synchronized end

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
        if ([self shouldContinueWhenAppEntersBackground]) {
            __weak __typeof__ (self) wself = self;
            backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                __strong __typeof (wself) sself = wself;
                if (sself) {
                    [sself cancel];
                    // [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId]; <-- called from operation's thread before 'start' will exit
                }
            }];
        }
#endif

        [self.connection start];
        DebugLogEvent(@" -start.afterConnectionStart");
        if (self.connection) {
            if (self.progressBlock) {
                self.progressBlock(0, NSURLResponseUnknownLength);
            }
            DebugLogEvent(@" -start.SDWebImageDownloadStartNotification");
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:self];
            });


            // Make sure to run the runloop in our background thread so it can process downloaded data
            // Note: we use a timeout to work around an issue with NSURLConnection cancel under iOS 5
            //       not waking up the runloop, leading to dead threads (see https://github.com/rs/SDWebImage/issues/466)
            SInt32 runLoopResult = CFRunLoopRunInMode(kCFRunLoopDefaultMode, self.request.timeoutInterval + 1 , false);

            DebugLogEvent(([NSString stringWithFormat:@" -start.afterCFRunLoopRunInMode (%d)", runLoopResult]));
//          Possible return values:
//            kCFRunLoopRunFinished = 1,
//            kCFRunLoopRunStopped = 2,
//            kCFRunLoopRunTimedOut = 3,
//            kCFRunLoopRunHandledSource = 4
            if (runLoopResult == kCFRunLoopRunTimedOut) {
                DebugLogEvent(@" -start.timedOut");
                [self.connection cancel];
                [self connection:self.connection didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:@{NSURLErrorFailingURLErrorKey : self.request.URL}]];
            }
            else if (self.isCancelled) {
                DebugLogEvent(@" -start.cancelled");
                [self connection:self.connection didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{NSURLErrorFailingURLErrorKey : self.request.URL}]];
            }
            // self.completedBlock has been already called with downloaded image or from didFailWithError
            assert(self.completedBlock == nil);
        }
        else {
            if (self.completedBlock) {
                self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Connection can't be initialized"}], YES);
                self.completedBlock = nil;
            }
        }

#if TARGET_OS_IPHONE && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
        if (backgroundTaskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
            backgroundTaskId = UIBackgroundTaskInvalid;
        }
#endif

       // synchronize with cancel call
       @synchronized(self) {
           DebugLogEvent(@" -start.done");
           [self done];
       } // @synchronized end

    }// @autoreleasepool
    DebugLogEvent(@"< start");
}

- (void)cancel {
    DebugLogEvent(@"> cancel");
    // synchronize with start
    @synchronized(self) {
        if (self.isCancelled || self.isFinished) {
            DebugLogEvent(@"< cancel.itsTooLate");
            return; // cancel only once
        }
        DebugLogEvent(@" -cancel.winner");
        if (self.thread) {
            [self performSelector:@selector(cancelInternalAndStop) onThread:self.thread withObject:nil waitUntilDone:NO];
        }
        else {
            [self cancelInternal];
        }
    }
    DebugLogEvent(@"< cancel");
}

- (void)cancelInternalAndStop {
    DebugLogEvent(@"> cancelInternalAndStop");
    // runs on operation's thread
    if ([self cancelInternal]) {
        DebugLogEvent(@" -cancelInternalAndStop.didCancel");
        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    DebugLogEvent(@"< cancelInternalAndStop");
}

- (BOOL)cancelInternal {
    DebugLogEvent(@"> cancelInternal");
    if (self.isFinished || self.isCancelled)
        return NO;// operation is finished, another regular op. may be already started on this thread(we are reusing threads), !!! DON'T call CFRunLoopStop !!!.
    DebugLogEvent(@" -cancelInternal.winner");
    // signal that it's cancelled
    [super cancel];
    // cancel the URL connection
    [self.connection cancel];
    // don't set self.finished = YES because, we haven't done yet
    DebugLogEvent(@"< cancelInternal");
    return YES;
}

- (void)done {
    DebugLogEvent(@"> done");
    // send download stop notification if download start notification was sent
    if (self.connection) {
        DebugLogEvent(@" -done.SDWebImageDownloadStopNotification");
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];
        });
    }
    
    self.finished = YES;
    self.executing = NO;
    [self reset];
    DebugLogEvent(@"< done");
}

- (void)reset {
    _completedBlock = nil;
    _progressBlock = nil;
    _connection = nil;
    _imageData = nil;
    _thread = nil;
}

- (void)setFinished:(BOOL)finished {
    if (_finished != finished) {
        DebugLogEvent(@"> setFinished");
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
        DebugLogEvent(@"< setFinished");
    }
}

- (void)setExecuting:(BOOL)executing {
    if (_executing != executing) {
        DebugLogEvent(@"> setExecuting");
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
        DebugLogEvent(@"< setExecuting");
    }
}

- (BOOL)isConcurrent {
    return YES;
}

#pragma mark NSURLConnection (delegate)

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    DebugLogEvent(@"> didReceiveResponse");
    // do finish immediately if operation has been cancelled (connection has been already cancelled too)
    if (self.isCancelled) {
        DebugLogEvent(@"< didReceiveResponse.cancelled");
        return;
    }

    //'304 Not Modified' is an exceptional one
    if (![response respondsToSelector:@selector(statusCode)] || ([((NSHTTPURLResponse *)response) statusCode] < 400 && [((NSHTTPURLResponse *)response) statusCode] != 304)) {
        NSInteger expected = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
        _expectedSize = expected;
        if (self.progressBlock) {
            self.progressBlock(0, expected);
        }
        self.imageData = [[NSMutableData alloc] initWithCapacity:expected];
        self.response = response;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadReceiveResponseNotification object:self];
            [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];
        });
    }
    else {
        NSUInteger code = [((NSHTTPURLResponse *)response) statusCode];

        //This is the case when server returns '304 Not Modified'. It means that remote image is not changed.
        //In case of 304 we need just cancel the operation and return cached image from the cache.
        if (code == 304) {
            DebugLogEvent(@" -didReceiveResponse.304");
            [self cancelInternal]; // [self cancel]; [self.connection cancel];
        } else {
            DebugLogEvent(@" -didReceiveResponse.error");
            [self.connection cancel];
            if (self.completedBlock) {
                self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:[((NSHTTPURLResponse *)response) statusCode] userInfo:nil], YES);
                self.completedBlock = nil;
            }
        }

        CFRunLoopStop(CFRunLoopGetCurrent());
    }
    DebugLogEvent(@"< didReceiveResponse");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // do finish immediately if operation has been cancelled (connection has been already cancelled too)
    if (self.isCancelled) {
        DebugLogEvent(@"< didReceiveData.cancelled");
        return;
    }

    [self.imageData appendData:data];

    if ((self.options & SDWebImageDownloaderProgressiveDownload) && _expectedSize > 0 && self.completedBlock) {
        // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
        // Thanks to the author @Nyx0uf

        // Get the total bytes downloaded
        const NSInteger totalSize = self.imageData.length;

        // Update the data source, we must pass ALL the data, not just the new bytes
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)self.imageData, NULL);

        if (width + height == 0) {
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            if (properties) {
                NSInteger orientationValue = -1;
                CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &height);
                val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
                if (val) CFNumberGetValue(val, kCFNumberLongType, &width);
                val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
                if (val) CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
                CFRelease(properties);

                // When we draw to Core Graphics, we lose orientation information,
                // which means the image below born of initWithCGIImage will be
                // oriented incorrectly sometimes. (Unlike the image born of initWithData
                // in connectionDidFinishLoading.) So save it here and pass it on later.
                orientation = [[self class] orientationFromPropertyValue:(orientationValue == -1 ? 1 : orientationValue)];
            }

        }

        if (width + height > 0 && totalSize < _expectedSize) {
            // Create the image
            CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);

#ifdef TARGET_OS_IPHONE
            // Workaround for iOS anamorphic image
            if (partialImageRef) {
                const size_t partialHeight = CGImageGetHeight(partialImageRef);
                CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
                CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
                CGColorSpaceRelease(colorSpace);
                if (bmContext) {
                    CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
                    CGImageRelease(partialImageRef);
                    partialImageRef = CGBitmapContextCreateImage(bmContext);
                    CGContextRelease(bmContext);
                }
                else {
                    CGImageRelease(partialImageRef);
                    partialImageRef = nil;
                }
            }
#endif

            if (partialImageRef) {
                @autoreleasepool {
                    __block UIImage *image = [UIImage imageWithCGImage:partialImageRef scale:1 orientation:orientation];
                    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
                    UIImage *scaledImage = SDScaledImageForKey(key, image);
                    if (self.shouldDecompressImages) {
                        image = [UIImage decodedImageWithImage:scaledImage];
                    }
                    else {
                        image = scaledImage;
                    }
                    CGImageRelease(partialImageRef);
                    __weak __typeof(self) weakSelf = self;
                    dispatch_sync(dispatch_get_main_queue(),^{
                        __strong __typeof(self) strongSelf = weakSelf;
                        if (strongSelf.completedBlock) {
                            strongSelf.completedBlock(image, nil, nil, NO);
                        }
                    });
                }
            }
        }

        CFRelease(imageSource);
    }

    if (self.progressBlock) {
        self.progressBlock(self.imageData.length, _expectedSize);
    }
}

+ (UIImageOrientation)orientationFromPropertyValue:(NSInteger)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {
    DebugLogEvent(@"> connectionDidFinishLoading");
    // do finish immediately if operation has been cancelled (connection has been already cancelled too)
    if (self.isCancelled) {
        DebugLogEvent(@"< connectionDidFinishLoading.cancelled");
        return;
    }
    
    // operation is almost done(we don't need to handle cancel anymore)
    SDWebImageDownloaderCompletedBlock completionBlock = self.completedBlock;
    self.completedBlock = nil;// to prevent to be called later again. For example: cancel called after this point, before we exit from run loop(from 'start' method).
    
    if (![[NSURLCache sharedURLCache] cachedResponseForRequest:self.request]) {
        responseFromCached = NO;
    }

    if (completionBlock) {
        if (self.options & SDWebImageDownloaderIgnoreCachedResponse && responseFromCached) {
            completionBlock(nil, nil, nil, YES);
        }
        else if (self.imageData) {
            @autoreleasepool {
                UIImage *image = [UIImage sd_imageWithData:self.imageData];
                NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:self.request.URL];
                image = SDScaledImageForKey(key, image);

                // Do not force decoding animated GIFs
                if (!image.images) {
                    if (self.shouldDecompressImages) {
                        image = [UIImage decodedImageWithImage:image];
                    }
                }
                if (CGSizeEqualToSize(image.size, CGSizeZero)) {
                    completionBlock(nil, nil, [NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Downloaded image has 0 pixels"}], YES);
                }
                else {
                    completionBlock(image, self.imageData, nil, YES);
                }
            }
        } else {
            completionBlock(nil, nil, [NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Image data is nil"}], YES);
        }
    }

    CFRunLoopStop(CFRunLoopGetCurrent());
    DebugLogEvent(@"< connectionDidFinishLoading");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    DebugLogEvent(@"> didFailWithError");
    // we do not neet to hold lock here, because this method can be called only from operation's thread
    if (self.completedBlock) {
        DebugLogEvent(@" -didFailWithError.completedBlock");
        self.completedBlock(nil, nil, error, YES);
        self.completedBlock = nil;// to prevent to be called later again. For example: cancel called after error, before we exit from run loop(from 'start' method).
    }
    else {
        DebugLogEvent(@" -didFailWithError.noCompletedBlock");
    }

    CFRunLoopStop(CFRunLoopGetCurrent());
    DebugLogEvent(@"< didFailWithError");
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    responseFromCached = NO; // If this method is called, it means the response wasn't read from cache
    if (self.request.cachePolicy == NSURLRequestReloadIgnoringLocalCacheData) {
        // Prevents caching of responses
        return nil;
    }
    else {
        return cachedResponse;
    }
}

- (BOOL)shouldContinueWhenAppEntersBackground {
    return self.options & SDWebImageDownloaderContinueInBackground;
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection __unused *)connection {
    return self.shouldUseCredentialStorage;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if (!(self.options & SDWebImageDownloaderAllowInvalidSSLCertificates) &&
            [challenge.sender respondsToSelector:@selector(performDefaultHandlingForAuthenticationChallenge:)]) {
            [challenge.sender performDefaultHandlingForAuthenticationChallenge:challenge];
        } else {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
        }
    } else {
        if ([challenge previousFailureCount] == 0) {
            if (self.credential) {
                [[challenge sender] useCredential:self.credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
            }
        } else {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        }
    }
}

@end
