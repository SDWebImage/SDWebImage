/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageManagerDelegate.h"

@interface SDWebImagePrefetcher : NSObject <SDWebImageManagerDelegate> {
    NSArray     *_prefetchList;    // Array of URLs
    NSUInteger   _skippedCount;
    NSUInteger   _finishedCount;
    NSUInteger   _requestedCount;
    NSTimeInterval _startedTime;
}

+ (SDWebImagePrefetcher *)sharedImagePrefetcher;

@property (nonatomic, assign) NSUInteger maxConcurrentDownloads;        // Default is 3


// Assign list of URLs to let SDWebImagePrefetcher to queue the prefetching,
// currently one image is downloaded at a time,
// and skips images for failed downloads and proceed to the next image in the list
- (void)startPrefetchingWithList:(NSArray *)list;


// Remove and cancel queued list
- (void)cancelPrefetching;


@end
