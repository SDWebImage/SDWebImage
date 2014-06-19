//
//  MKAnnotationView+WebCache.m
//  SDWebImage
//
//  Created by Olivier Poitrey on 14/03/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "MKAnnotationView+WebCache.h"
#import "objc/runtime.h"

static char imageURLKey;
static char operationKey;

@implementation MKAnnotationView (WebCache)

- (NSURL *)imageURL;
{
    return objc_getAssociatedObject(self, &imageURLKey);
}

- (void)setImageWithURL:(NSURL *)url
{
    [self setImageAndReturnURLWithURL:url placeholderImage:nil options:0 completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [self setImageAndReturnURLWithURL:url placeholderImage:placeholder options:0 completed:nil];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options {
    [self setImageAndReturnURLWithURL:url placeholderImage:placeholder options:options completed:nil];
}

- (void)setImageWithURL:(NSURL *)url completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageAndReturnURLWithURL:url placeholderImage:nil options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        completedBlock(image,error,cacheType);
    }];
}
- (void)setImageAndReturnURLWithURL:(NSURL *)url completed:(setImageAndReturnURLWithURL)completedBlock {
    [self setImageAndReturnURLWithURL:url placeholderImage:nil options:0 completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageAndReturnURLWithURL:url placeholderImage:placeholder options:0 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        completedBlock(image,error,cacheType);
    }];
}
- (void)setImageAndReturnURLWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageWithURLCompletedBlock)completedBlock {
    [self setImageAndReturnURLWithURL:url placeholderImage:placeholder options:0 completed:completedBlock];
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder options:(SDWebImageOptions)options completed:(SDWebImageCompletedBlock)completedBlock {
    [self setImageAndReturnURLWithURL:url placeholderImage:placeholder options:options completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        completedBlock(image,error,cacheType);
    }];
}
- (void)setImageAndReturnURLWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder completed:(SDWebImageWithURLCompletedBlock)completedBlock {
    [self cancelCurrentImageLoad];
    
    objc_setAssociatedObject(self, &imageURLKey, url, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.image = placeholder;
    
    if (url) {
        __weak MKAnnotationView *wself = self;
        id <SDWebImageOperation> operation = [SDWebImageManager.sharedManager downloadImageWithURL:url options:options progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished,NSURL* imageURL) {
            if (!wself) return;
            dispatch_main_sync_safe(^{
                __strong MKAnnotationView *sself = wself;
                if (!sself) return;
                if (image) {
                    sself.image = image;
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType,imageURL);
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
