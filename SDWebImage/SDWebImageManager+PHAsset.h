/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_UIKIT

#import "SDWebImageManager.h"
#import <Photos/Photos.h>

@interface SDWebImageManager (PHAsset)

typedef void (^SDLocalPHAssetRetrievalCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType);


/**
 * Load image using PHImageManager with the given identifier if not present in cache or return the cached version otherwise
 *
 * @param identifier     The URL of the asset, which can be acquired from PHAsset using `localIdentifier`.
 * @param targetSize     The image size. Note this will also be used as part of cache key.
 * @param completedBlock A block called when query has been completed.
 */
- (void)loadImageWithPHAssetIdentifier:(nullable NSString *)identifier
                            targetSize:(CGSize)targetSize
                            completion:(nullable SDLocalPHAssetRetrievalCompletionBlock)completedBlock;

@end

#endif
