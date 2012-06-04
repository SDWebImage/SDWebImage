/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageDownloaderDelegate.h"
#import "SDWebImageManagerDelegate.h"
#import "SDImageCacheDelegate.h"

typedef enum
{
    SDWebImageRetryFailed = 1 << 0,
    SDWebImageLowPriority = 1 << 1,
    SDWebImageCacheMemoryOnly = 1 << 2,
    SDWebImageProgressiveDownload = 1 << 3
} SDWebImageOptions;

/**
 * The SDWebImageManager is the class behind the UIImageView+WebCache category and likes.
 * It ties the asynchronous downloader (SDWebImageDownloader) with the image cache store (SDImageCache).
 * You can use this class directly to benefit from web image downloading with caching in another context than
 * a UIView.
 *
 * Here is a simple example of how to use SDWebImageManager:
 *
 *  SDWebImageManager *manager = [SDWebImageManager sharedManager];
 *  [manager downloadWithURL:imageURL
 *                  delegate:self
 *                   options:0
 *                   success:^(UIImage *image)
 *                   {
 *                       // do something with image
 *                   }
 *                   failure:nil];
 */
@interface SDWebImageManager : NSObject <SDWebImageDownloaderDelegate, SDImageCacheDelegate>
{
    NSMutableArray *downloadInfo;
    NSMutableArray *downloadDelegates;
    NSMutableArray *downloaders;
    NSMutableArray *cacheDelegates;
    NSMutableArray *cacheURLs;
    NSMutableDictionary *downloaderForURL;
    NSMutableArray *failedURLs;
}

#if NS_BLOCKS_AVAILABLE
typedef NSString *(^CacheKeyFilter)(NSURL *url);

/**
 * The cache filter is a block used each time SDWebManager need to convert an URL into a cache key. This can
 * be used to remove dynamic part of an image URL.
 *
 * The following example sets a filter in the application delegate that will remove any query-string from the
 * URL before to use it as a cache key:
 *
 * 	[[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL *url)
 *	{
 *	    url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
 *	    return [url absoluteString];
 *	}];
 */
@property (strong) CacheKeyFilter cacheKeyFilter;
#endif


/**
 * Returns global SDWebImageManager instance.
 *
 * @return SDWebImageManager shared instance
 */
+ (id)sharedManager;

- (UIImage *)imageWithURL:(NSURL *)url __attribute__ ((deprecated));

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @see [SDWebImageManager downloadWithURL:delegate:options:userInfo:]
 * @see [SDWebImageManager downloadWithURL:delegate:options:userInfo:success:failure:]
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate;

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @param options A mask to specify options to use for this request
 * @see [SDWebImageManager downloadWithURL:delegate:options:userInfo:]
 * @see [SDWebImageManager downloadWithURL:delegate:options:userInfo:success:failure:]
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate options:(SDWebImageOptions)options;

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @param options A mask to specify options to use for this request
 * @param info An NSDictionnary passed back to delegate if provided
 * @see [SDWebImageManager downloadWithURL:delegate:options:success:failure:]
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate options:(SDWebImageOptions)options userInfo:(NSDictionary *)info;

// use options:SDWebImageRetryFailed instead
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed __attribute__ ((deprecated));
// use options:SDWebImageRetryFailed|SDWebImageLowPriority instead
- (void)downloadWithURL:(NSURL *)url delegate:(id<SDWebImageManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority __attribute__ ((deprecated));

#if NS_BLOCKS_AVAILABLE
/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @param options A mask to specify options to use for this request
 * @param success A block called when image has been retrived successfuly
 * @param failure A block called when couldn't be retrived for some reason
 * @see [SDWebImageManager downloadWithURL:delegate:options:]
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id)delegate options:(SDWebImageOptions)options success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @param options A mask to specify options to use for this request
 * @param info An NSDictionnary passed back to delegate if provided
 * @param success A block called when image has been retrived successfuly
 * @param failure A block called when couldn't be retrived for some reason
 * @see [SDWebImageManager downloadWithURL:delegate:options:]
 */
- (void)downloadWithURL:(NSURL *)url delegate:(id)delegate options:(SDWebImageOptions)options userInfo:(NSDictionary *)info success:(void (^)(UIImage *image))success failure:(void (^)(NSError *error))failure;
#endif

/**
 * Cancel all pending download requests for a given delegate
 *
 * @param delegate The delegate to cancel requests for
 */
- (void)cancelForDelegate:(id<SDWebImageManagerDelegate>)delegate;

@end
