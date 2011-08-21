/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"

NSString *const SDWebImageDownloadStartNotification = @"SDWebImageDownloadStartNotification";
NSString *const SDWebImageDownloadStopNotification = @"SDWebImageDownloadStopNotification";

@interface SDWebImageDownloader ()
@property (nonatomic, retain) NSURLConnection *connection;
@end

@implementation SDWebImageDownloader
@synthesize url, delegate, connection, imageData, userInfo, lowPriority;

#pragma mark Public Methods

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate
{
    return [self downloaderWithURL:url delegate:delegate userInfo:nil];
}

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate userInfo:(id)userInfo
{

    return [self downloaderWithURL:url delegate:delegate userInfo:userInfo lowPriority:NO];
}

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate userInfo:(id)userInfo lowPriority:(BOOL)lowPriority
{
    // Bind SDNetworkActivityIndicator if available (download it here: http://github.com/rs/SDNetworkActivityIndicator )
    // To use it, just add #import "SDNetworkActivityIndicator.h" in addition to the SDWebImage import
    if (NSClassFromString(@"SDNetworkActivityIndicator"))
    {
        id activityIndicator = [NSClassFromString(@"SDNetworkActivityIndicator") performSelector:NSSelectorFromString(@"sharedActivityIndicator")];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"startActivity")
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:NSSelectorFromString(@"stopActivity")
                                                     name:SDWebImageDownloadStopNotification object:nil];
    }

    SDWebImageDownloader *downloader = [[[SDWebImageDownloader alloc] init] autorelease];
    downloader.url = url;
    downloader.delegate = delegate;
    downloader.userInfo = userInfo;
    downloader.lowPriority = lowPriority;
    [downloader performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    return downloader;
}

+ (void)setMaxConcurrentDownloads:(NSUInteger)max
{
    // NOOP
}

- (void)start
{
    // In order to prevent from potential duplicate caching (NSURLCache + SDImageCache) we disable the cache for image requests
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];

    // If not in low priority mode, ensure we aren't blocked by UI manipulations (default runloop mode for NSURLConnection is NSEventTrackingRunLoopMode)
    if (!lowPriority)
    {
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    [connection start];
    [request release];

    if (connection)
    {
        self.imageData = [NSMutableData data];
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:nil];
    }
    else
    {
        if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
        {
            [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:nil];
        }
    }
}

- (void)cancel
{
    if (connection)
    {
        [connection cancel];
        self.connection = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];
    }
}

#pragma mark NSURLConnection (delegate)

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
}

// NS_BLOCKS_AVAILBLE checks __IPHONE_OS_VERSION_MAX_ALLOWED, so blocks are 
// reported as available even if you set a 3.x version of the SDK as the 
// "iOS Deployment Target". However attempting to use blocks at runtime on 3.x
// crashes. We could do a runtime check for block availability, but that 
// requires you to weak-link libSystem which is tedious for a library like
// SDWebImage. Instead, we only enable blocks-based background image decoding
// if you set the deployment target (__IPHONE_OS_VERSION_MIN_REQUIRED) to at 
// least 4.0.
// For Mac OS X though, stick with the same logic as NS_BLOCKS_AVAILABLE.
#if NS_BLOCKS_AVAILABLE && (MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED || __IPHONE_4_0 <= __IPHONE_OS_VERSION_MIN_REQUIRED)
    #define BLOCKS_SUPPORTED 1
#else
    #define BLOCKS_SUPPORTED 0
#endif

#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    self.connection = nil;

    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    if ([delegate respondsToSelector:@selector(imageDownloaderDidFinish:)])
    {
        [delegate performSelector:@selector(imageDownloaderDidFinish:) withObject:self];
    }

    if ([delegate respondsToSelector:@selector(imageDownloader:didFinishWithImage:)])
    {
#if BLOCKS_SUPPORTED
        if ([[[NSRunLoop currentRunLoop] currentMode] isEqualToString:UITrackingRunLoopMode]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {
                UIImage *image = [[UIImage alloc] initWithData:imageData];
                dispatch_sync(dispatch_get_main_queue(), ^(void) {
                    [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
                });
                [image release];
            });
        } else {
#endif
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
            [image release];
#if BLOCKS_SUPPORTED
        }
#endif
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

    if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
    {
        [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:error];
    }

    self.connection = nil;
    self.imageData = nil;
}

#pragma mark NSObject

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [url release], url = nil;
    [connection release], connection = nil;
    [imageData release], imageData = nil;
    [userInfo release], userInfo = nil;
    [super dealloc];
}


@end
