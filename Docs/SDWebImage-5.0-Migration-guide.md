## SDWebImage 5.0 Migration Guide

SDWebImage 5.0 is the latest major release of SDWebImage, a top library for downloading and caching images.
As a major release, following [Semantic Versioning](http://semver.org/) conventions, 5.0 introduces several API-breaking changes with its new architecture.

This guide is provided in order to ease the transition of existing applications using SDWebImage 4.X to the latest APIs, as well as explain the design and structure of new and changed functionality.

### Requirements: iOS 8, Mac OS X 10.10, watchOS 2, tvOS 9, Xcode 9

SDWebImage 5.0 officially supports iOS 8 and later, Mac OS X 10.10 and later, watchOS 2 and later and tvOS 9 and later.
It needs Xcode 9 or later to be able to build everything properly.

For targeting previous versions of the SDKs, check [README - Backwards compatibility](https://github.com/rs/SDWebImage#backwards-compatibility).

### Migration

Using the view categories brings no change from 4.x to 5.0. 

Objective-C:

```objective-c
[imageView sd_setImageWithURL:url placeholderImage:placeholderImage];
```

Swift:

```swift
imageView.sd_setImage(with: url, placeholderImage: placeholder)
```

However, all view categories in 5.0 introduce a new extra arg called `SDWebImageContext`. Which can hold anything that previous enum `SDWebImageOptions` can not. This allow user to control advanced behavior for image loading as well as many aspect (cache, loader, etc). See the declaration for `SDWebImageContext` for detailed information.

### New Feature

#### Animated Image View

In 5.0, we introduce a brand new animated image solution. Which including animated image loading, rendering, decoding, and also support customization for advanced user.

This animated image solution is available for iOS/tvOS/macOS. The `SDAnimatedImage` is subclass of `UIImage/NSImage`, and `SDAnimatedImageView` is subclass of `UIImageView/NSImageView`, to allow most compatible for common framework APIs. See [Animated Image](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#animated-image-50) for more detailed information.

#### Transformer

In 5.0, we introduce a easy way to provide a image transform process after the image was downloaded from network. Which allow user to easily scale, rotate, rounded corner the original image. And even support chain a list of transformers together to output the final one. These transformed image will also stored to cache to avoid duplicate process. See [Image Transformer](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#transformer-50) for more detailed information.

#### Customization

In 5.0, we refactor our framework architecture with many aspect. This make our framework easier to customize for advanced user, without hook anything or create their fork. We introduce [Custom Cache](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-cache-50) to control detailed cache loading behavior, and separate the memory cache & disk cache implementation. We introduce [Custom Loader](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-loader-50) to allow custom loading from your own source (which even not need to be on network). And also, we change current [Custom Coder](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-coder-420) to works better for custom image decoder/encoder and animated image.

#### View Indicator
In 5.0, we refactor the current image loading indicator API. To use a better and extensible API for both iOS/tvOS/macOS. Which is suitable for easy usage for provide a loading view during the image loading process. See [View Indicator](https://github.com/rs/SDWebImage/wiki/How-to-use#use-view-indicator-50) for more detailed information.

#### FLAnimatedImage support moved to a dedicated plugin repo

Since we introduce the new animated image solution. Now we are no longer hosting the integration with `FLAnimatedImage` inside this repo. But for user who need `FLAnimatedImage` support. We have a dedicated repo for that and contains all the code compatible for SDWebImage 5.0. See [SDWebImageFLPlugin](https://github.com/SDWebImage/SDWebImageFLPlugin) for more detailed information.

#### Photos Plugin

By taking the advantage of [Custom Loader](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-loader-50) feature, we introduce a plugin to allow easily load Photos Library images. See [SDWebImagePhotosPlugin](https://github.com/SDWebImage/SDWebImagePhotosPlugin) for more detailed information.


### API Changes

#### SDImageCache

- moved `maxMemoryCost` and `maxMemoryCountLimit` to `SDImageCacheConfig`
- `makeDiskCachePath:` removed, use `NSSearchPathForDirectoriesInDomains` with NSString's Path API instead.
- `addReadOnlyCachePath:` removed, use `additionalCachePathBlock` instead
- `cachePathForKey:inPath:` removed, use `cachePathForKey:` with NSString's path API instead.
- `defaultCachePathForKey:` removed, use `cachePathForKey:` instead
- `SDCacheQueryCompletedBlock` renamed to `SDImageCacheQueryCompletionBlock`
- `SDWebImageCheckCacheCompletionBlock` renamed to `SDImageCacheCheckCompletionBlock`
- `SDWebImageCalculateSizeBlock` renamed to `SDImageCacheCalculateSizeBlock`

#### SDImageCacheConfig

- `shouldDecompressImages` removed. Use  `SDImageCacheAvoidDecodeImage` in cache options instead

#### SDWebImageManager

- `loadImageWithURL:options:progress:completed:` changed the `completed` param requirement from `nullable` to `nonnull`
- `loadImageWithURL:options:progress:completed:` return type `id<SDWebImageOperation>` changed to `SDWebImageCombinedOperation *`
- `imageCache` changed from nullable to nonnull. And property type changed from `SDImageCache *` to `id<SDImageCache>`. The default value does not change.
- `imageDownloader` renamed to `imageLoader` and changed from nullable to nonnull. And property type changed from `SDWebImageDownloader *` to `id<SDImageLoader>`. The default value does not change.
- `cacheKeyFilter` property type changed to `id<SDWebImageCacheKeyFilter>`, you can use `+[SDWebImageCacheKeyFilter cacheKeyFilterWithBlock:]` to create
- `cacheSerializer` property type changed to `id<SDWebImageCacheSerializer>`, you can use `+[SDWebImageCacheSerializer cacheSerializerWithBlock:]` to create
- `SDWebImageCacheKeyFilterBlock`'s `url` arg change from nullable to nonnull
- `initWithCache:downloader:` 's `cache` arg type changed from `SDImageCache *` to `id<SDImageCache>`
- `initWithCache:downloader` renamed to `initWithCache:loader:` 
- `saveImageToCache:forURL:` removed. Use `SDImageCache storeImage:imageData:forKey:cacheType:completion:` (or `SDImageCache storeImage:forKey:toDisk:completion:` if you use default cache class) with `cacheKeyForURL:` instead.
- `diskImageExistsForURL:completion:` removed. Use `SDImageCache containsImageForKey:cacheType:completion:` (or `SDImageCache diskImageExistsWithKey:completion:` if you use default cache class) with `cacheKeyForURL:` instead.
- `cachedImageExistsForURL:completion` removed. Use `SDImageCache containsImageForKey:cacheType:completion:` (or `SDImageCache diskImageExistsWithKey:completion:` and `SDImageCache imageFromMemoryCacheForKey:` if you use default cache class) with `cacheKeyForURL:` instead.

#### SDWebImageManagerDelegate

- removed `imageManager:transformDownloadedImage:forKey:`, use `SDImageTransformer` with context option instead

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
- Renamed `sd_animatedGIFWithData` to `sd_imageWithGIFData:`
- Removed `sd_webpLoopCount`

#### UIImageView

- Removed `sd_setImageWithPreviousCachedImageWithURL:placeholderImage:options:progress:completed`

#### SDWebImageDownloader

- `shouldDecompressImages` moved to `SDWebImageDownloaderConfig.shouldDecompressImages`
- `maxConcurrentDownloads` moved to `SDWebImageDownloaderConfig.maxConcurrentDownloads`
- `downloadTimeout` moved to `SDWebImageDownloaderConfig.downloadTimeout`
- `operationClass` moved to `SDWebImageDownloaderConfig.operationClass`
- `executionOrder` moved to `SDWebImageDownloaderConfig.executionOrder`
- `urlCredential` moved to `SDWebImageDownloaderConfig.urlCredential`
- `username` moved to `SDWebImageDownloaderConfig.username`
- `password` moved to `SDWebImageDownloaderConfig.password`
- `initWithSessionConfiguration:` removed, use `initWithConfig:` with session configuration instead
- `createNewSessionWithConfiguration:` removed, use `initWithConfig:` with new session configuration instead. To modify shared downloader configuration, provide custom `SDWebImageDownloaderConfig.defaultDownloaderConfig` before it created.
- `headersFilter` removed, use `requestModifier` instead
- `cancel:` removed, use `-[SDWebImageDownloadToken cancel]` instead
- `shouldDecompressImages` removed. Use `SDWebImageDownloaderAvoidDecodeImage` in downloader options instead
- use `SDWebImageLoaderProgressBlock` instead of `SDWebImageDownloaderProgressBlock`
- use `SDWebImageLoaderCompletedBlock` instead of `SDWebImageDownloaderCompletedBlock`

#### SDWebImageDownloaderOperation

- `initWithRequest:inSession:options:context:` is now the designated initializer
- Removed `shouldUseCredentialStorage` property
- `SDWebImageDownloadOperationInterface` protocol renamed to `SDWebImageDownloadOperation`
- `expectedSize` removed, use `response.expectedContentLength` instead
- `shouldDecompressImages` removed. Use `SDWebImageDownloaderAvoidDecodeImage` in downloader options instead.
- `response` property change to readonly

#### SDWebImagePrefetcher

- `prefetchURLs:` and `prefetchURLs:progress:completed:` return types changed from `void` to `SDWebImagePrefetchToken`
- `prefetcherQueue` property renamed to `delegateQueue`
- `maxConcurrentDownloads` property removed, use `SDWebImageManager.downloader` config instead

#### SDImageCoder
- `SDCGColorSpaceGetDeviceRGB()` moved to `+[SDImageCoderHelper colorSpaceGetDeviceRGB]` 
- `SDCGImageRefContainsAlpha()`, moved to `+[SDImageCoderHelper imageRefContainsAlpha:]`
- `decodedImageWithData:` replaced with `decodedImageWithData:options:`
- `encodedDataWithImage:format:` replaced with `encodedDataWithImage:format:options`
- `init` method from `SDWebImageProgressiveCoder` changed to `initIncrementalWithOptions:`
- `incrementalDecodedImageWithData:finished` replaced with `updateIncrementalData:finished` and `incrementalDecodedImageWithOptions:` two APIs
- removed `decompressedImage:data:options`, use `+[SDImageCoderHelper decodedImageWithImage:]` and `+[SDImageCoderHelper decodedAndScaledDownImageWithImage:limitBytes:]` instead

#### Constants

- `SDWebImageInternalSetImageGroupKey` renamed to `SDWebImageContextSetImageGroup`
- `SDWebImageExternalCustomManagerKey` renamed to `SDWebImageContextCustomManager`

#### Swift Specific API Change
In SDWebImage 5.0 we did a clean up of the API. We are using many modern Objective-C declarations to generate the Swift API. We now provide full nullability support, string enum, class property, and even custom Swift API name, all to make the framework easier to use for our Swift users. Here are the API change specify for Swift. 

##### UIView+WebCache
- `sd_imageURL()` changed to `sd_imageURL`

##### SDImageCache
- `shared()` changed to `shared`

##### SDWebImageManager
- `shared()` changed to `shared`
- `isRunning()` changed to `isRunning`

##### SDWebImageDownloader
- `shared()` changed to `shared`
- `setOperationClass(_:)` available for Swift user with `operationClass` property
- `setSuspended(_:)` changed to `isSuspended` property

##### SDWebImageDownloadOperation
- `SDWebImageDownloadOperationInterface` protocol renamed to `SDWebImageDownloadOperationProtocol`. 

##### SDImageCodersManager

- `sharedInstance()` changed to `shared`

##### SDImageIOCoder

- `shared()` changed to `shared`

##### SDImageGIFCoder

- `shared()` changed to `shared`

##### SDImageWebPCoder

- `shared()` changed to `shared`

##### NSData-ImageContentType

- `sd_UTTypeFromSDImageFormat` return `CFString` instead of `Unmanaged<CFString>`

##### UIButton-WebCache

- `sd_currentImageURL()` changed to `sd_currentImageURL`
  
##### NSButton-WebCache

- `sd_currentImageURL()` changed to `sd_currentImageURL`
- `sd_currentAlternateImageURL()` changed to `sd_currentAlternateImageURL`

### Full API Diff
For advanced user who need the detailed API diff, we provide the full diff in a HTML web page: [SDWebImage 5.0 API Diff](https://raw.githubusercontent.com/rs/SDWebImage/master/Docs/Diff/5.0/apidiff.html)

