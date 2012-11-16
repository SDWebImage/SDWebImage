/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"
#import "SDWebImageDownloader.h"
#import "SDImageCache.h"

typedef enum
{
    /**
     * By default, when a URL fail to be downloaded, the URL is blacklisted so the library won't keep trying.
     * This flag disable this blacklisting.
     */
    SDWebImageRetryFailed = 1 << 0,
    /**
     * By default, image downloads are started during UI interactions, this flags disable this feature,
     * leading to delayed download on UIScrollView deceleration for instance.
     */
    SDWebImageLowPriority = 1 << 1,
    /**
     * This flag disables on-disk caching
     */
    SDWebImageCacheMemoryOnly = 1 << 2,
    /**
     * This flag enables progressive download, the image is displayed progressively during download as a browser would do.
     * By default, the image is only displayed once completely downloaded.
     */
    SDWebImageProgressiveDownload = 1 << 3
} SDWebImageOptions;

typedef void(^SDWebImageCompletedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType);
typedef void(^SDWebImageCompletedWithFinishedBlock)(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished);


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
 *                  progress:nil
 *                 completed:^(UIImage *image, NSError *error, BOOL fromCache)
 *                 {
 *                     if (image)
 *                     {
 *                         // do something with image
 *                     }
 *                 }];
 */
@interface SDWebImageManager : NSObject

@property (strong, nonatomic, readonly) SDImageCache *imageCache;
@property (strong, nonatomic, readonly) SDWebImageDownloader *imageDownloader;

/**
 * The cache filter is a block used each time SDWebImageManager need to convert an URL into a cache key. This can
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
@property (strong) NSString *(^cacheKeyFilter)(NSURL *url);

/**
 * Returns global SDWebImageManager instance.
 *
 * @return SDWebImageManager shared instance
 */
+ (SDWebImageManager *)sharedManager;

/**
 * Downloads the image at the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url The URL to the image
 * @param delegate The delegate object used to send result back
 * @param options A mask to specify options to use for this request
 * @param progressBlock A block called while image is downloading
 * @param completedBlock A block called when operation has been completed.
 *
 *                       This block as no return value and takes the requested UIImage as first parameter.
 *                       In case of error the image parameter is nil and the second parameter may contain an NSError.
 *
 *                       The third parameter is a Boolean indicating if the image was retrived from the local cache
 *                       of from the network.
 *
 *                       The last parameter is set to NO when the SDWebImageProgressiveDownload option is used and
 *                       the image is downloading. This block is thus called repetidly with a partial image. When
 *                       image is fully downloaded, the block is called a last time with the full image and the last
 *                       parameter set to YES.
 *
 * @return Returns a cancellable NSOperation
 */
- (id<SDWebImageOperation>)downloadWithURL:(NSURL *)url
                                   options:(SDWebImageOptions)options
                                  progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                 completed:(SDWebImageCompletedWithFinishedBlock)completedBlock;

/**
 * Cancel all current opreations
 */
- (void)cancelAll;

@end
