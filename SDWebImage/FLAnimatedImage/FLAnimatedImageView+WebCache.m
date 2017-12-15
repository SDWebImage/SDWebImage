/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "FLAnimatedImageView+WebCache.h"

#if SD_UIKIT
#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"
#import "NSData+ImageContentType.h"
#import "UIImageView+WebCache.h"

@implementation FLAnimatedImageView (WebCache)

- (void)sd_setImageWithURL:(nullable NSURL *)url {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                  progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    dispatch_group_t group = dispatch_group_create();
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:imageData];
                           if (imageFormat == SDImageFormatGIF) {
                               // Firstly set the static poster image to avoid flashing
                               UIImage *posterImage = image.images ? image.images.firstObject : image;
                               weakSelf.image = posterImage;
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                   // Secondly create FLAnimatedImage in global queue because it's time consuming, then set it back
                                   FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
                                   dispatch_main_async_safe(^{
                                       weakSelf.animatedImage = animatedImage;
                                       if (group) {
                                           dispatch_group_leave(group);
                                       }
                                   });
                               });
                           } else {
                               weakSelf.image = image;
                               weakSelf.animatedImage = nil;
                               if (group) {
                                   dispatch_group_leave(group);
                               }
                           }
                       }
                            progress:progressBlock
                           completed:completedBlock
                             context:group ? @{SDWebImageInternalSetImageGroupKey : group} : nil];
}

@end

#endif
