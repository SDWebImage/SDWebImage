//
//  MKAnnotationView+WebCache.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 14/03/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "MKAnnotationView+WebCache.h"
#import "objc/runtime.h"

static char operationKey;

@implementation MKAnnotationView (WebCache)

- (void)setImageWithURL:(NSURL *)url {
    [self setImageWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self setImageWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setImageWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self cancelCurrentImageLoad];

    self.image = placeholder;

    if (url) {
        __weak MKAnnotationView *wself = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong MKAnnotationView *sself = wself;
                if (!sself) return;
                if (image) {
                    sself.image = image;
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
