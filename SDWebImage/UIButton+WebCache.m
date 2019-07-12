/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+WebCache.h"

#if SD_UIKIT

#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCacheState.h"
#import "UIView+WebCache.h"
#import "SDInternalMacros.h"

static inline NSString * imageOperationKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"UIButtonImageOperation%lu", (unsigned long)state];
}

static inline NSString * backgroundImageOperationKeyForState(UIControlState state) {
    return [NSString stringWithFormat:@"UIButtonBackgroundImageOperation%lu", (unsigned long)state];
}

@implementation UIButton (WebCache)

#pragma mark - Image

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options progress:(nullable SDImageLoaderProgressBlock)progressBlock completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url
                  forState:(UIControlState)state
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
    mutableContext[SDWebImageContextSetImageOperationKey] = imageOperationKeyForState(state);
    @weakify(self);
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:mutableContext
                       setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           @strongify(self);
                           [self setImage:image forState:state];
                       }
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Background Image

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options context:context progress:nil completed:nil];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options progress:(nullable SDImageLoaderProgressBlock)progressBlock completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options context:nil progress:progressBlock completed:completedBlock];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url
                            forState:(UIControlState)state
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
    mutableContext[SDWebImageContextSetImageOperationKey] = backgroundImageOperationKeyForState(state);
    @weakify(self);
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:mutableContext
                       setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                           @strongify(self);
                           [self setBackgroundImage:image forState:state];
                       }
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#pragma mark - Cancel

- (void)sd_cancelImageLoadForState:(UIControlState)state {
    [self sd_cancelImageLoadOperationWithKey:imageOperationKeyForState(state)];
}

- (void)sd_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self sd_cancelImageLoadOperationWithKey:backgroundImageOperationKeyForState(state)];
}

#pragma mark - State

- (NSURL *)sd_currentImageURL {
    NSURL *url = [self sd_imageURLForState:self.state];
    if (!url) {
        [self sd_imageURLForState:UIControlStateNormal];
    }
    return url;
}

- (NSURL *)sd_imageURLForState:(UIControlState)state {
    return [self sd_imageLoadStateForKey:imageOperationKeyForState(state)].url;
}

- (NSProgress *)sd_imageProgressForState:(UIControlState)state {
    return [self sd_imageLoadStateForKey:imageOperationKeyForState(state)].progress;
}

- (void)sd_setImageProgress:(NSProgress *)progress forState:(UIControlState)state {
    if (!progress) {
        return;
    }
    SDWebImageStateContainer *stateContainer = [self sd_imageLoadStateForKey:imageOperationKeyForState(state)];
    if (!stateContainer) {
        stateContainer = [SDWebImageStateContainer new];
    }
    stateContainer.progress = progress;
    [self sd_setImageLoadState:stateContainer forKey:nil];
    
}

- (SDWebImageTransition *)sd_imageTransitionForState:(UIControlState)state {
    return [self sd_imageLoadStateForKey:imageOperationKeyForState(state)].transition;
}

- (void)sd_setImageTransition:(SDWebImageTransition *)transition forState:(UIControlState)state {
    if (!transition) {
        return;
    }
    SDWebImageStateContainer *stateContainer = [self sd_imageLoadStateForKey:imageOperationKeyForState(state)];
    if (!stateContainer) {
        stateContainer = [SDWebImageStateContainer new];
    }
    stateContainer.transition = transition;
    [self sd_setImageLoadState:stateContainer forKey:nil];
}

#pragma mark - Background State

- (NSURL *)sd_currentBackgroundImageURL {
    NSURL *url = [self sd_backgroundImageURLForState:self.state];
    if (!url) {
        url = [self sd_backgroundImageURLForState:UIControlStateNormal];
    }
    return url;
}

- (NSURL *)sd_backgroundImageURLForState:(UIControlState)state {
    return [self sd_imageLoadStateForKey:backgroundImageOperationKeyForState(state)].url;
}

- (NSProgress *)sd_backgroundImageProgressForState:(UIControlState)state {
    return [self sd_imageLoadStateForKey:backgroundImageOperationKeyForState(state)].progress;
}

- (void)sd_setBackgroundImageProgress:(NSProgress *)progress forState:(UIControlState)state {
    if (!progress) {
        return;
    }
    SDWebImageStateContainer *stateContainer = [self sd_imageLoadStateForKey:backgroundImageOperationKeyForState(state)];
    if (!stateContainer) {
        stateContainer = [SDWebImageStateContainer new];
    }
    stateContainer.progress = progress;
    [self sd_setImageLoadState:stateContainer forKey:nil];
    
}

- (SDWebImageTransition *)sd_backgroundImageTransitionForState:(UIControlState)state {
    return [self sd_imageLoadStateForKey:backgroundImageOperationKeyForState(state)].transition;
}

- (void)sd_setBackgroundImageTransition:(SDWebImageTransition *)transition forState:(UIControlState)state {
    if (!transition) {
        return;
    }
    SDWebImageStateContainer *stateContainer = [self sd_imageLoadStateForKey:backgroundImageOperationKeyForState(state)];
    if (!stateContainer) {
        stateContainer = [SDWebImageStateContainer new];
    }
    stateContainer.transition = transition;
    [self sd_setImageLoadState:stateContainer forKey:nil];
}

@end

#endif
