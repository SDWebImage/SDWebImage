/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "NSButton+WebCache.h"

#if SD_MAC

#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCacheState.h"
#import "UIView+WebCache.h"
#import "SDInternalMacros.h"

static NSString * const SDAlternateImageOperationKey = @"NSButtonAlternateImageOperation";

@implementation NSButton (WebCache)

#pragma mark - Image

- (void)sd_setImageWithURL:(nullable NSURL *)url {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options context:context progress:nil completed:nil];
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

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options progress:(nullable SDImageLoaderProgressBlock)progressBlock completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                   context:(nullable SDWebImageContext *)context
                  progress:(nullable SDImageLoaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:context
                       setImageBlock:nil
                            progress:progressBlock
                           completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Alternate Image

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url {
    [self sd_setAlternateImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setAlternateImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setAlternateImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context {
    [self sd_setAlternateImageWithURL:url placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setAlternateImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setAlternateImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setAlternateImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options progress:(nullable SDImageLoaderProgressBlock)progressBlock completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setAlternateImageWithURL:url placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)sd_setAlternateImageWithURL:(nullable NSURL *)url
                   placeholderImage:(nullable UIImage *)placeholder
                            options:(SDWebImageOptions)options
                            context:(nullable SDWebImageContext *)context
                           progress:(nullable SDImageLoaderProgressBlock)progressBlock
                          completed:(nullable SDExternalCompletionBlock)completedBlock {
    SDWebImageMutableContext *mutableContext;
    if (context) {
        mutableContext = [context mutableCopy];
    } else {
        mutableContext = [NSMutableDictionary dictionary];
    }
    mutableContext[SDWebImageContextSetImageOperationKey] = SDAlternateImageOperationKey;
    @weakify(self);
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:mutableContext
                       setImageBlock:^(NSImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           @strongify(self);
                           self.alternateImage = image;
                       }
                            progress:progressBlock
                           completed:^(NSImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Cancel

- (void)sd_cancelCurrentImageLoad {
    [self sd_cancelImageLoadOperationWithKey:NSStringFromClass([self class])];
}

- (void)sd_cancelCurrentAlternateImageLoad {
    [self sd_cancelImageLoadOperationWithKey:SDAlternateImageOperationKey];
}

#pragma mark - State

- (NSURL *)sd_currentImageURL {
    SDWebImageStateContainer *state = [self sd_imageLoadStateForKey:nil];
    return state[SDWebImageStateContainerURL];
}

- (NSProgress *)sd_currentImageProgress {
    SDWebImageStateContainer *state = [self sd_imageLoadStateForKey:nil];
    return state[SDWebImageStateContainerProgress];
}

- (void)setSd_currentImageProgress:(NSProgress *)sd_currentImageProgress {
    if (!sd_currentImageProgress) {
        return;
    }
    SDWebImageMutableStateContainer *mutableState = [[self sd_imageLoadStateForKey:nil] mutableCopy];
    if (!mutableState) {
        mutableState = [SDWebImageMutableStateContainer dictionary];
    }
    mutableState[SDWebImageStateContainerProgress] = sd_currentImageProgress;
    [self sd_setImageLoadState:[mutableState copy] forKey:nil];
}

- (SDWebImageTransition *)sd_currentImageTransition {
    SDWebImageStateContainer *state = [self sd_imageLoadStateForKey:nil];
    return state[SDWebImageStateContainerTransition];
}

- (void)setSd_currentImageTransition:(SDWebImageTransition *)sd_currentImageTransition {
    if (!sd_currentImageTransition) {
        return;
    }
    SDWebImageMutableStateContainer *mutableState = [[self sd_imageLoadStateForKey:nil] mutableCopy];
    if (!mutableState) {
        mutableState = [SDWebImageMutableStateContainer dictionary];
    }
    mutableState[SDWebImageStateContainerTransition] = sd_currentImageTransition;
    [self sd_setImageLoadState:[mutableState copy] forKey:nil];
}

#pragma mark - Alternate State

- (NSURL *)sd_currentAlternateImageURL {
    SDWebImageStateContainer *state = [self sd_imageLoadStateForKey:SDAlternateImageOperationKey];
    return state[SDWebImageStateContainerURL];
}

- (NSProgress *)sd_currentAlternateImageProgress {
    SDWebImageStateContainer *state = [self sd_imageLoadStateForKey:SDAlternateImageOperationKey];
    return state[SDWebImageStateContainerProgress];
}

- (void)setsd_currentAlternateImageProgress:(NSProgress *)sd_currentAlternateImageProgress {
    if (!sd_currentAlternateImageProgress) {
        return;
    }
    SDWebImageMutableStateContainer *mutableState = [[self sd_imageLoadStateForKey:SDAlternateImageOperationKey] mutableCopy];
    if (!mutableState) {
        mutableState = [SDWebImageMutableStateContainer dictionary];
    }
    mutableState[SDWebImageStateContainerProgress] = sd_currentAlternateImageProgress;
    [self sd_setImageLoadState:[mutableState copy] forKey:SDAlternateImageOperationKey];
}

- (SDWebImageTransition *)sd_currentAlternateImageTransition {
    SDWebImageStateContainer *state = [self sd_imageLoadStateForKey:SDAlternateImageOperationKey];
    return state[SDWebImageStateContainerTransition];
}

- (void)setsd_currentAlternateImageTransition:(SDWebImageTransition *)sd_currentAlternateImageTransition {
    if (!sd_currentAlternateImageTransition) {
        return;
    }
    SDWebImageMutableStateContainer *mutableState = [[self sd_imageLoadStateForKey:SDAlternateImageOperationKey] mutableCopy];
    if (!mutableState) {
        mutableState = [SDWebImageMutableStateContainer dictionary];
    }
    mutableState[SDWebImageStateContainerTransition] = sd_currentAlternateImageTransition;
    [self sd_setImageLoadState:[mutableState copy] forKey:SDAlternateImageOperationKey];
}

@end

#endif
