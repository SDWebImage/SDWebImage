/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImageView+WebCache.h"
#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "UIView+WebCache.h"

@implementation UIImageView (WebCache)

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
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

#if SD_UIKIT

#pragma mark - Animation of multiple images

- (void)sd_setAnimationImagesWithURLs:(nonnull NSArray<NSURL *> *)arrayOfURLs {
    return [self sd_setAnimationImagesWithURLs:arrayOfURLs progress:nil completed:nil];
}

- (void)sd_setAnimationImagesWithURLs:(nonnull NSArray<NSURL *> *)arrayOfURLs progress:(nullable SDImageBatchProgressBlock)progressBlock completed:(nullable SDImageBatchCompletionBlock)completedBlock {
    [self sd_cancelCurrentAnimationImagesLoad];
    NSPointerArray *operationsArray = [self sd_animationOperationArray];
    
    NSUInteger totalCount = arrayOfURLs.count;
    if (totalCount == 0) {
        if (completedBlock) {
            completedBlock(0, 0);
        }
        return;
    }
    
    __block NSUInteger finishedCount = 0;
    __block NSUInteger skippedCount = 0;
    [arrayOfURLs enumerateObjectsUsingBlock:^(NSURL *logoImageURL, NSUInteger idx, BOOL * _Nonnull stop) {
        __weak __typeof(self) wself = self;
        id <SDWebImageOperation> operation = [[SDWebImageManager sharedManager] loadImageWithURL:logoImageURL options:0 progress:nil completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            __strong typeof(wself) sself = wself;
            if (!sself) {
                return;
            }
            if (!finished) {
                return;
            }
            dispatch_main_async_safe(^{
                finishedCount++;
                if (image) {
                    [sself stopAnimating];
                    NSMutableArray<UIImage *> *currentImages = [[sself animationImages] mutableCopy];
                    if (!currentImages) {
                        currentImages = [[NSMutableArray alloc] init];
                    }
                    
                    // We know what index objects should be at when they are returned so
                    // we will put the object at the index, filling any empty indexes
                    // with the image that was returned too "early". These images will
                    // be overwritten. (does not require additional sorting datastructure)
                    while ([currentImages count] < idx) {
                        [currentImages addObject:image];
                    }
                    
                    currentImages[idx] = image;

                    sself.animationImages = currentImages;
                    [sself setNeedsLayout];
                    [sself startAnimating];
                } else {
                    skippedCount++;
                }
                // Current operation finished
                if (progressBlock) {
                    progressBlock(finishedCount, totalCount);
                }
                
                // All finished
                if (finishedCount == totalCount) {
                    if (completedBlock) {
                        completedBlock(finishedCount, skippedCount);
                    }
                }
            });
        }];
        @synchronized (self) {
            [operationsArray addPointer:(__bridge void *)(operation)];
        }
    }];
}

static char animationLoadOperationKey;

// element is weak because operation instance is retained by SDWebImageManager's runningOperations property
// we should use lock to keep thread-safe because these method may not be acessed from main queue
- (NSPointerArray *)sd_animationOperationArray {
    @synchronized(self) {
        NSPointerArray *operationsArray = objc_getAssociatedObject(self, &animationLoadOperationKey);
        if (operationsArray) {
            return operationsArray;
        }
        operationsArray = [NSPointerArray weakObjectsPointerArray];
        objc_setAssociatedObject(self, &animationLoadOperationKey, operationsArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operationsArray;
    }
}

- (void)sd_cancelCurrentAnimationImagesLoad {
    NSPointerArray *operationsArray = [self sd_animationOperationArray];
    if (operationsArray) {
        @synchronized (self) {
            for (id operation in operationsArray) {
                if ([operation conformsToProtocol:@protocol(SDWebImageOperation)]) {
                    [operation cancel];
                }
            }
            operationsArray.count = 0;
        }
    }
}
#endif

@end
