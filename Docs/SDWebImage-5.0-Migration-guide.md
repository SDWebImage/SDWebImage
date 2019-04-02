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

However, all view categories in 5.0 introduce a new extra arg called `SDWebImageContext`. This param can hold anything, as oposed to the previous `SDWebImageOptions` enum limitations. This gives developers advanced control for the behavior of image loading (cache, loader, etc). See the declaration for `SDWebImageContext` for detailed information.

### New Feature

#### Animated Image View

In 5.0, we introduced a brand new mechanism for supporting animated images. This includes animated image loading, rendering, decoding, and also supports customizations (for advanced users).

This animated image solution is available for `iOS`/`tvOS`/`macOS`. The `SDAnimatedImage` is subclass of `UIImage/NSImage`, and `SDAnimatedImageView` is subclass of `UIImageView/NSImageView`, to make them compatible with the common frameworks APIs. See [Animated Image](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#animated-image-50) for more detailed information.

#### Image Transformer

In 5.0, we introduced an easy way to hook an image transformation process after the image was downloaded from network. This allows the user to easily scale, rotate, add rounded corner the original image and even chain a list of transformations. These transformed images will also be stored to the cache as they are after transformation. The reasons for this decision are: avoiding redoing the transformations (which can lead to unwanted behavior) and also time saving. See [Image Transformer](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#image-transformer-50) for more detailed information.

#### Customization

In 5.0, we refactored our framework architecture in many aspects. This makes our framework easier to customize for advanced users, without the need for hooking anything or forking. We introduced [Custom Cache](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-cache-50) to control detailed cache loading behavior, and separate the memory cache & disk cache implementation. We introduced [Custom Loader](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-loader-50) to allow custom loading from your own source (doesn't have to be the network). And also, we changed the current [Custom Coder](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-coder-420) to work better for custom image decoder/encoder and animated images.

#### View Indicator
In 5.0, we refactored the image loading indicator API into a better and extensible API for `iOS`/`tvOS`/`macOS`. This is suitable for easy usage like providing a loading view during the image loading process. See [View Indicator](https://github.com/rs/SDWebImage/wiki/How-to-use#use-view-indicator-50) for more detailed information.

#### FLAnimatedImage support moved to a dedicated plugin repo

In order to clean up things and make our core project do less things, we decided that the `FLAnimatedImage` integration does not belong here. From 5.0, this will still be available, but under a dedicated repo [SDWebImageFLPlugin](https://github.com/SDWebImage/SDWebImageFLPlugin).

#### Photos Plugin

By taking the advantage of the [Custom Loader](https://github.com/rs/SDWebImage/wiki/Advanced-Usage#custom-loader-50) feature, we introduced a plugin to allow easy loading images from the Photos Library. See [SDWebImagePhotosPlugin](https://github.com/SDWebImage/SDWebImagePhotosPlugin) for more detailed information.


### Notable Behavior Changes (without API breaking)

#### Cache

##### Cache Paths

`SDImageCache` in 5.x, use `~/Library/Caches/com.hackemist.SDImageCache/default/` as default cache path. However, 4.x use `~/Library/Caches/default/com.hackemist.SDWebImageCache.default/`. And don't be worried, we will do the migration automatically once the shared cache initialized.

However, if you have some other custom namespace cache instance, you should try to do migration by yourself. But typically, since the cache is designed to be invalid at any time, you'd better not to bind some important logic related on that cache path changes.

And, if you're previously using any version from `5.0.0-beta` to `5.0.0-beta3`, please note that the cache folder has been temporarily moved to `~/Library/Caches/default/com.hackemist.SDImageCache.default/`, however, the final release version of 5.0.0 use the path above. If you upgrade from those beta version, you may need manually do migration, check `+[SDDiskCache moveCacheDirectoryFromPath:toPath:]` for detail information.

##### Cache Cost Function

`SDImageCacheConfig.maxMemoryCost` can be used to specify the memory cost limit. In the 4.x, the cost function is the **pixel count** of images. However, 5.x change it into the total **bytes size** of images. 

Because for memory cache, we actually care about the memory usage about bytes, but not the count of pixels. And pixel count can not accurately represent the memory usage.

The bytes of a image occupied in the memory, can use the simple formula below:

**bytes size** = **pixel count** \* **bytes per pixel**

The **bytes per pixel** is a constant depends on [image pixel format](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/drawingwithquartz2d/dq_images/dq_images.html). For mostly used images (8 bits per channel with alpha), the value is 4. So you can simply migrate your previous pixel count value with 4 multiplied.


#### Prefetcher

`SDWebImagePrefetcher` in 5.x, change the concept of fetching batch of URLs. Now, each time you call `prefetchURLs:`, you will get a token which represents the specified URLs list. It does not cancel the previous URLs which is prefetching, which make the shared prefetcher behaves more intuitively.

However, in 4.x, each time you call `prefetchURLs:`, it will cancel all previous URLs which is been prefetching.

If you still want the same behavior, manually call `cancelPrefetching` each time before any `prefetchURLs:` calls.


+ Objective-C

```objective-c
SDWebImagePrefetcher *prefetcher = SDWebImagePrefetcher.sharedImagePrefetcher;
[prefetcher cancelPrefetching];
[prefetcher prefetchURLs:@[url1, url2]];
```

+ Swift

```swift
let prefetcher = SDWebImagePrefetcher.shared
prefetcher.cancelPrefetching()
prefetcher.prefetchURLs([url1, url2])
```

#### Error codes and domain
For image loading from network, if you don't pass `SDWebImageRetryFailed` option, we'll try to blocking some URLs which is indeed mark as failed.

This check is done previously in a hard-coded logic for specify error codes. However, due to some compatible issue, we don't check the error domain. (Learn about [NSError's domain and codes](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorObjectsDomains/ErrorObjectsDomains.html)) And arbitrarily block some codes which may from custom download operation implementations.

Since in 5.x, we supports custom loaders which can use any third-party SDKs, and have their own error domain and error codes. So we now only filter the error codes in [NSURLErrorDomain](https://developer.apple.com/documentation/foundation/nsurlerrordomain). If you have already using some error codes without error domain check, or you use [Custom Download Operation](https://github.com/SDWebImage/SDWebImage/wiki/Advanced-Usage#custom-download-operation-40), be sure to update it with the right way.

At the same time, our framework errors, now using the formal `SDWebImageErrorDomain` with the pre-defined codes. Check `SDWebImageError.h` for details.

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
- `getSize` renamed to `totalDiskSize`
- `getDiskCount` renamed to `totalDiskCount`

#### SDImageCacheConfig

- `shouldDecompressImages` removed. Use  `SDImageCacheAvoidDecodeImage` in cache options instead
- `maxCacheAge` renamed to `maxDiskAge`
- `maxCacheSize` renamed to `maxDiskSize`

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
- use `SDImageLoaderProgressBlock` instead of `SDWebImageDownloaderProgressBlock`
- use `SDImageLoaderCompletedBlock` instead of `SDWebImageDownloaderCompletedBlock`

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
- `maxConcurrentDownloads` replaced with `maxConcurrentPrefetchCount`

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
For advanced user who need the detailed API diff, we provide the full diff in a HTML web page (Currently based on 4.4.4 and 5.0.0-beta4):

[SDWebImage 5.0 API Diff](https://htmlpreview.github.io/?https://github.com/rs/SDWebImage/blob/master/Docs/API-Diff/5.0/apidiff.html).

