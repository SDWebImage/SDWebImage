/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "CALayer+WebCache.h"
#import "objc/runtime.h"

static char operationKey;

@implementation CALayer (WebCache)

- (void)setContentsWithURL:(NSURL *)url
{
    [self setContentsWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder
{
    [self setContentsWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options
{
    [self setContentsWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)setContentsWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setContentsWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setContentsWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock
{
    [self setContentsWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}



- (void)setContentsWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock;
{
    [self cancelCurrentImageLoad];

    self.contents = (id)[placeholder CGImage];

    if (url)
    {
        __weak CALayer *wself = self;
        id<SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
                                             {
                                                 __strong CALayer *sself = wself;
                                                 if (!sself) return;
                                                 if (image)
                                                 {
                                                     sself.contents = (id)[image CGImage];
                                                     [sself setNeedsLayout];
                                                 }
                                                 if (completedBlock && finished)
                                                 {
                                                     completedBlock(image, error, cacheType);
                                                 }
                                             }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)cancelCurrentImageLoad
{
    // Cancel in progress downloader from queue
    id<SDWebImageOperation> operation = objc_getAssociatedObject(self, &operationKey);
    if (operation)
    {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
