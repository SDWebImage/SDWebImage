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

- (FLAnimatedImageViewSetImagePolicy)sd_setImagePolicy {
    FLAnimatedImageViewSetImagePolicy setImagePolicy = FLAnimatedImageViewSetImagePolicyStandard;
    NSNumber *value = objc_getAssociatedObject(self, @selector(sd_setImagePolicy));
    if ([value isKindOfClass:[NSNumber class]]) {
        setImagePolicy = value.unsignedIntegerValue;
    }
    return setImagePolicy;
}

- (void)setSd_setImagePolicy:(FLAnimatedImageViewSetImagePolicy)sd_setImagePolicy {
    objc_setAssociatedObject(self, @selector(sd_setImagePolicy), @(sd_setImagePolicy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    NSDictionary *context;
    dispatch_group_t group = dispatch_group_create();
    SDSetImageGroupConditionBlock groupConditionBlock = ^BOOL(UIImage *image, NSData *imageData) {
        FLAnimatedImage *associatedAnimatedImage = image.sd_FLAnimatedImage;
        if (associatedAnimatedImage) {
            return YES;
        }
        if ([NSData sd_imageFormatForImageData:imageData] == SDImageFormatGIF) {
            return YES;
        }
        return NO;
    };
    if (group) {
        NSMutableDictionary *mutableContext = [NSMutableDictionary dictionaryWithCapacity:2];
        [mutableContext setValue:group forKey:SDWebImageInternalSetImageGroupKey];
        [mutableContext setValue:groupConditionBlock forKey:SDWebImageInternalSetImageGroupConditionBlockKey];
        context = [mutableContext copy];
    }
    
    __weak typeof(self)weakSelf = self;
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           __strong typeof(weakSelf)strongSelf = weakSelf;
                           if (!strongSelf) {
                               if (group) {
                                   dispatch_group_leave(group);
                               }
                               return;
                           }
                           // We could not directlly create the animated image on bacakground queue because it's time consuming, by the time we set it back, the current runloop has passed and the placeholder has been rendered and then replaced with animated image, this cause a flashing.
                           // Previously we use a trick to firstly set the static poster image, then set animated image back to avoid flashing, but this trick fail when using with custom UIView transition. Core Animation will use the current layer state to do rendering, so even we later set it back, the transition will not update. (it's recommended to use `SDWebImageTransition` instead)
                           // So we have no choice to force store the FLAnimatedImage into memory cache using a associated object binding to UIImage instance. This consumed memory is adoptable and much smaller than `_UIAnimatedImage` for big GIF
                           FLAnimatedImage *associatedAnimatedImage = image.sd_FLAnimatedImage;
                           if (associatedAnimatedImage) {
                               // Asscociated animated image exist
                               strongSelf.animatedImage = associatedAnimatedImage;
                               strongSelf.image = nil;
                               if (group) {
                                   dispatch_group_leave(group);
                               }
                           } else if ([NSData sd_imageFormatForImageData:imageData] == SDImageFormatGIF) {
                               // Directly create FLAnimatedImage on main queue
                               if (strongSelf.sd_setImagePolicy == FLAnimatedImageViewSetImagePolicyStandard) {
                                   FLAnimatedImage *animatedImage;
                                   // Compatibility in 4.x for lower version FLAnimatedImage.
                                   if ([FLAnimatedImage respondsToSelector:@selector(initWithAnimatedGIFData:optimalFrameCacheSize:predrawingEnabled:)]) {
                                       animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData optimalFrameCacheSize:strongSelf.sd_optimalFrameCacheSize predrawingEnabled:strongSelf.sd_predrawingEnabled];
                                   } else {
                                       animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
                                   }
                                   image.sd_FLAnimatedImage = animatedImage;
                                   strongSelf.animatedImage = animatedImage;
                                   strongSelf.image = nil;
                                   if (group) {
                                       dispatch_group_leave(group);
                                   }
                               } else {
                                   // Firstly set the static poster image to avoid flashing
                                   UIImage *posterImage = image.images ? image.images.firstObject : image;
                                   strongSelf.image = posterImage;
                                   strongSelf.animatedImage = nil;
                                   // Secondly create FLAnimatedImage in global queue because it's time consuming, then set it back
                                   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                                       FLAnimatedImage *animatedImage;
                                       // Compatibility in 4.x for lower version FLAnimatedImage.
                                       if ([FLAnimatedImage respondsToSelector:@selector(initWithAnimatedGIFData:optimalFrameCacheSize:predrawingEnabled:)]) {
                                           animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData optimalFrameCacheSize:strongSelf.sd_optimalFrameCacheSize predrawingEnabled:strongSelf.sd_predrawingEnabled];
                                       } else {
                                           animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
                                       }
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           image.sd_FLAnimatedImage = animatedImage;
                                           strongSelf.animatedImage = animatedImage;
                                           strongSelf.image = nil;
                                           if (group) {
                                               dispatch_group_leave(group);
                                           }
                                       });
                                   });
                               }
                           } else {
                               // Not animated image
                               strongSelf.image = image;
                               strongSelf.animatedImage = nil;
                               if (group) {
                                   dispatch_group_leave(group);
                               }
                           }
                       }
                            progress:progressBlock
                           completed:completedBlock
                             context:context];
}

@end

#endif
