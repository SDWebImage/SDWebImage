/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageDownloaderDelegate.h"

@interface SDWebImageDownloader : NSOperation
{
    NSURL *url;
    id<SDWebImageDownloaderDelegate> delegate;
}

@property (retain) NSURL *url;
@property (assign) id<SDWebImageDownloaderDelegate> delegate;

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<SDWebImageDownloaderDelegate>)delegate;
+ (void)setMaxConcurrentDownloads:(NSUInteger)max;

@end
