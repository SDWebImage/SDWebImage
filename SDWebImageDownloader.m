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
- (CGImageRef)createTransitoryImage:(CGImageRef)partialImg;
@end

@implementation SDWebImageDownloader
@synthesize url, delegate, connection, imageData, userInfo, lowPriority;

#pragma mark Public Methods

- (id)init
{
    self = [super init];
    if (self) {
        imageSource = CGImageSourceCreateIncremental(NULL);
        if (imageSource == NULL) {
            [NSException raise:NSMallocException format:@"CGImageSourceCreateIncremental failed in SDWebImageDownloader"];
            [self release];
        }
        
    }
    return self;
}

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
                                                 selector:@selector(startActivity)
                                                     name:SDWebImageDownloadStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:activityIndicator
                                                 selector:@selector(stopActivity)
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
//        self.imageData = [NSMutableData data];
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
int statusCode = [((NSHTTPURLResponse *)response) statusCode];
    if (statusCode >= 400)
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
    } else if (statusCode >= 200 && statusCode < 300) {
		expectedSize = (NSUInteger)[response expectedContentLength];
		imageData = [[NSMutableData alloc] initWithCapacity:(expectedSize != NSUIntegerMax) ? expectedSize : 0];
	}	

}

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)data
{
    [imageData appendData:data];
    
    
    //
    // The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
    // Thanks to the author @Nyx0uf !
    //

	/// Get the total bytes downloaded
	const NSUInteger totalSize = [imageData length];
	/// Update the data source, we must pass ALL the data, not just the new bytes
	CGImageSourceUpdateData(imageSource, (CFDataRef)imageData, totalSize == expectedSize);
    
	/// We know the expected size of the image
	if (fullHeight > 0 && fullWidth > 0)
	{
		/// Create the image
		CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
		if (image && [delegate respondsToSelector:@selector(imageDownloader:didUpdatePartialImage:)])
		{
#ifdef __IPHONE_4_0 // iOS
			CGImageRef imgTmp = [self createTransitoryImage:image];
			if (imgTmp)
			{
//				[_delegate downloadedImageUpdated:imgTmp];
                // Call delegate
                UIImage *uiImage = [[UIImage alloc] initWithCGImage:imgTmp];
                [delegate imageDownloader:self didUpdatePartialImage:uiImage];
				CGImageRelease(imgTmp);
                [uiImage release];
			}
#else // Mac OS
//            NSImage *uiImage = [[UIImage alloc] initWithCGImage:image];
//
//			[_delegate downloadedImageUpdated:uiImage];
//            [uiImage release];
#endif
			CGImageRelease(image);
		}
	}
	else
	{
		CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
		if (properties)
		{
			CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
			if (val)
				CFNumberGetValue(val, kCFNumberLongType, &fullHeight);
			val = CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
			if (val)
				CFNumberGetValue(val, kCFNumberLongType, &fullWidth);
			CFRelease(properties);
		}
	}

    //
    // End of @Nyx0uf's code
    //
}

//
// The following code is from http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
// Thanks to the author @Nyx0uf !
//

-(CGImageRef)createTransitoryImage:(CGImageRef)partialImg
{
	const size_t height = CGImageGetHeight(partialImg);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL, fullWidth, fullHeight, 8, fullWidth * 4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpace);
	if (!bmContext)
	{
		NSLog(@"fail creating context");
		return NULL;
	}
	CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = fullWidth, .size.height = height}, partialImg);
	CGImageRef goodImageRef = CGBitmapContextCreateImage(bmContext);
	CGContextRelease(bmContext);
	return goodImageRef;
}
//
// End of @Nyx0uf's code
//



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
    CFRelease(imageSource);

    SDWISafeRelease(url);
    SDWISafeRelease(connection);
    SDWISafeRelease(imageData);
    SDWISafeRelease(userInfo);
    SDWISuperDealoc;
}


@end
