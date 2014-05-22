/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIButton+WebCache.h"
#import "UIView+WebCacheOperation.h"
#import "objc/runtime.h"

@implementation UIButton (WebCache)

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self setImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self cancelBackgroundImageLoadForState:state];

    [self setImage:placeholder forState:state];

    if (url) {
        __weak UIButton          *wself    = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (!wself) return;
            dispatch_main_sync_safe (^{
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
        [self setBackgroundImageLoadOperation:operation forState:state];
    }
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:options completed:nil];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(SDWebImageCompletedBlock)completedBlock {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:nil options:0 completed:completedBlock];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self setBackgroundImageWithURL:url forState:state placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self cancelImageLoadForState:state];

    [self setBackgroundImage:placeholder forState:state];

    if (url) {
        __weak UIButton          *wself    = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (!wself) return;
            dispatch_main_sync_safe (^{
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
        [self setImageLoadOperation:operation forState:state];
    }
}

- (void)setImageLoadOperation:(id<SDWebImageOperation>)operation forState:(UIControlState)state {
    [self setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)cancelImageLoadForState:(UIControlState)state {
    [self cancelImageLoadOperation:[NSString stringWithFormat:@"UIButtonImageOperation%@", @(state)]];
}

- (void)setBackgroundImageLoadOperation:(id<SDWebImageOperation>)operation forState:(UIControlState)state {
    [self setImageLoadOperation:operation forKey:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

- (void)cancelBackgroundImageLoadForState:(UIControlState)state {
    [self cancelImageLoadOperation:[NSString stringWithFormat:@"UIButtonBackgroundImageOperation%@", @(state)]];
}

@end
