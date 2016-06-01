/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import "FLAnimatedImageView+WebCache.h"
#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "NSData+ImageContentType.h"
#import "FLAnimatedImage.h"
#import "UIImageView+WebCache.h"

static char imageURLKey;


@implementation FLAnimatedImageView (WebCache)

- (NSURL *)sd_imageURL {
    return objc_getAssociatedObject(self, &imageURLKey);
}

- (void)sd_setAnimatedImageWithURL:(NSURL *)url {
    [self sd_setAnimatedImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)sd_setAnimatedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self sd_setAnimatedImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)sd_setAnimatedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setAnimatedImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setAnimatedImageWithURL:(NSURL *)url completed:(SDExternalCompletionBlock)completedBlock {
    [self sd_setAnimatedImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)sd_setAnimatedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDExternalCompletionBlock)completedBlock {
    [self sd_setAnimatedImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)sd_setAnimatedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDExternalCompletionBlock)completedBlock {
    [self sd_setAnimatedImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setAnimatedImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options progress:(SDWebImageDownloaderProgressBlock)progressBlock completed:(SDExternalCompletionBlock)completedBlock {
    [self sd_cancelCurrentAnimatedImageLoad];
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (!(options & SDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            self.image = placeholder;
        });
    }
    
    if (url) {
        // check if activityView is enabled or not
        if ([self showActivityIndicatorView]) {
            [self addActivityIndicator];
        }
        
        __weak __typeof(self)wself = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager loadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                [wself removeActivityIndicator];
                
                if (!wself) return;
                if (image && (options & SDWebImageAvoidAutoSetImage) && completedBlock) {
                    completedBlock(image, error, cacheType, url);
                    return;
                } else if (image) {
                    NSString *imageContentType = [NSData sd_contentTypeForImageData:data];
                    if ([imageContentType isEqualToString:@"image/gif"]) {
                        wself.animatedImage = [FLAnimatedImage animatedImageWithGIFData:data];
                        wself.image = nil;
                    } else {
                        wself.image = image;
                        wself.animatedImage = nil;
                    }
                    [wself setNeedsLayout];
                } else {
                    if ((options & SDWebImageDelayPlaceholder)) {
                        wself.image = placeholder;
                        [wself setNeedsLayout];
                    }
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, url);
                }
            });
        }];
        [self sd_setImageLoadOperation:operation forKey:@"UIImageViewAnimatedImageLoad"];
    } else {
        dispatch_main_async_safe(^{
            [self removeActivityIndicator];
            
            if (completedBlock) {
                NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
                completedBlock(nil, error, SDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)sd_cancelCurrentAnimatedImageLoad {
    [self sd_cancelImageLoadOperationWithKey:@"UIImageViewAnimatedImageLoad"];
}


@end
