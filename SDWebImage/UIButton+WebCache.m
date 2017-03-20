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
#import "UIView+WebCache.h"

static char imageURLStorageKey;

typedef NSMutableDictionary<NSNumber *, NSURL *> SDStateImageURLDictionary;

@implementation UIButton (WebCache)

- (nullable NSURL *)sd_currentImageURL {
    NSURL *url = self.imageURLStorage[@(self.state)];

    if (!url) {
        url = self.imageURLStorage[@(UIControlStateNormal)];
    }

    return url;
}

- (nullable NSURL *)sd_imageURLForState:(UIControlState)state {
    return self.imageURLStorage[@(state)];
}

#pragma mark - Image

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url
                  forState:(UIControlState)state
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                 completed:(nullable SDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:@(state)];
        return;
    }
    
    self.imageURLStorage[@(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

#pragma mark - Background image

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url forState:(UIControlState)state placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)sd_setBackgroundImageWithURL:(nullable NSURL *)url
                            forState:(UIControlState)state
                    placeholderImage:(nullable UIImage *)placeholder
                             options:(SDWebImageOptions)options
                           completed:(nullable SDExternalCompletionBlock)completedBlock {
    if (!url) {
        [self.imageURLStorage removeObjectForKey:@(state)];
        return;
    }
    
    self.imageURLStorage[@(state)] = url;
    
    __weak typeof(self)weakSelf = self;
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           [weakSelf setBackgroundImage:image forState:state];
                       }
                            progress:nil
                           completed:completedBlock];
}

- (void)sd_setImageLoadOperation:(id<SDWebImageOperation>)operation forState:(UIControlState)state {
    [self sd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)sd_cancelImageLoadForState:(UIControlState)state {
    [self sd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)sd_setBackgroundImageLoadOperation:(id<SDWebImageOperation>)operation forState:(UIControlState)state {
    [self sd_setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (void)sd_cancelBackgroundImageLoadForState:(UIControlState)state {
    [self sd_cancelImageLoadOperationWithKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (SDStateImageURLDictionary *)imageURLStorage {
    SDStateImageURLDictionary *storage = objc_getAssociatedObject(self, &imageURLStorageKey);
    if (!storage) {
        storage = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &imageURLStorageKey, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return storage;
}

@end

#endif
