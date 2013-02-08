/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageDownloader.h"
#import "SDWebImageOperation.h"

@interface SDWebImageDownloaderOperation : NSOperation <SDWebImageOperation>

@property (strong, nonatomic, readonly) NSURLRequest *request;
@property (assign, nonatomic, readonly) SDWebImageDownloaderOptions options;

- (id)initWithRequest:(NSURLRequest *)request
                queue:(dispatch_queue_t)queue
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
             redirect:(SDWebImageDownloaderRedirectedBlock)redirectBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)())cancelBlock;

@end
