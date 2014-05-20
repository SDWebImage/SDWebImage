/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+WebCache.h"
#import "objc/runtime.h"

static char operationKey;

@implementation UIButton (WebCache)

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self setImageWithURL:url forState:state imageManager:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state imageManager:(SDWebImageManager *)imageManager {
    [self setImageWithURL:url forState:state placeholderImage:nil options:0 imageManager:imageManager completed:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self setImageWithURL:url forState:state placeholderImage:placeholder imageManager:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder imageManager:(SDWebImageManager *)imageManager {
    [self setImageWithURL:url forState:state placeholderImage:placeholder options:0 imageManager:imageManager completed:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setImageWithURL:url forState:state placeholderImage:placeholder options:options imageManager:nil completed:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url forState:state placeholderImage:nil options:0 imageManager:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url forState:state placeholderImage:placeholder options:0 imageManager:nil completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options imageManager:(SDWebImageManager *)imageManager completed:(SDWebImageCompletedBlock)completedBlock {
    [self cancelCurrentImageLoad];

    [self setImage:placeholder forState:state];

    if (url) {
        if (!imageManager) {
            imageManager = SDWebImageManager.sharedManager;
        }
        __weak UIButton *wself = self;
        id <SDWebImageOperation> operation = [imageManager downloadWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong UIButton *sself = wself;
                if (!sself) return;
                if (image) {
                    [sself setImage:image forState:state];
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType);
                }
            });
        }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self setBackgroundImageWithURL:url forState:state imageManager:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state imageManager:(SDWebImageManager *)imageManager {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 imageManager:imageManager completed:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:placeholder imageManager:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder imageManager:(SDWebImageManager *)imageManager {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 imageManager:imageManager completed:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options imageManager:nil completed:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(SDWebImageCompletedBlock)completedBlock {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 imageManager:nil completed:completedBlock];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 imageManager:nil completed:completedBlock];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options imageManager:(SDWebImageManager *)imageManager completed:(SDWebImageCompletedBlock)completedBlock {
    [self cancelCurrentImageLoad];

    [self setBackgroundImage:placeholder forState:state];

    if (url) {
        if (!imageManager) {
            imageManager = SDWebImageManager.sharedManager;
        }
        __weak UIButton *wself = self;
        id <SDWebImageOperation> operation = [imageManager downloadWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong UIButton *sself = wself;
                if (!sself) return;
                if (image) {
                    [sself setBackgroundImage:image forState:state];
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType);
                }
            });
        }];
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}


- (void)cancelCurrentImageLoad {
    // Cancel in progress downloader from queue
    id <SDWebImageOperation> operation = objc_getAssociatedObject(self, &operationKey);
    if (operation) {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
