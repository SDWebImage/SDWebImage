//
//  MKAnnotationView+WebCache.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 14/03/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "MKAnnotationView+WebCache.h"
#import "UIView+WebCacheOperation.h"

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
        __weak MKAnnotationView  *wself    = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
            if (!wself) return;
            dispatch_main_sync_safe (^{
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
        [self setImageLoadOperation:operation forKey:@"MKAnnotationViewImage"];
    }
}

- (void)cancelCurrentImageLoad {
    [self cancelImageLoadOperation:@"MKAnnotationViewImage"];
}

@end
