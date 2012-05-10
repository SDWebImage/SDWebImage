/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageDownloaderDelegate.h"
#import "SDWebImageCompat.h"

extern NSString *const SDWebImageDownloadStartNotification;
extern NSString *const SDWebImageDownloadStopNotification;

/**
 * Asynchronous downloader dedicated and optimized for image loading.
 */
@interface SDWebImageDownloader : NSObject
{
    @private
    NSURL *url;
    SDWIWeak id<SDWebImageDownloaderDelegate> delegate;
    NSURLConnection *connection;
    NSMutableData *imageData;
    id userInfo;
    BOOL lowPriority;
    NSUInteger expectedSize;
    BOOL progressive;
    size_t width, height;
}

@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) id<SDWebImageDownloaderDelegate> delegate;
@property (nonatomic, retain) NSMutableData *imageData;
@property (nonatomic, retain) id userInfo;
@property (nonatomic, readwrite) BOOL lowPriority;

/**
 * If set to YES, enables progressive download support.
 *
 * The [SDWebImageDownloaderDelegate imageDownloader:didUpdatePartialImage:] delegate method is then called
 * while the image is downloaded with an image object containing the portion of the currently downloaded
 * image.
 *
 * @see http://www.cocoaintheshell.com/2011/05/progressive-images-download-imageio/
 */
@property (nonatomic, readwrite) BOOL progressive;

/**
 * Creates a SDWebImageDownloader async downloader instance with a given URL
 *
 * The delegate will be informed when the image is finish downloaded or an error has happen.
 *
 * @see SDWebImageDownloaderDelegate
 *
 * @param url The URL to the image to download
 * @param delegate The delegate object
 * @param userInfo A NSDictionary containing custom info
 * @param lowPriority Ensure the download won't run during UI interactions
 *
 * @return A new SDWebImageDownloader instance
 */
+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate userInfo:(id)userInfo lowPriority:(BOOL)lowPriority;
+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate userInfo:(id)userInfo;
+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate;

- (void)start;

/**
 * Cancel the download immediatelly
 */
- (void)cancel;

// This method is now no-op and is deprecated
+ (void)setMaxConcurrentDownloads:(NSUInteger)max __attribute__((deprecated));

@end
