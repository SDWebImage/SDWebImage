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
#import "UIImage+MultiFormat.h"

/**
 A `SDWebImageGroup` to maintain setImageBlock and completionBlock. This key should be used only internally and may be changed in the future. (`SDWebImageGroup`)
 */
FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageInternalSetImageSDGroupKey;

static inline FLAnimatedImage * SDWebImageCreateFLAnimatedImage(FLAnimatedImageView *imageView, NSData *imageData) {
    if ([NSData sd_imageFormatForImageData:imageData] != SDImageFormatGIF) {
        return nil;
    }
    FLAnimatedImage *animatedImage;
    // Compatibility in 4.x for lower version FLAnimatedImage.
    if ([FLAnimatedImage respondsToSelector:@selector(initWithAnimatedGIFData:optimalFrameCacheSize:predrawingEnabled:)]) {
        animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData optimalFrameCacheSize:imageView.sd_optimalFrameCacheSize predrawingEnabled:imageView.sd_predrawingEnabled];
    } else {
        animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
    }
    return animatedImage;
}

@implementation UIImage (FLAnimatedImage)

- (FLAnimatedImage *)sd_FLAnimatedImage {
    return objc_getAssociatedObject(self, @selector(sd_FLAnimatedImage));
}

- (void)setSd_FLAnimatedImage:(FLAnimatedImage *)sd_FLAnimatedImage {
    objc_setAssociatedObject(self, @selector(sd_FLAnimatedImage), sd_FLAnimatedImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation FLAnimatedImageView (WebCache)

// These property based options will moved to `SDWebImageContext` in 5.x, to allow per-image-request level options instead of per-imageView-level options
- (NSUInteger)sd_optimalFrameCacheSize {
    NSUInteger optimalFrameCacheSize = 0;
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_optimalFrameCacheSize));
    if ([value isKindOfClass:[NSNumber class]]) {
        optimalFrameCacheSize = value.unsignedShortValue;
    }
    return optimalFrameCacheSize;
}

- (void)setSd_optimalFrameCacheSize:(NSUInteger)sd_optimalFrameCacheSize {
    objc_setAssociatedObject(self, @selector(sd_optimalFrameCacheSize), @(sd_optimalFrameCacheSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sd_predrawingEnabled {
    BOOL predrawingEnabled = YES;
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_predrawingEnabled));
    if ([value isKindOfClass:[NSNumber class]]) {
        predrawingEnabled = value.boolValue;
    }
    return predrawingEnabled;
}

- (void)setSd_predrawingEnabled:(BOOL)sd_predrawingEnabled {
    objc_setAssociatedObject(self, @selector(sd_predrawingEnabled), @(sd_predrawingEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sd_cacheFLAnimatedImage {
    BOOL cacheFLAnimatedImage = YES;
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_cacheFLAnimatedImage));
    if ([value isKindOfClass:[NSNumber class]]) {
        cacheFLAnimatedImage = value.boolValue;
    }
    return cacheFLAnimatedImage;
}

- (void)setSd_cacheFLAnimatedImage:(BOOL)sd_cacheFLAnimatedImage {
    objc_setAssociatedObject(self, @selector(sd_cacheFLAnimatedImage), @(sd_cacheFLAnimatedImage), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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
                           __strong typeof(weakSelf)strongSelf = weakSelf;
                           if (!strongSelf) {
                               return;
                           }
                           // Step 1. Check memory cache (associate object)
                           FLAnimatedImage *associatedAnimatedImage = image.sd_FLAnimatedImage;
                           if (associatedAnimatedImage) {
                               // Asscociated animated image exist
                               // FLAnimatedImage framework contains a bug that cause GIF been rotated if previous rendered image orientation is not Up. We have to call `setImage:` with non-nil image to reset the state. See `https://github.com/rs/SDWebImage/issues/2402`
                               strongSelf.image = associatedAnimatedImage.posterImage;
                               strongSelf.animatedImage = associatedAnimatedImage;
                               return;
                           }
                           // Step 2. Check if original compressed image data is "GIF"
                           BOOL isGIF = (image.sd_imageFormat == SDImageFormatGIF || [NSData sd_imageFormatForImageData:imageData] == SDImageFormatGIF);
                           if (!isGIF) {
                               strongSelf.image = image;
                               strongSelf.animatedImage = nil;
                               return;
                           }
                           // Hack, mark we need should use dispatch group notify for completedBlock
                           objc_setAssociatedObject(group, &SDWebImageInternalSetImageSDGroupKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                               // Step 3. Check if data exist or query disk cache
                               NSData *diskData = imageData;
                               if (!diskData) {
                                   NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
                                   diskData = [[SDImageCache sharedImageCache] diskImageDataForKey:key];
                               }
                               // Step 4. Create FLAnimatedImage
                               FLAnimatedImage *animatedImage = SDWebImageCreateFLAnimatedImage(strongSelf, diskData);
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   // Step 5. Set animatedImage or normal image
                                   if (animatedImage) {
                                       if (strongSelf.sd_cacheFLAnimatedImage) {
                                           image.sd_FLAnimatedImage = animatedImage;
                                       }
                                       strongSelf.image = animatedImage.posterImage;
                                       strongSelf.animatedImage = animatedImage;
                                   } else {
                                       strongSelf.image = image;
                                       strongSelf.animatedImage = nil;
                                   }
                                   dispatch_group_leave(group);
                               });
                           });
                       }
                            progress:progressBlock
                           completed:completedBlock
                             context:@{SDWebImageInternalSetImageSDGroupKey: group}];
}

@end

#endif
