/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageOperation.h"

typedef enum
{
    SDWebImageDownloaderLowPriority = 1 << 0,
    SDWebImageDownloaderProgressiveDownload = 1 << 1
} SDWebImageDownloaderOptions;

extern NSString *const SDWebImageDownloadStartNotification;
extern NSString *const SDWebImageDownloadStopNotification;

typedef void(^SDWebImageDownloaderProgressBlock)(NSUInteger receivedSize, long long expectedSize);
typedef void(^SDWebImageDownloaderCompletedBlock)(UIImage *image, NSData *data, NSError *error, BOOL finished);

/**
 * Asynchronous downloader dedicated and optimized for image loading.
 */
@interface SDWebImageDownloader : NSObject

@property (assign, nonatomic) NSInteger maxConcurrentDownloads;

+ (SDWebImageDownloader *)sharedDownloader;

/**
 * Creates a SDWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 * @see SDWebImageDownloaderDelegate
 *
 * @param url The URL to the image to download
 * @param options The options to be used for this download
 * @param progress A block called repeatedly while the image is downloading
 * @param completed A block called once the download is completed.
 *                  If the download succeeded, the image parameter is set, in case of error,
 *                  error parameter is set with the error. The last parameter is always YES
 *                  if SDWebImageDownloaderProgressiveDownload isn't use. With the
 *                  SDWebImageDownloaderProgressiveDownload option, this block is called
 *                  repeatedly with the partial image object and the finished argument set to NO
 *                  before to be called a last time with the full image and finished argument
 *                  set to YES. In case of error, the finished argument is always YES.
 *
 * @return A cancellable SDWebImageOperation
 */
- (id<SDWebImageOperation>)downloadImageWithURL:(NSURL *)url
                                        options:(SDWebImageDownloaderOptions)options
                                       progress:(SDWebImageDownloaderProgressBlock)progressBlock
                                      completed:(SDWebImageDownloaderCompletedBlock)completedBlock;

@end
