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
#import "UIImage+MemoryCacheCost.h"

@interface UIView (PrivateWebCache)

- (void)sd_internalSetImageWithURL:(nullable NSURL *)url
                  placeholderImage:(nullable UIImage *)placeholder
                           options:(SDWebImageOptions)options
                      operationKey:(nullable NSString *)operationKey
             internalSetImageBlock:(nullable SDInternalSetImageBlock)setImageBlock
                          progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                         completed:(nullable SDExternalCompletionBlock)completedBlock
                           context:(nullable NSDictionary<NSString *, id> *)context;

@end

static inline FLAnimatedImage * SDWebImageCreateFLAnimatedImage(FLAnimatedImageView *imageView, NSData *imageData) {
    if ([NSData sd_imageFormatForImageData:imageData] != SDImageFormatGIF) {
        return nil;
    }
    FLAnimatedImage *animatedImage;
    // Compatibility in 4.x for lower version FLAnimatedImage.
    if ([FLAnimatedImage instancesRespondToSelector:@selector(initWithAnimatedGIFData:optimalFrameCacheSize:predrawingEnabled:)]) {
        animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData optimalFrameCacheSize:imageView.sd_optimalFrameCacheSize predrawingEnabled:imageView.sd_predrawingEnabled];
    } else {
        animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
    }
    return animatedImage;
}

static inline NSUInteger SDWebImageMemoryCostFLAnimatedImage(FLAnimatedImage *animatedImage, UIImage *image) {
    NSUInteger frameCacheSizeCurrent = animatedImage.frameCacheSizeCurrent; // [1...frame count], more suitable than raw frame count because FLAnimatedImage internal actually store a buffer size but not full frames (they called `window`)
    NSUInteger pixelsPerFrame = animatedImage.size.width * animatedImage.size.height; // FLAnimatedImage does not support scale factor
    NSUInteger animatedImageCost = frameCacheSizeCurrent * pixelsPerFrame;
    
    NSUInteger imageCost = image.size.height * image.size.width * image.scale * image.scale; // Same as normal cost calculation
    imageCost = image.images ? (imageCost * image.images.count) : imageCost;
    
    return animatedImageCost + imageCost;
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
               internalSetImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           __strong typeof(weakSelf)strongSelf = weakSelf;
                           if (!strongSelf) {
                               dispatch_group_leave(group);
                               return;
                           }
                           // Step 1. Check memory cache (associate object)
                           FLAnimatedImage *associatedAnimatedImage = image.sd_FLAnimatedImage;
                           if (associatedAnimatedImage) {
                               // Asscociated animated image exist
                               // FLAnimatedImage framework contains a bug that cause GIF been rotated if previous rendered image orientation is not Up. We have to call `setImage:` with non-nil image to reset the state. See `https://github.com/SDWebImage/SDWebImage/issues/2402`
                               strongSelf.image = associatedAnimatedImage.posterImage;
                               strongSelf.animatedImage = associatedAnimatedImage;
                               dispatch_group_leave(group);
                               return;
                           }
                           // Step 2. Check if original compressed image data is "GIF"
                           BOOL isGIF = (image.sd_imageFormat == SDImageFormatGIF || [NSData sd_imageFormatForImageData:imageData] == SDImageFormatGIF);
                           // Check if placeholder, which does not trigger a backup disk cache query
                           BOOL isPlaceholder = !imageData && image && cacheType == SDImageCacheTypeNone;
                           if (!isGIF || isPlaceholder) {
                               strongSelf.image = image;
                               strongSelf.animatedImage = nil;
                               dispatch_group_leave(group);
                               return;
                           }
                           __weak typeof(strongSelf) wweakSelf = strongSelf;
                           // Hack, mark we need should use dispatch group notify for completedBlock
                           objc_setAssociatedObject(group, &SDWebImageInternalSetImageGroupKey, @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                               __strong typeof(wweakSelf) sstrongSelf = wweakSelf;
                               if (!sstrongSelf || ![url isEqual:sstrongSelf.sd_imageURL]) { return ; }
                               // Step 3. Check if data exist or query disk cache
                               NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
                               __block NSData *gifData = imageData;
                               if (!gifData) {
                                   gifData = [[SDImageCache sharedImageCache] diskImageDataForKey:key];
                               }
                               // Step 4. Create FLAnimatedImage
                               FLAnimatedImage *animatedImage = SDWebImageCreateFLAnimatedImage(sstrongSelf, gifData);
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   if (![url isEqual:sstrongSelf.sd_imageURL]) { return ; }
                                   // Step 5. Set animatedImage or normal image
                                   if (animatedImage) {
                                       if (sstrongSelf.sd_cacheFLAnimatedImage && SDImageCache.sharedImageCache.config.shouldCacheImagesInMemory) {
                                           image.sd_FLAnimatedImage = animatedImage;
                                           image.sd_memoryCost = SDWebImageMemoryCostFLAnimatedImage(animatedImage, image);
                                           // Update the memory cache
                                           [SDImageCache.sharedImageCache removeImageForKey:key fromDisk:NO withCompletion:nil];
                                           [SDImageCache.sharedImageCache storeImage:image forKey:key toDisk:NO completion:nil];
                                       }
                                       sstrongSelf.image = animatedImage.posterImage;
                                       sstrongSelf.animatedImage = animatedImage;
                                   } else {
                                       sstrongSelf.image = image;
                                       sstrongSelf.animatedImage = nil;
                                   }
                                   dispatch_group_leave(group);
                               });
                           });
                       }
                            progress:progressBlock
                           completed:completedBlock
                             context:@{SDWebImageInternalSetImageGroupKey: group}];
}

@end

#endif
