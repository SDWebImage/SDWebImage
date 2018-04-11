## SDWebImage 5.0 Migration Guide

SDWebImage 5.0 is the latest major release of SDWebImage, a top library for downloading and caching images.
As a major release, following [Semantic Versioning](http://semver.org/) conventions, 5.0 introduces several API-breaking changes with its new architecture.

.... RELEASE_SUMMARY ....

This guide is provided in order to ease the transition of existing applications using SDWebImage 4.X to the latest APIs, as well as explain the design and structure of new and changed functionality.

### Requirements: iOS 8, Mac OS X 10.10, watchOS 2, tvOS 9, Xcode 8

SDWebImage 5.0 officially supports iOS 8 and later, Mac OS X 10.10 and later, watchOS 2 and later and tvOS 9 and later.
It needs Xcode 8 or later to be able to build everything properly.

For targeting previous versions of the SDKs, check [README - Backwards compatibility](https://github.com/rs/SDWebImage#backwards-compatibility)
.

### Migration

#### Swift

#### Objective-C

example

SDWebImage 4.x
```
[imageView sd_setImageWithURL:url placeholderImage:placeholderImage];
```

SDWebImage 5.x
```
[imageView sd_setImageWithURL:url placeholderImage:placeholderImage];
```

### Entities

#### Added
...

#### SDImageCache

- new initializer `initWithNamespace:diskCacheDirectory:config:`, is now the designated initializer
- moved `maxMemoryCost` and `maxMemoryCountLimit` to `SDImageCacheConfig`
- added `SDImageCache diskImageDataExistsWithKey:` synchronous method
- `addReadOnlyCachePath:` removed, use `additionalCachePathBlock` instead
- `cachePathForKey:inPath:` removed, use `cachePathForKey:` with NSString's path API instead.
- `defaultCachePathForKey:` removed, use `cachePathForKey:` instead

#### SDImageCacheConfig

- added `diskCacheWritingOptions` of type `NSDataWritingOptions`, defaults to `NSDataWritingAtomic`
- added `maxMemoryCost` and `maxMemoryCountLimit` properties (used to be in `SDImageCache`)
- `shouldDecompressImages` removed. Use  `SDImageCacheAvoidDecodeImage` in cache options instead

#### SDWebImageManager

- `loadImageWithURL:options:progress:completed:` changed the `completed` param requirement from `nullable` to `nonnull`
- `loadImageWithURL:options:progress:completed:` return type `id<SDWebImageOperation>` changed to `SDWebImageCombinedOperation *`
- `shared()` changed to `shared`
- `isRunning()` changed to `isRunning`
- `imageCache` changed from nullable to nonnull
- `imageDownloader` renamed to `imageLoader` and changed from nullable to nonnull
- `cacheKeyFilter` property type changed to `id<SDWebImageCacheKeyFilter>`, use the `SDWebImageCacheKeyFilter cacheKeyFilterWithBlock:`
- `cacheSerializer` property type CHANGED to `id<SDWebImageCacheSerializer>`, use the `SDWebImageCacheSerializer cacheSerializerWithBlock:`
- `imageCache` property type changed from `SDImageCache *` to `id<SDImageCache>`. The default value does not change.
- `initWithCache:downloader:` 's `cache` arg type changed from `SDImageCache *` to `id<SDImageCache>`
- `initWithCache:downloader` renamed to `initWithCache:loader:` 
- `saveImageToCache:forURL:` removed. Use `SDImageCache storeImage:imageData:forKey:cacheType:completion:` (or `SDImageCache storeImage:forKey:toDisk:completion:` if you use default cache class) with `cacheKeyForURL:` instead.
- `diskImageExistsForURL:completion:` removed. Use `SDImageCache containsImageForKey:cacheType:completion:` (or `SDImageCache diskImageExistsWithKey:completion:` if you use default cache class) with `cacheKeyForURL:` instead.
- `cachedImageExistsForURL:completion` removed. Use `SDImageCache containsImageForKey:cacheType:completion:` (or `SDImageCache diskImageExistsWithKey:completion:` and `SDImageCache imageFromMemoryCacheForKey:` if you use default cache class) with `cacheKeyForURL:` instead.

#### SDWebImageManagerDelegate

- removed `imageManager:transformDownloadedImage:forKey:`

#### UIView and subclasses (UIImageView, UIButton, ...)

- `sd_internalSetImageWithURL:placeholderImage:options:operationKey:setImageBlock:progress:completed:` renamed to `UIView sd_internalSetImageWithURL:placeholderImage:options:context:setImageBlock:progress:completed:` (The biggest changes is that the completion block type from `SDExternalCompletionBlock` to `SDInternalCompletionBlock`. Which allow advanced user to get more information of image loading process) 
- `sd_internalSetImageWithURL:placeholderImage:options:operationKey:setImageBlock:progress:completed:context:` removed
- activity indicator refactoring - use `sd_imageIndicator` with `SDWebImageActivityIndicator`
  - `sd_setShowActivityIndicatorView:` removed 
  - `sd_setIndicatorStyle:` removed
  - `sd_showActivityIndicatorView` removed
  - `sd_addActivityIndicator:` removed
  - `sd_removeActivityIndicator:` removed

#### UIImage

- Renamed `isGIF` to `sd_isAnimated`, also `NSImage isGIF` renamed to `NSImage sd_isAnimated`
- Renamed `decodedImageWithImage:` to `sd_decodedImageWithImage:`
- Renamed `decodedAndScaledDownImageWithImage:` to `sd_decodedAndScaledDownImageWithImage:`
- Removed `sd_webpLoopCount` since we have `sd_imageLoopCount`

#### UIImageView

- Removed `sd_setImageWithPreviousCachedImageWithURL:placeholderImage:options:progress:completed`

#### SDWebImageDownloader

- `shared()` changed to `shared`
- `setOperationClass` available for Swift user
- `setSuspended(_:)` changed to `isSuspended` property
- `shouldDecompressImages` moved to `SDWebImageDownloaderConfig.shouldDecompressImages`
- `maxConcurrentDownloads` moved to `SDWebImageDownloaderConfig.maxConcurrentDownloads`
- `downloadTimeout` moved to `SDWebImageDownloaderConfig.downloadTimeout`
- `operationClass` moved to `SDWebImageDownloaderConfig.operationClass`
- `executionOrder` moved to `SDWebImageDownloaderConfig.executionOrder`
- `urlCredential` moved to `SDWebImageDownloaderConfig.urlCredential`
- `username` moved to `SDWebImageDownloaderConfig.username`
- `password` moved to `SDWebImageDownloaderConfig.password`
- `initWithSessionConfiguration:` removed, use `initWithConfig:]` with session configuration instead
- `createNewSessionWithConfiguration:` removed, use `initWithConfig:]` with new session configuration instead. To modify shared downloader configuration, provide custom `SDWebImageDownloaderConfig.defaultDownloaderConfig` before it created.
- `headersFilter` removed, use `requestModifier` instead
- `cancel:` removed, use `SDWebImageDownloadToken cancel` instead
- `shouldDecompressImages` removed. Use `SDWebImageDownloaderAvoidDecodeImage` in downloader options instead

#### SDWebImageDownloaderOperation

- `initWithRequest:inSession:options:context:` is now the designated initializer
- Removed `shouldUseCredentialStorage` property
- `SDWebImageDownloadOperationInterface` protocol renamed to `SDWebImageDownloadOperation`. (`SDWebImageDownloadOperationProtocol` for Swift)
- `expectedSize` removed, use `response.expectedContentLength` instead
- `shouldDecompressImages` removed. Use `SDWebImageDownloaderAvoidDecodeImage` in downloader options instead.

#### SDWebImagePrefetcher

- `prefetchURLs:` and `prefetchURLs:progress:completed:` return types changed from `void` to `SDWebImagePrefetchToken`
- `prefetcherQueue` property renamed to `delegateQueue`
- `maxConcurrentDownloads` property removed, use `SDWebImageManager.downloader` config instead

#### SDWebImageCoder
- `SDCGColorSpaceGetDeviceRGB()` moved to `SDWebImageCoderHelper colorSpaceGetDeviceRGB` 
- `SDCGImageRefContainsAlpha()`, moved to `SDWebImageCoderHelper imageRefContainsAlpha:`
- `decodedImageWithData:` replaced with `decodedImageWithData:options:`
- `encodedDataWithImage:format:` replaced with `encodedDataWithImage:format:options`
- `init` method from `SDWebImageProgressiveCoder` changed to `initIncrementalWithOptions:`
- `incrementalDecodedImageWithData:finished` replaced with `updateIncrementalData:finished` and `incrementalDecodedImageWithOptions:`
- removed `decompressedImage:data:options`

#### SDWebImageCodersManager

- `sharedInstance()` changed to `shared`

#### SDWebImageImageIOCoder

- `shared()` changed to `shared`

#### SDWebImageGIFCoder

- `shared()` changed to `shared`

#### SDWebImageWebPCoder

- `shared()` changed to `shared`

#### NSData-ImageContentType

- `sd_UTTypeFromSDImageFormat` return `CFString` instead of `Unmanaged<CFString>`

#### UIButton-WebCache

- `sd_currentImageURL()` changed to `sd_currentImageURL`
  
#### NSButton-WebCache

- `sd_currentImageURL()` changed to `sd_currentImageURL`
- `sd_currentAlternateImageURL()` changed to `sd_currentAlternateImageURL`

#### Constants

- `SDWebImageInternalSetImageGroupKey` renamed to `SDWebImageContextSetImageGroup`
- `SDWebImageExternalCustomManagerKey` renamed to `SDWebImageContextCustomManager`
