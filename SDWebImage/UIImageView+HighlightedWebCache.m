/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+HighlightedWebCache.h"
#import "objc/runtime.h"

static char operationKey;

@implementation UIImageView (HighlightedWebCache)

- (void)setHighlightedImageWithURL:(NSURL *)url {
    [self setHighlightedImageWithURL:url options:0 progress:nil completed:nil];
}

- (void)setHighlightedImageWithURL:(NSURL *)url options:(SDWebImageOptions)options {
    [self setHighlightedImageWithURL:url options:options progress:nil completed:nil];
}

- (void)setHighlightedImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)setHighlightedImageWithURL:(NSURL *)url options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self setHighlightedImageWithURL:url options:options progress:nil completed:completedBlock];
}

- (void)setHighlightedImageWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock {
    [self cancelCurrentImageLoad];

    if (url) {
        __weak UIImageView      *wself    = self;
        id<SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url
                                                                                     options:options
                                                                                    progress:progressBlock
                                                                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
                                             {
                                                 if (!wself) return;
                                                 dispatch_main_sync_safe (^
                                                                          {
                                                                              if (!wself) return;
                                                                              if (image) {
                                                                                  wself.highlightedImage = image;
                                                                                  [wself setNeedsLayout];
                                                                              }
                                                                              if (completedBlock && finished) {
                                                                                  completedBlock(image, error, cacheType);
                                                                              }
                                                                          });
                                             }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
