//
//  UIImageView+msd_WebCache.m
//  vb
//
//  Created by 马权 on 3/17/16.
//  Copyright © 2016 maquan. All rights reserved.
//

#import "UIImageView+msd_WebCache.h"
#import "SDWebImageManager.h"
#import "MSDImageDownloadGroupManage.h"
#import "objc/runtime.h"

@interface UIImageView ()

@property (nonatomic, strong) NSURL *msd_imageURL;
@property (nonatomic, copy) NSString *msd_downloadGroupIdentifier;
@property (nonatomic, strong) id<SDWebImageOperation> msd_operation;

@end

@implementation UIImageView (msd_WebCache)

//  MARK: Public
- (void)msd_setImageWithURL:(NSURL *)url
{
    [self msd_setImageWithURL:url groupIdentifier:MSDImageDownloadDefaultGroupIdentifier placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)msd_setImageWithURL:(NSURL *)url
           groupIdentifier:(NSString *)identifier
{
    [self msd_setImageWithURL:url groupIdentifier:identifier placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)msd_setImageWithURL:(NSURL *)url
           groupIdentifier:(NSString *)identifier
          placeholderImage:(UIImage *)placeholder
                   options:(SDWebImageOptions)options
{
    [self msd_setImageWithURL:url groupIdentifier:identifier placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)msd_setImageWithURL:(NSURL *)url
                 completed:(SDWebImageCompletionBlock)completedBlock
{
    [self msd_setImageWithURL:url groupIdentifier:MSDImageDownloadDefaultGroupIdentifier placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)msd_setImageWithURL:(NSURL *)url
           groupIdentifier:(NSString *)identifier
                 completed:(SDWebImageCompletionBlock)completedBlock
{
    [self msd_setImageWithURL:url groupIdentifier:identifier placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)msd_setImageWithURL:(NSURL *)url
           groupIdentifier:(NSString *)identifier
          placeholderImage:(UIImage *)placeholder
                   options:(SDWebImageOptions)options
                 completed:(SDWebImageCompletionBlock)completedBlock
{
    [self msd_setImageWithURL:url groupIdentifier:identifier placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)msd_setImageWithURL:(NSURL *)url
           groupIdentifier:(NSString *)identifier
          placeholderImage:(UIImage *)placeholder
                   options:(SDWebImageOptions)options
                  progress:(SDWebImageDownloaderProgressBlock)progressBlock
                 completed:(SDWebImageCompletionBlock)completedBlock
{
    self.msd_imageURL = url;
    
    __weak typeof(self) weakSelf = self;
    if (!(options & SDWebImageDelayPlaceholder)) {
        dispatch_main_async_safe(^{
            if (!weakSelf) {
                return;
            }
            if ([weakSelf.msd_imageURL.absoluteString isEqualToString:url.absoluteString]) {
                weakSelf.image = placeholder;
            }
        });
    }
    
    if (url) {
        __weak typeof(self) weakSelf = self;
        __block id <SDWebImageOperation> operation = [[SDWebImageManager sharedManager] downloadImageWithURL:url options:options progress:progressBlock completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (operation && identifier) {
                    [[MSDImageDownloadGroupManage shareInstance] removeImageDownLoadOperation:operation fromGroup:identifier forKey:imageURL.absoluteString];
                }
                if (!weakSelf) {
                    return;
                }
                if ([weakSelf.msd_imageURL.absoluteString isEqualToString:imageURL.absoluteString]) {
                    weakSelf.msd_operation = nil;
                    weakSelf.msd_imageURL = nil;
                    weakSelf.msd_downloadGroupIdentifier = nil;
                    if (image) {
                        weakSelf.image = image;
                        [weakSelf setNeedsLayout];
                    }
                }
                if (completedBlock && finished) {
                    completedBlock(image, error, cacheType, imageURL);
                }
            });
        }];
        
        if (operation && identifier) {
            [[MSDImageDownloadGroupManage shareInstance] setImageDownLoadOperation:operation toGroup:identifier forKey:[url absoluteString]];
            self.msd_operation = operation;
            self.msd_downloadGroupIdentifier = identifier;
        }
    }
    else {
        dispatch_main_async_safe(^{
            NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"Trying to load a nil url"}];
            if (completedBlock) {
                completedBlock(nil, error, SDImageCacheTypeNone, url);
            }
        });
    }
}

- (void)msd_cancelCurrentImageDownload
{
    id<SDWebImageOperation> operation = [self msd_operation];
    if (!operation) {
        return;
    }
    [operation cancel];
    [[MSDImageDownloadGroupManage shareInstance] removeImageDownLoadOperation:operation fromGroup:self.msd_downloadGroupIdentifier forKey:self.msd_imageURL.absoluteString];
    self.msd_operation = nil;
    self.msd_imageURL = nil;
    self.msd_downloadGroupIdentifier = nil;
}

//  MARK: objc_setAssociatedObject
- (void)setMsd_imageURL:(NSURL *)msd_imageURL
{
    objc_setAssociatedObject(self, @selector(msd_imageURL), msd_imageURL, OBJC_ASSOCIATION_RETAIN);
}

- (NSURL *)msd_imageURL
{
    return objc_getAssociatedObject(self, @selector(msd_imageURL));
}

- (void)setMsd_downloadGroupIdentifier:(NSString *)msd_downloadGroupIdentifier
{
    objc_setAssociatedObject(self, @selector(msd_downloadGroupIdentifier), msd_downloadGroupIdentifier, OBJC_ASSOCIATION_COPY);
}

- (NSString *)msd_downloadGroupIdentifier
{
    return objc_getAssociatedObject(self, @selector(msd_downloadGroupIdentifier));
}

- (void)setMsd_operation:(id<SDWebImageOperation>)msd_operation
{
    objc_setAssociatedObject(self, @selector(msd_operation), msd_operation, OBJC_ASSOCIATION_RETAIN);
}

- (id<SDWebImageOperation>)msd_operation
{
    return objc_getAssociatedObject(self, @selector(msd_operation));
}

@end
