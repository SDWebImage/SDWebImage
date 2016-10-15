//
//  SDImageCache+ALAssets.h
//  SDWebImage
//
//  Created by skyline on 16/10/15.
//  Copyright © 2016年 Dailymotion. All rights reserved.
//

#import "SDWebImageCompat.h"

#if SD_IOS

#import "SDWebImageManager.h"
#import <AssetsLibrary/AssetsLibrary.h>

typedef void (^SDLocalALAssetRetrievalCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType);

@interface SDWebImageManager (ALAsset)


/**
 * Load image from ALAssetsLibaray using the given URL if not present in cache or return the cached version otherwise.
 *
 * @param url            The URL of the asset, which can be acquired from ALAsset using `ALAssetPropertyAssetURL`.
 * @param targetSize     The image size. Note this will also be used as part of cache key.
 * @param completedBlock A block called when query has been completed.
 */
- (void)loadImageWithALAssetURL:(nullable NSURL *)url
                     targetSize:(CGSize)targetSize
                     completion:(nullable SDLocalALAssetRetrievalCompletionBlock)completedBlock;

@end

#endif
