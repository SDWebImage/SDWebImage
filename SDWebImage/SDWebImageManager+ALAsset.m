//
//  SDImageCache+ALAssets.m
//  SDWebImage
//
//  Created by skyline on 16/10/15.
//  Copyright © 2016年 Dailymotion. All rights reserved.
//

#import "SDWebImageManager+ALAsset.h"

#if SD_IOS

#import "objc/runtime.h"

typedef NS_ENUM(NSUInteger, SDLocalALAssetSize) {
    SDLocalALAssetSizeAspectThumbnail,
    SDLocalALAssetSizeSquareThumbnail,
    SDLocalALAssetSizeAspectFullscreen,
    SDLocalALAssetSizeAspectOriginal
};

static char SDLocalALAssetsLibraryPropertyKey;
static char SDLocalALAssetsAssetURLToAssetPropertyKey;

@implementation SDWebImageManager (ALAssets)

- (ALAssetsLibrary *)assetsLibrary {
    return objc_getAssociatedObject(self, &SDLocalALAssetsLibraryPropertyKey);
}

- (void)setAssetsLibrary:(ALAssetsLibrary *)assetsLibrary {
    objc_setAssociatedObject(self, &SDLocalALAssetsLibraryPropertyKey, assetsLibrary, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary<NSString *, ALAsset *> *)localAssetURLToAssetCache {
    return objc_getAssociatedObject(self, &SDLocalALAssetsAssetURLToAssetPropertyKey);
}

- (void)setLocalAssetURLToAssetCache:(NSMutableDictionary *)localAssetURLToAssetCache {
    objc_setAssociatedObject(self, &SDLocalALAssetsAssetURLToAssetPropertyKey, localAssetURLToAssetCache, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark -

- (SDLocalALAssetSize)localALAssetSizeForTargetSize:(CGSize)targetSize {

    /*

     ALAssetLibrary Thumbnail sizes come in the following flavors:

     iPhone:
     Thumbnail (Aspect):  120x90 or 90x120 (depending on aspect ratio)
     Thumbnail (Square):  150x150
     Fullscreen (Aspect): (screenWidth*screenScale)x(screenHeight*screenScale) or reverse (depending on aspect ratio)
     Original:            Anything > Fullscreen size

     iPad:
     Thumbnail (Aspect): 480x360 or 360x480 (depending on aspect ratio) < WTF, pretty big for thumbnail...
     Thumbnail (Square): 157x157 < WTF, small compared to aspect...
     Fullscreen (Aspect): (screenWidth*screenScale)x(screenHeight*screenScale) or reverse (depending on aspect ratio)
     Original:            Anything > Fullscreen size

     */

    CGFloat pixelsRequested = targetSize.width * targetSize.height;

    CGFloat thumbPixels;

    if (targetSize.width == targetSize.height) {
        thumbPixels = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? (157 * 157) : (150 * 150);
    } else {
        thumbPixels = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? (480 * 360) : (120 * 90);
    }

    CGFloat fullscreenPixels = (([UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale) * ([UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale));

    CGFloat thumbCutoff = thumbPixels * 2.0f; // Don't scale thumbnails more than 2x

    if (pixelsRequested <= thumbCutoff) {
        if (targetSize.width == targetSize.height) {
            return SDLocalALAssetSizeSquareThumbnail;
        } else {
            return SDLocalALAssetSizeAspectThumbnail;
        }
    } else if (pixelsRequested <= fullscreenPixels) {
        return SDLocalALAssetSizeAspectFullscreen;
    } else {
        return SDLocalALAssetSizeAspectOriginal;
    }
}

- (NSString *)cacheKeyForALAssetURL:(NSURL *)url targetSize:(CGSize)targetSize {

    NSString *urlString = nil;
    if ([url isKindOfClass:NSString.class]) {
        urlString = (NSString *)url;
    } else {
        urlString = url.absoluteString;
    }

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", urlString, NSStringFromCGSize(targetSize)];
    return cacheKey;
}

- (void)loadImageWithALAssetURL:(NSURL *)url
                     targetSize:(CGSize)targetSize
                     completion:(SDLocalALAssetRetrievalCompletionBlock)completedBlock {
    NSAssert(completedBlock != nil, @"Compelete block should not be nil");

    if (!self.assetsLibrary) {
        self.assetsLibrary = [ALAssetsLibrary new];
    }

    if (!self.localAssetURLToAssetCache) {
        self.localAssetURLToAssetCache = @{}.mutableCopy;
    }

    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    UIImage *image = [self.imageCache imageFromCacheForKey:[self cacheKeyForALAssetURL:url targetSize:targetSize]];
    if (image) {
        completedBlock(image, nil, SDImageCacheTypeMemory);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *cacheKey = [self cacheKeyForALAssetURL:url targetSize:targetSize];

        UIImage *returnImage;

        __block ALAsset *localAsset;
        localAsset = [self.localAssetURLToAssetCache valueForKey:cacheKey];

        if (!localAsset) {
            // Force the retrieval of the ALAsset to get retrieved from the ALAssetsLibrary synchronously using a semaphore
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [self.assetsLibrary assetForURL:url
                                    resultBlock:^(ALAsset *asset) {
                                        @autoreleasepool {
                                            if (asset) {
                                                localAsset = asset;
                                                @synchronized(self.localAssetURLToAssetCache) {
                                                    [self.localAssetURLToAssetCache setValue:asset forKey:url.absoluteString];
                                                }
                                            }
                                        }
                                        dispatch_semaphore_signal(sema);
                                    } failureBlock:^(NSError *error) {
                                        dispatch_semaphore_signal(sema);
                                    }];
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }

        if (localAsset) {
            // Intelligently choose the right ALAssetRepresentation based on the size requested
            switch ([self localALAssetSizeForTargetSize:targetSize]) {
                case SDLocalALAssetSizeAspectOriginal:
                    returnImage = [UIImage imageWithCGImage:localAsset.defaultRepresentation.fullResolutionImage];
                    break;

                case SDLocalALAssetSizeAspectFullscreen:
                    returnImage = [UIImage imageWithCGImage:localAsset.defaultRepresentation.fullScreenImage];
                    break;

                case SDLocalALAssetSizeSquareThumbnail:
                    returnImage = [UIImage imageWithCGImage:localAsset.thumbnail];
                    break;

                case SDLocalALAssetSizeAspectThumbnail:
                default:
                    returnImage = [UIImage imageWithCGImage:localAsset.aspectRatioThumbnail];
                    break;
            }

            if (returnImage) {
                [self.imageCache storeImage:returnImage forKey:cacheKey completion:nil];
            }

            dispatch_main_async_safe(^{
                completedBlock(returnImage, nil, SDImageCacheTypeNone);
            });

        } else {
            dispatch_main_async_safe(^{
                NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Cannot retrieve ALAsset"}];
                completedBlock(nil, error, SDImageCacheTypeNone);
            });
        }
    });
}

@end

#endif
