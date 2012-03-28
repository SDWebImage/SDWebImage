/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloader.h"

#import "SDWebImageDecoder.h"
@interface SDWebImageDownloader (ImageDecoder) <SDWebImageDecoderDelegate>
@end

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

    SDWebImageDownloader *downloader = SDWIReturnAutoreleased([[SDWebImageDownloader alloc] init]);
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
    self.connection = SDWIReturnAutoreleased([[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO]);

    // If not in low priority mode, ensure we aren't blocked by UI manipulations (default runloop mode for NSURLConnection is NSEventTrackingRunLoopMode)
    if (!lowPriority)
    {
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    [connection start];
    SDWIRelease(request);

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

- (void)connection:(NSURLConnection *)aConnection didReceiveResponse:(NSURLResponse *)response
{
    if ([((NSHTTPURLResponse *)response) statusCode] >= 400)
    {
        [aConnection cancel];

        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];

        if ([delegate respondsToSelector:@selector(imageDownloader:didFailWithError:)])
        {
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain
                                                        code:[((NSHTTPURLResponse *)response) statusCode]
                                                    userInfo:nil];
            [delegate performSelector:@selector(imageDownloader:didFailWithError:) withObject:self withObject:error];
            SDWIRelease(error);
        }

        self.connection = nil;
        self.imageData = nil;
    }
}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
}

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
        UIImage *image = SDScaledImageForPath(url.absoluteString, imageData);
        [[SDWebImageDecoder sharedImageDecoder] decodeImage:image withDelegate:self userInfo:nil];
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

#pragma mark SDWebImageDecoderDelegate

- (void)imageDecoder:(SDWebImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(NSDictionary *)userInfo
{
    [delegate performSelector:@selector(imageDownloader:didFinishWithImage:) withObject:self withObject:image];
}

#pragma mark NSObject

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SDWISafeRelease(url);
    SDWISafeRelease(connection);
    SDWISafeRelease(imageData);
    SDWISafeRelease(userInfo);
    SDWISuperDealoc;
}


@end
