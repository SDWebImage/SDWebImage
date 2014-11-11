//
//  SDImageCache+LocalAssets.m
//  Pods
//
//  Created by Don Holly on 9/19/14.
//
//

#import "SDImageCache+LocalAssets.h"

#if defined(TARGET_OS_IPHONE)

static char SDImageCacheALAssetsLibraryPropertyKey;
static char SDImageCacheLocalAssetURLToAssetPropertyKey;
static char SDImageCachePHImageManagerPropertyKey;
static char SDImageCachePHImageRequestDeliveryModeKey;
static char SDImageCachePHImageRequestResizeModeKey;

#import <objc/runtime.h>

typedef NS_ENUM(NSUInteger, SDLocalALAssetSize) {
    SDLocalALAssetSizeAspectThumbnail,
    SDLocalALAssetSizeSquareThumbnail,
    SDLocalALAssetSizeAspectFullscreen,
    SDLocalALAssetSizeAspectOriginal
};

@interface SDImageCache ()
@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@property (nonatomic, strong) NSMutableDictionary *localAssetIdentifierToAssetCache;

#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
@property (nonatomic, strong) PHImageManager *imageManager;
#endif

@end

#endif

@implementation SDImageCache (LocalAssets)

#pragma mark - Property getters/setters -

- (ALAssetsLibrary *)assetsLibrary {
    ALAssetsLibrary *assetsLibrary = objc_getAssociatedObject(self, &SDImageCacheALAssetsLibraryPropertyKey);
    return assetsLibrary;
}

- (void)setAssetsLibrary:(ALAssetsLibrary *)assetsLibrary {
    objc_setAssociatedObject(self, &SDImageCacheALAssetsLibraryPropertyKey, assetsLibrary, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableDictionary *)localAssetIdentifierToAssetCache {
    NSMutableDictionary *localAssetIdentifierToAssetCache = objc_getAssociatedObject(self, &SDImageCacheLocalAssetURLToAssetPropertyKey);
    return localAssetIdentifierToAssetCache;
}

- (void)setLocalAssetIdentifierToAssetCache:(NSMutableDictionary *)localAssetIdentifierToAssetCache {
    objc_setAssociatedObject(self, &SDImageCacheLocalAssetURLToAssetPropertyKey, localAssetIdentifierToAssetCache, OBJC_ASSOCIATION_RETAIN);
}

- (PHImageManager *)imageManager {
    PHImageManager *imageManager = objc_getAssociatedObject(self, &SDImageCachePHImageManagerPropertyKey);
    return imageManager;
}

- (void)setImageManager:(PHImageManager *)imageManager {
    objc_setAssociatedObject(self, &SDImageCachePHImageManagerPropertyKey, imageManager, OBJC_ASSOCIATION_RETAIN);
}

- (PHImageRequestOptionsDeliveryMode)phImageRequestDeliveryMode {
    NSNumber *deliveryMode = objc_getAssociatedObject(self, &SDImageCachePHImageRequestDeliveryModeKey);
    
    if (!deliveryMode) {
        deliveryMode = @(PHImageRequestOptionsDeliveryModeOpportunistic);
    }
    
    return (PHImageRequestOptionsDeliveryMode)deliveryMode.integerValue;
}

- (void)setPhImageRequestDeliveryMode:(PHImageRequestOptionsDeliveryMode)phImageRequestDeliveryMode {
    objc_setAssociatedObject(self, &SDImageCachePHImageRequestDeliveryModeKey, @(phImageRequestDeliveryMode), OBJC_ASSOCIATION_RETAIN);
}

- (PHImageRequestOptionsResizeMode)phImageRequestResizeMode {
    NSNumber *resizeMode = objc_getAssociatedObject(self, &SDImageCachePHImageRequestResizeModeKey);
    
    if (!resizeMode) {
        resizeMode = @(PHImageRequestOptionsResizeModeFast);
    }
    
    return (PHImageRequestOptionsResizeMode)resizeMode.integerValue;
}

- (void)setPhImageRequestResizeMode:(PHImageRequestOptionsResizeMode)phImageRequestResizeMode {
    objc_setAssociatedObject(self, &SDImageCachePHImageRequestResizeModeKey, @(phImageRequestResizeMode), OBJC_ASSOCIATION_RETAIN);
}

#pragma mark - Helpers -

- (void)warmLocalAssetCache {
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        [self warmPHAssetsLibrary];
    } else {
        [self warmALAssetsLibrary];   
    }
}

- (void)warmALAssetsLibrary {

    if (!self.assetsLibrary) {
        self.assetsLibrary = [ALAssetsLibrary new];
    }
    
    if (!self.localAssetIdentifierToAssetCache) {
        self.localAssetIdentifierToAssetCache = [NSMutableDictionary dictionary];
    }
    
    ALAuthorizationStatus currentStatus = [ALAssetsLibrary authorizationStatus];
    if (currentStatus != ALAuthorizationStatusAuthorized) {
        return;
    }
    
    dispatch_async(self.ioQueue, ^ {
        
        // NOTE: This currently only indexes the Camera Roll, not additional albums or other image stores on the device
        [self.assetsLibrary
         enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
         usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
             @autoreleasepool {
                 [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                 
                 if (group != nil) {
                     
                     [group enumerateAssetsWithOptions:NSEnumerationConcurrent
                                            usingBlock:^(ALAsset *result, NSUInteger index, BOOL *shouldStop) {
                                                @autoreleasepool {
                                                    if (result != NULL) {
                                                        if ([[result valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
                                                            @synchronized(self.localAssetIdentifierToAssetCache) {
                                                                // Create a mapping of the ALAssets so we can retrieve them quickly without polling the ALAssetsLibrary each time
                                                                NSString *assetURL = ((NSURL *)[result valueForProperty:ALAssetPropertyAssetURL]).absoluteString;
                                                                [self.localAssetIdentifierToAssetCache setValue:result forKey:assetURL];
                                                            }
                                                        }
                                                    } else {
                                                        // NSLog(@"Finished indexing of local assets");
                                                    }
                                                }
                                            }];
                 }
             }
         } failureBlock:^(NSError *error) {
             
         }];
        
    });
}

- (void)warmPHAssetsLibrary {
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        
        PHAuthorizationStatus currentStatus = [PHPhotoLibrary authorizationStatus];
        if (currentStatus != PHAuthorizationStatusAuthorized) {
            return;
        }
        
        dispatch_async(self.ioQueue, ^ {
            
            if (!self.imageManager) {
                self.imageManager = [PHImageManager new];
            }
            
            if (!self.localAssetIdentifierToAssetCache) {
                self.localAssetIdentifierToAssetCache = [NSMutableDictionary dictionary];
            }
            
            PHFetchOptions *options = [PHFetchOptions new];
            options.includeAllBurstAssets = YES;
            options.includeHiddenAssets = YES;
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage
                                                                   options:options];
            
            [fetchResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
                
                if (asset) {
                    @synchronized(fetchResult) {
                        NSString *assetIdentifier = asset.localIdentifier;
                        if (assetIdentifier) {
                            self.localAssetIdentifierToAssetCache[assetIdentifier] = asset;
                        }
                    }
                }
                
            }];
        });
        
    }
    
}

+ (NSNumber *)isLocalAssetIdentifier:(id)identifier {
    
    if ([self isALAssetURL:identifier]) {
        return @YES;
    } else {
        return [self isPHAssetLocalIdentifier:identifier] ? @YES : @NO;
    }
}

+ (BOOL)isALAssetURL:(id)assetURL {
    // ALAsset URLs start with the scheme 'assets-library://'
    
    NSString *url = nil;
    
    if ([assetURL isKindOfClass:[NSURL class]]) {
        url = [assetURL absoluteString];
    } else if ([assetURL isKindOfClass:[NSString class]]) {
        url = assetURL;
    }
    
    BOOL ALAssetURL = [url rangeOfString:@"assets-library"].location != NSNotFound;
    
    return ALAssetURL;
}

+ (BOOL)isPHAssetLocalIdentifier:(id)localIdentifier {
    
    NSString *identifier = nil;
    
    if ([localIdentifier isKindOfClass:[NSURL class]]) {
        identifier = [localIdentifier absoluteString];
    } else if ([localIdentifier isKindOfClass:[NSString class]]) {
        identifier = localIdentifier;
    }
    
    // PHAsset localIdentifiers have /L##/### in them (this could likely be improved upon?)
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"/L[0-9]/[0-9][0-9][0-9]"
                                  options:0
                                  error:nil];
    NSRange range = [regex rangeOfFirstMatchInString:identifier
                                             options:0
                                               range:NSMakeRange(0, [identifier length])];
    BOOL PHAssetURL = (range.location != NSNotFound);
    
    return PHAssetURL;
}

+ (SDLocalALAssetSize)localALAssetSizeForTargetSize:(CGSize)targetSize {

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
    CGFloat fullscreenCutoff = fullscreenPixels * 1.50f;
    
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

+ (NSString *)cacheKeyForLocalAssetIdentifier:(id)localAssetIdentifier andTargetSize:(CGSize)targetSize {
    
    NSString *url = nil;
    
    if ([localAssetIdentifier isKindOfClass:[NSURL class]]) {
        url = [localAssetIdentifier absoluteString];
    } else if ([localAssetIdentifier isKindOfClass:[NSString class]]) {
        url = localAssetIdentifier;
    }
    
    NSString *cacheKey = [NSString stringWithFormat:@"%@:%@", url, NSStringFromCGSize(targetSize)];
    
    return cacheKey;
}

#pragma mark - Image Fetching -

- (NSOperation *)queryLocalAssetStoreWithLocalAssetIdentifier:(id)assetIdentifier
                                                   targetSize:(CGSize)targetSize
                                              completionBlock:(SDImageCacheLocalAssetRetrievalCompletionBlock)completionBlock {
    
    if (!completionBlock) return nil;
    
    if (!assetIdentifier) {
        completionBlock(nil, SDImageCacheTypeNone);
        return nil;
    }
    
    if (!self.assetsLibrary) {
        self.assetsLibrary = [ALAssetsLibrary new];
    }
    
    if (!self.localAssetIdentifierToAssetCache) {
        self.localAssetIdentifierToAssetCache = @{}.mutableCopy;
    }
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        if (!self.imageManager) {
            self.imageManager = [PHImageManager new];
        }
    }
    
    // Normalize identifier to a NSURL (we'll convert later if we need to based on which local asset store we use)
    NSString *assetURL;
    if ([assetIdentifier isKindOfClass:[NSString class]]) {
        assetURL = assetIdentifier;
    } else {
        assetURL = [assetIdentifier absoluteString];
    }
    
    UIImage *image = [self imageFromMemoryCacheForKey:[SDImageCache cacheKeyForLocalAssetIdentifier:assetURL andTargetSize:targetSize]];
    if (image) {
        completionBlock(image, SDImageCacheTypeMemory);
        return nil;
    }
    
    NSOperation *operation = nil;
    
    // Dispatch to the appropriate local store
    if ([SDImageCache isALAssetURL:assetURL]) {
        operation = [self fetchImageFromAssetsLibraryWithAssetURL:[NSURL URLWithString:assetURL] targetSize:targetSize completionBlock:completionBlock];
    } else if ([SDImageCache isPHAssetLocalIdentifier:assetURL]) {
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
            operation = [self fetchImageFromPhotoLibraryWithLocalIdentifier:assetURL targetSize:targetSize completionBlock:completionBlock];
        }
    }
    
    return operation;
}

- (NSOperation *)fetchImageFromAssetsLibraryWithAssetURL:(NSURL *)assetURL
                                              targetSize:(CGSize)targetSize
                                         completionBlock:(SDImageCacheLocalAssetRetrievalCompletionBlock)completionBlock {
    
    NSOperation *operation = [NSOperation new];
    
    dispatch_async(self.ioQueue, ^{
        
        if (operation.isCancelled) {
            return;
        }
        
        NSString *cacheKey = [SDImageCache cacheKeyForLocalAssetIdentifier:assetURL andTargetSize:targetSize];
        
        UIImage *returnImage;
        
        __block ALAsset *localAsset;
        localAsset = [self.localAssetIdentifierToAssetCache valueForKey:cacheKey];
        
        if (!localAsset) {
            // Force the retrieval of the ALAsset to get retrieved from the ALAssetsLibrary synchronously using a semaphore
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [self.assetsLibrary assetForURL:assetURL
                                    resultBlock:^(ALAsset *asset) {
                                        @autoreleasepool {
                                            if (asset) {
                                                localAsset = asset;
                                                
                                                @synchronized(self.localAssetIdentifierToAssetCache) {
                                                    // this Asset wasn't previous in our cache, add it for use later
                                                    [self.localAssetIdentifierToAssetCache setValue:asset forKey:cacheKey];
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
            
            if (operation.isCancelled) {
                return;
            }
            
            // Intelligently choose the right ALAssetRepresentation based on the size requested
            switch ([SDImageCache localALAssetSizeForTargetSize:targetSize]) {
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
                CGFloat cost = returnImage.size.height * returnImage.size.width * returnImage.scale;
                [self.memCache setObject:returnImage
                                  forKey:cacheKey
                                    cost:cost];
            }
            
            
            if (operation.isCancelled) {
                return;
            }
            
            dispatch_main_sync_safe(^{
                completionBlock(returnImage, SDImageCacheTypeLocalAssetStore);
            });
            
        } else {
            dispatch_main_sync_safe(^{
                completionBlock(nil, SDImageCacheTypeNone);
            });
        }
    });
    
    return operation;
}

- (NSOperation *)fetchImageFromPhotoLibraryWithLocalIdentifier:(NSString *)localIdentifier
                                                    targetSize:(CGSize)targetSize
                                               completionBlock:(SDImageCacheLocalAssetRetrievalCompletionBlock)completionBlock {
    
    NSBlockOperation *operation = [NSBlockOperation new];
    
    dispatch_async(self.ioQueue, ^{
        
        if (operation.isCancelled) {
            return;
        }
        
        NSString *cacheKey = [SDImageCache cacheKeyForLocalAssetIdentifier:localIdentifier andTargetSize:targetSize];
        
        void (^fetchImageBlock)() = ^(PHAsset *asset){
            
            if (operation.isCancelled) {
                return;
            }
            
            PHImageRequestOptions *requestOptions = [PHImageRequestOptions new];
            requestOptions.version = PHImageRequestOptionsVersionCurrent;
            requestOptions.synchronous = YES;
            requestOptions.networkAccessAllowed = YES;
            requestOptions.deliveryMode = self.phImageRequestDeliveryMode;
            requestOptions.resizeMode = self.phImageRequestResizeMode;
            
            [self.imageManager requestImageForAsset:asset
                                         targetSize:targetSize
                                        contentMode:PHImageContentModeAspectFit
                                            options:requestOptions
                                      resultHandler:^(UIImage *result, NSDictionary *info) {
                                          
                                          if (operation.isCancelled) {
                                              return;
                                          }
                                          
                                          if (result) {
                                              CGFloat cost = result.size.height * result.size.width * result.scale;
                                              [self.memCache setObject:result
                                                                forKey:cacheKey
                                                                  cost:cost];
                                          }
                                          
                                          if (completionBlock) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  completionBlock(result, SDImageCacheTypeLocalAssetStore);
                                              });
                                          }
                                      }];
            
        };
        
        __block PHAsset *localAsset = nil;
        localAsset = [self.localAssetIdentifierToAssetCache valueForKey:cacheKey];
        
        if (localAsset) {
            fetchImageBlock(localAsset);
        } else {
            PHFetchOptions *fetchOptions = [PHFetchOptions new];
            fetchOptions.includeHiddenAssets = YES;
            
            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:fetchOptions];
            
            if (fetchResult.count) {
                
                @synchronized(self.localAssetIdentifierToAssetCache) {
                    // this Asset wasn't previous in our cache, add it for use later
                    [self.localAssetIdentifierToAssetCache setValue:fetchResult.firstObject forKey:cacheKey];
                }
                
                fetchImageBlock(fetchResult.firstObject);
            } else {
                if (completionBlock) {
                    dispatch_main_sync_safe(^{
                        completionBlock(nil, SDImageCacheTypeNone);
                    });
                }
            }
        }
        
    });
    
    return operation;
}

@end
