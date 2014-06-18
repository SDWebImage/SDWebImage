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
    [self setHighlightedImageAndReturnURLWithURL:url options:0 progress:nil completed:nil];
}

- (void)setHighlightedImageWithURL:(NSURL *)url options:(SDWebImageOptions)options {
    [self setHighlightedImageAndReturnURLWithURL:url options:options progress:nil completed:nil];

}

- (void)setHighlightedImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock {
    [self setHighlightedImageWithURL:url options:0 progress:nil completed:completedBlock];
}

- (void)setHighlightedImageWithURL:(NSURL *)url options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self setHighlightedImageAndReturnURLWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        completedBlock(image,error,cacheType);
    }];
}


- (void)setHighlightedImageWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageCompletedBlock)completedBlock {
    
[self setHighlightedImageAndReturnURLWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
    completedBlock(image,error,cacheType);
}];

}





- (void)setHighlightedImageAndReturnURLWithURL:(NSURL *)url {
    [self setHighlightedImageAndReturnURLWithURL:url options:0 progress:nil completed:nil];
}

- (void)setHighlightedImageAndReturnURLWithURL:(NSURL *)url options:(SDWebImageOptions)options {
    [self setHighlightedImageAndReturnURLWithURL:url options:options progress:nil completed:nil];
}

- (void)setHighlightedImageAndReturnURLWithURL:(NSURL *)url completed:(SDWebImageWithURLCompletedBlock)completedBlock {
    [self setHighlightedImageAndReturnURLWithURL:url options:0 progress:nil completed:completedBlock];
}

- (void)setHighlightedImageAndReturnURLWithURL:(NSURL *)url options:(SDWebImageOptions)options completed:(SDWebImageWithURLCompletedBlock)completedBlock {
    [self setHighlightedImageAndReturnURLWithURL:url options:options progress:nil completed:completedBlock];
}


- (void)setHighlightedImageAndReturnURLWithURL:(NSURL *)url options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDWebImageWithURLCompletedBlock)completedBlock {
    [self cancelCurrentImageLoad];
    
    if (url) {
        __weak UIImageView      *wself    = self;
        id<SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadImageWithURL:url
                                                                                     options:options
                                                                                    progress:progressBlock
                                                                                   completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished,NSURL* imageURL)
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
                                                                                  completedBlock(image, error, cacheType,url);
                                                                              }
                                                                          });
                                             }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
