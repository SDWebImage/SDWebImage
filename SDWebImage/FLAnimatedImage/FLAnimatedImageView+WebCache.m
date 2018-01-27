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

@implementation UIImage (FLAnimatedImage)

- (FLAnimatedImage *)sd_FLAnimatedImage {
    return objc_getAssociatedObject(self, @selector(sd_FLAnimatedImage));
}

- (void)setSd_FLAnimatedImage:(FLAnimatedImage *)sd_FLAnimatedImage {
    objc_setAssociatedObject(self, @selector(sd_FLAnimatedImage), sd_FLAnimatedImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

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
    dispatch_group_t group = dispatch_group_create();
    __weak typeof(self)weakSelf = self;
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           // We could not directlly create the animated image on bacakground queue because it's time consuming, by the time we set it back, the current runloop has passed and the placeholder has been rendered and then replaced with animated image, this cause a flashing.
                           // Previously we use a trick to firstly set the static poster image, then set animated image back to avoid flashing, but this trick fail when using with custom UIView transition. Core Animation will use the current layer state to do rendering, so even we later set it back, the transition will not update. (it's recommended to use `SDWebImageTransition` instead)
                           // So we have no choice to force store the FLAnimatedImage into memory cache using a associated object binding to UIImage instance. This consumed memory is adoptable and much smaller than `_UIAnimatedImage` for big GIF
                           FLAnimatedImage *associatedAnimatedImage = image.sd_FLAnimatedImage;
                           if (associatedAnimatedImage) {
                               // Asscociated animated image exist
                               weakSelf.animatedImage = associatedAnimatedImage;
                               weakSelf.image = nil;
                               if (group) {
                                   dispatch_group_leave(group);
                               }
                           } else if ([NSData sd_imageFormatForImageData:imageData] == SDImageFormatGIF) {
                               // Firstly set the static poster image to avoid flashing
                               UIImage *posterImage = image.images ? image.images.firstObject : image;
                               weakSelf.image = posterImage;
                               weakSelf.animatedImage = nil;
                               // Secondly create FLAnimatedImage in global queue because it's time consuming, then set it back
                               dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                   FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:imageData];
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       image.sd_FLAnimatedImage = animatedImage;
                                       weakSelf.animatedImage = animatedImage;
                                       weakSelf.image = nil;
                                       if (group) {
                                           dispatch_group_leave(group);
                                       }
                                   });
                               });
                           } else {
                               // Not animated image
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
