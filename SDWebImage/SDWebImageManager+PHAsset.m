/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageManager+PHAsset.h"

#ifdef SD_UIKIT

#import "objc/runtime.h"

static char SDLocalPHImageManagerPropertyKey;
static char SDLocalPHAssetAssetIdentifierToAssetPropertyKey;

@implementation SDWebImageManager (PHAsset)

- (PHImageManager *)imageManager {
    return objc_getAssociatedObject(self, &SDLocalPHImageManagerPropertyKey);
}

- (void)setImageManager:(PHImageManager *)imageManager {
    objc_setAssociatedObject(self, &SDLocalPHImageManagerPropertyKey, imageManager, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary<NSString *, PHAsset *> *)localAssetIdentifierToAssetCache {
    return objc_getAssociatedObject(self, &SDLocalPHAssetAssetIdentifierToAssetPropertyKey);
}

- (void)setLocalAssetIdentifierToAssetCache:(NSMutableDictionary *)localAssetIdentifierToAssetCache {
    objc_setAssociatedObject(self, &SDLocalPHAssetAssetIdentifierToAssetPropertyKey, localAssetIdentifierToAssetCache, OBJC_ASSOCIATION_RETAIN);
}

#pragma mark -

- (NSString *)cacheKeyForPHAssetIdentifier:(NSString *)localIdentifier targetSize:(CGSize)targetSize {

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", localIdentifier, NSStringFromCGSize(targetSize)];

    return cacheKey;
}

- (void)loadImageWithPHAssetIdentifier:(NSString *)localIdentifier
                                                         targetSize:(CGSize)targetSize
                                                         completion:(SDLocalPHAssetRetrievalCompletionBlock)completedBlock {
    NSAssert(completedBlock != nil, @"Compelete block should not be nil");

    if (!self.imageManager) {
        self.imageManager = [PHImageManager defaultManager];
    }

    UIImage *image = [self.imageCache imageFromCacheForKey:[self cacheKeyForPHAssetIdentifier:localIdentifier targetSize:targetSize]];
    if (image) {
        completedBlock(image, nil, SDImageCacheTypeMemory);
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *cacheKey = [self cacheKeyForPHAssetIdentifier:localIdentifier targetSize:targetSize];

        void (^fetchImageBlock)() = ^(PHAsset *asset){
            PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
            requestOptions.version = PHImageRequestOptionsVersionCurrent;
            requestOptions.synchronous = YES;
            requestOptions.networkAccessAllowed = YES;
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            requestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;

            [self.imageManager requestImageForAsset:asset
                                         targetSize:targetSize
                                        contentMode:PHImageContentModeAspectFit
                                            options:requestOptions
                                      resultHandler:^(UIImage *result, NSDictionary *info) {
                                          if (result && info[PHImageResultIsDegradedKey] && ![info[PHImageResultIsDegradedKey] boolValue]) {
                                              [self.imageCache storeImage:result forKey:cacheKey completion:nil];
                                          }

                                          if (completedBlock) {
                                              dispatch_main_async_safe(^{
                                                  completedBlock(result, nil, SDImageCacheTypeNone);
                                              });
                                          }
                                      }];

        };

        PHAsset *localAsset = nil;
        localAsset = [self.localAssetIdentifierToAssetCache valueForKey:cacheKey];

        if (localAsset) {
            fetchImageBlock(localAsset);
        } else {
            PHFetchOptions *fetchOptions = [PHFetchOptions new];
            fetchOptions.includeHiddenAssets = YES;

            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:fetchOptions];

            if (fetchResult.count) {
                PHAsset *result = fetchResult.firstObject;
                @synchronized(self.localAssetIdentifierToAssetCache) {
                    [self.localAssetIdentifierToAssetCache setValue:result forKey:result.localIdentifier];
                }
                fetchImageBlock(fetchResult.firstObject);
            } else {
                if (completedBlock) {
                    NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey : @"Cannot retrieve PHAsset"}];
                    dispatch_main_async_safe(^{
                        completedBlock(nil, error, SDImageCacheTypeNone);
                    });
                }
            }
        }
    });
}

@end

#endif
