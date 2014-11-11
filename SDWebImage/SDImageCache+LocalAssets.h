//
//  SDImageCache+LocalAssets.h
//  Pods
//
//  Created by Don Holly on 9/19/14.
//
//

#import "SDImageCache.h"

// iOS 7 and lower
#import <AssetsLibrary/AssetsLibrary.h>

// iOS 8+
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
#import <Photos/Photos.h>
#endif

typedef void (^SDImageCacheLocalAssetRetrievalCompletionBlock)(UIImage *image, SDImageCacheType cacheType);

@interface SDImageCache (LocalAssets)

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
@property (nonatomic) PHImageRequestOptionsDeliveryMode phImageRequestDeliveryMode;
@property (nonatomic) PHImageRequestOptionsResizeMode phImageRequestResizeMode;
#endif

/**
 * Call this to warm the ALAsset / PHAsset lookup cache (for faster image retrieval later)
 */

- (void)warmLocalAssetCache;

/**
 * Helpers for identifying a Local Asset URL (ALAsset or PHAsset identifier)
 */

+ (NSNumber *)isLocalAssetIdentifier:(id)identifier;

+ (BOOL)isALAssetURL:(id)assetURL;

+ (BOOL)isPHAssetLocalIdentifier:(id)localIdentifier;

/**
 * Helper for generating a cache key for local assets
 */

+ (NSString *)cacheKeyForLocalAssetIdentifier:(id)localAssetIdentifier andTargetSize:(CGSize)targetSize;

/**
 * Query the system's local asset managers (ALAssetsLibrary or PHImageManager) for an image asynchronously
 *
 * @param assetIdentifier   an ALAsset URL (assets-library:// or PHAsset localIdentifier)
 * @param targetSize        the size of the image ideally returned (will not be resized if it doesn't match)
 */

- (NSOperation *)queryLocalAssetStoreWithLocalAssetIdentifier:(id)assetIdentifier
                                                   targetSize:(CGSize)targetSize
                                              completionBlock:(SDImageCacheLocalAssetRetrievalCompletionBlock)completionBlock;

@end
