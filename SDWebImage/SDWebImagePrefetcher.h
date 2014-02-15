/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageManager.h"

@class SDWebImagePrefetcher;

@protocol SDWebImagePrefetcherDelegate <NSObject>

@optional

/**
 * Called when an image was prefetched.
 *
 * @param imagePrefetcher The current image prefetcher
 * @param imageURL The image url that was prefetched
 * @param finishedCount The total number of images that were prefetched
 * @param totalCount The total number of images that need to be prefetched
 */
- (void)imagePrefetcher:(SDWebImagePrefetcher *)imagePrefetcher didPrefetchURL:(NSURL *)imageURL finishedCount:(NSUInteger)finishedCount totalCount:(NSUInteger)totalCount;

/**
 * Called when all images are prefetched.
 * @param imagePrefetcher The current image prefetcher
 * @param totalCount The total number of images that need to be prefetched
 * @param skippedCount The total number of images that were skipped
 */
- (void)imagePrefetcher:(SDWebImagePrefetcher *)imagePrefetcher didFinishWithTotalCount:(NSUInteger)totalCount skippedCount:(NSUInteger)skippedCount;

@end


/**
 * Prefetch some URLs in the cache for future use. Images are downloaded in low priority.
 */
@interface SDWebImagePrefetcher : NSObject

/**
 * Maximum number of URLs to prefetch at the same time. Defaults to 3.
 */
@property (nonatomic, assign) NSUInteger maxConcurrentDownloads;

/**
 * SDWebImageOptions for prefetcher. Defaults to SDWebImageLowPriority.
 */
@property (nonatomic, assign) SDWebImageOptions options;

@property (weak, nonatomic) id <SDWebImagePrefetcherDelegate> delegate;

/**
 * Return the global image prefetcher instance.
 */
+ (SDWebImagePrefetcher *)sharedImagePrefetcher;

/**
 * Assign list of URLs to let SDWebImagePrefetcher to queue the prefetching,
 * currently one image is downloaded at a time,
 * and skips images for failed downloads and proceed to the next image in the list
 *
 * @param urls list of URLs to prefetch
 */
- (void)prefetchURLs:(NSArray *)urls;

/**
 * Assign list of URLs to let SDWebImagePrefetcher to queue the prefetching,
 * currently one image is downloaded at a time,
 * and skips images for failed downloads and proceed to the next image in the list
 *
 * @param urls list of URLs to prefetch
 * @param progressBlock block to be called when progress updates
 * @param completionBlock block to be called when prefetching is completed
 */
- (void)prefetchURLs:(NSArray *)urls progress:(void (^)(NSUInteger, NSUInteger))progressBlock completed:(void (^)(NSUInteger, NSUInteger))completionBlock;

/**
 * Remove and cancel queued list
 */
- (void)cancelPrefetching;


@end
