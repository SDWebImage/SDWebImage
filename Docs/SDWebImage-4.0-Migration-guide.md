## SDWebImage 4.0 Migration Guide

SDWebImage 4.0 is the latest major release of SDWebImage, a top library for downloading and caching images.
As a major release, following [Semantic Versioning](http://semver.org/) conventions, 4.0 introduces several API-breaking changes with its new architecture.

We've expanded the list of supported platforms and added to the existing **iOS** and **tvOS**, the long waited **watchOS** and **Mac OS X**.

Our support for animated images (especially GIFs) was not that great, so we decided to delegate this responsibility to [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage), a library created by Flipboard which has great results in working with animated images.

This guide is provided in order to ease the transition of existing applications using SDWebImage 3.X to the latest APIs, as well as explain the design and structure of new and changed functionality.

### Requirements: iOS 7, Mac OS X 10.8, watchOS 2, tvOS 9, Xcode 7.3

SDWebImage 4.0 officially supports iOS 7 and later, Mac OS X 10.8 and later, watchOS 2 and later and tvOS 9 and later.
It needs Xcode 7.3 or later to be able to build everything properly.

For targeting previous versions of the SDKs, check [README - Backwards compatibility](https://github.com/SDWebImage/SDWebImage#backwards-compatibility)
.

### Migration

#### Swift

Because the 4.0 version included #1581 - Lightweight Generics and Nullability, the Swift interface for all users has changed.
For 3.x versions which did not have the Nullability specifiers, all params and vars where bridged as Implicitly Unwrapped Optionals.
With 4.0, the ones marked as `nullable` will be regular optionals, as the `nonnull` ones are non-optionals.

For details, read [Nullability and Objective-C](https://developer.apple.com/swift/blog/?id=25).

#### Using the UI*View categories brings no change

SDWebImage 3.x
```
[imageView sd_setImageWithURL:url placeholderImage:placeholderImage];
```

SDWebImage 4.x
```
[imageView sd_setImageWithURL:url placeholderImage:placeholderImage];
```

#### Using directly SDWebImageManager

SDWebImage 3.x
```
[manager downloadImageWithURL:url options:options: progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) { ... } ];
```

SDWebImage 4.x
```
[manager loadImageWithURL:url options:options: progress:nil completed:^(UIImage *image, NSData *imageData, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) { ... } ];
```

### Entities

#### Added
- `SDImageCacheConfig` class for `SDImageCache` config (`shouldDecompressImages`, `shouldDisableiCloud`, `shouldCacheImagesInMemory`, `maxCacheAge`, `maxCacheSize`)
- `SDWebImageDownloadToken` class for the ability to cancel specific downloads (`url`, `downloadOperationCancelToken`)
- `UIView (WebCache)` category because of DRY, with methods
  - `sd_imageURL`
  - `sd_internalSetImageWithURL:placeholderImage:options:operationKey:setImageBlock:progress:completed:`
  - `sd_cancelCurrentImageLoad`
  - `sd_showActivityIndicatorView`
  - `sd_addActivityIndicator`
  - `sd_removeActivityIndicator`
- `SDWebImageDownloaderOperationInterface` protocol to describe the downloader operation behavior (in case one wants to customize)
- `SDImageFormat` enum containing the formats supported by the library (jpeg, png, gif, tiff, webp)
- `FLAnimatedImageView (WebCache)` category for `FLAnimatedImageView` from [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage)

#### UIImageView (WebCache)
- moved to `UIView (WebCache)`,`UIImageView` objects still respond to those methods:
  - `sd_imageURL`
  - `sd_cancelCurrentImageLoad`
  - `setShowActivityIndicatorView:` renamed to `sd_setShowActivityIndicatorView:`
  - `setIndicatorStyle:` renamed to `sd_setIndicatorStyle:`
- removed deprecated methods:
  - `imageURL`
  - `setImageWithURL:`
  - `setImageWithURL:placeholderImage:`
  - `setImageWithURL:placeholderImage:options:`
  - `setImageWithURL:completed:`
  - `setImageWithURL:placeholderImage:completed:`
  - `setImageWithURL:placeholderImage:options:completed:`
  - `setImageWithURL:placeholderImage:options:progress:completed:`
  - `sd_setImageWithPreviousCachedImageWithURL:andPlaceholderImage:options:progress:completed:`
  - `setAnimationImagesWithURLs:`
  - `cancelCurrentArrayLoad`
  - `cancelCurrentImageLoad`
  
#### UIButton (WebCache)
- removed deprecated methods:
  - `currentImageURL`
  - `imageURLForState:`
  - `setImageWithURL:forState:`
  - `setImageWithURL:forState:placeholderImage:`
  - `setImageWithURL:forState:placeholderImage:options:`
  - `setImageWithURL:forState:completed:`
  - `setImageWithURL:forState:placeholderImage:completed:`
  - `setImageWithURL:forState:placeholderImage:options:completed:`
  - `setBackgroundImageWithURL:forState:`
  - `setBackgroundImageWithURL:forState:placeholderImage:`
  - `setBackgroundImageWithURL:forState:placeholderImage:options:`
  - `setBackgroundImageWithURL:forState:completed:`
  - `setBackgroundImageWithURL:forState:placeholderImage:completed:`
  - `setBackgroundImageWithURL:forState:placeholderImage:options:completed:`
  - `cancelCurrentImageLoad`
  - `cancelBackgroundImageLoadForState:`
  
#### MKAnnotationView (WebCache)
- removed deprecated methods:
  - `imageURL`
  - `setImageWithURL:`
  - `setImageWithURL:placeholderImage:`
  - `setImageWithURL:placeholderImage:options:`
  - `setImageWithURL:completed:`
  - `setImageWithURL:placeholderImage:completed:`
  - `setImageWithURL:placeholderImage:options:completed:`
  - `cancelCurrentImageLoad`

#### UIImageView (HighlightedWebCache)
- removed methods:
  - `sd_cancelCurrentHighlightedImageLoad`
- removed deprecated methods:
  - `setHighlightedImageWithURL:`
  - `setHighlightedImageWithURL:options:`
  - `setHighlightedImageWithURL:completed:`
  - `setHighlightedImageWithURL:options:completed:`
  - `setHighlightedImageWithURL:options:progress:completed:`
  - `cancelCurrentHighlightedImageLoad`
  
#### SDWebImageManager
- `initWithCache:downloader:` is now the designated initializer
- added `SDWebImageScaleDownLargeImages` option for scaling large images
- renamed `downloadImageWithURL:options:progress:completed` to `loadImageWithURL:options:progress:completed` just to make it clear what the method does
- renamed `SDWebImageCompletionBlock` to `SDExternalCompletionBlock`
- renamed `SDWebImageCompletionWithFinishedBlock` to `SDInternalCompletionBlock` and added extra `NSData` param
- removed synchronous methods:
  - `cachedImageExistsForURL:`
  - `diskImageExistsForURL:`
- removed deprecated methods:
  - `downloadWithURL:options:progress:completed:`
- removed deprecated types:
  - `SDWebImageCompletedBlock`
  - `SDWebImageCompletedWithFinishedBlock`
  
#### SDWebImagePrefetcher
- `initWithImageManager:` is now the designated initializer

#### SDWebImageDownloader
- added `initWithSessionConfiguration:` which is now the designated initializer
- added `SDWebImageDownloaderScaleDownLargeImages` option for scaling large images
- added a `NSURL` param to `SDWebImageDownloaderProgressBlock`
- `downloadImageWithURL:options:progress:completed:` now returns a `SDWebImageDownloadToken`
- added method `cancel:` which takes a `SDWebImageDownloadToken`

#### SDWebImageDownloaderOperation
- `initWithRequest:inSession:options:progress:completed:cancelled:` replaced by two methods: `initWithRequest:inSession:options:` and `addHandlersForProgress:completed:`
- `initWithRequest:inSession:options:` is now the designated initializer
- added `cancel:` method
- removed deprecated methods:
  - `initWithRequest:options:progress:completed:cancelled:`
  
#### SDImageCache
- moved the following properties to `SDImageCacheConfig`:
  - `shouldDecompressImages`
  - `shouldDisableiCloud`
  - `shouldCacheImagesInMemory`
  - `maxCacheAge`
  - `maxCacheSize`
- added a `config` property (`SDImageCacheConfig`)
- renamed `SDWebImageQueryCompletedBlock` to `SDCacheQueryCompletedBlock` and added `NSData` param
- `initWithNamespace:diskCacheDirectory:` is now the designated initializer
- the `storeImage:forKey:`, `storeImage:forKey:toDisk:`, `storeImage:recalculateFromImage:imageData:forKey:toDisk:` methods were async already, but declared as sync. Properly marked them as async + added `completion` param. Got rid of the `recalculate` param. If the `NSData` is provided, use it. Otherwise, recalculate it from the `UIImage`
  - `storeImage:forKey:` -> `storeImage:forKey:completion:`
  - `storeImage:forKey:toDisk:` -> `storeImage:forKey:toDisk:completion:`
  - `storeImage:recalculateFromImage:imageData:forKey:toDisk:` -> `storeImage:imageData:forKey:toDisk:completion:`
- removed the synchronous method `diskImageExistsWithKey:`
- got rid of the confusion caused by having `cleanDisk` and `clearDisk`. Renamed `cleanDiskWithCompletion:` to `deleteOldFilesWithCompletion:`. 
- removed the synchronous `clearDisk` and `deleteOldFiles`
- renamed `queryDiskCacheForKey:done:` to `queryCacheOperationForKey:done:`
- another clarification: `imageFromDiskCacheForKey:` used to also check the memory cache which I think is misleading. Now `imageFromDiskCacheForKey:` only checks the disk cache and the new method `imageFromCacheForKey:` checks both caches
- removed `removeImageForKey:` and `removeImageForKey:fromDisk:` because they caused confusion (were calling the async ones with `nil` as `completion`)

#### NSData (ImageContentType)
- renamed `sd_contentTypeForImageData:` to `sd_imageFormatForImageData:` and returns `SDImageFormat`
- removed the deprecated method `contentTypeForImageData:`

#### SDWebImageCompat
- removed `dispatch_main_sync_safe` as it could be mistakenly used
- updated `dispatch_main_async_safe` so it checks for the main queue instead of the main thread

#### SDWebImageDecoder
- added `decodedAndScaledDownImageWithImage:` that decodes the image and scales it down if it's too big (over 60MB in memory)

#### UIImage
- removed `sd_animatedGIFNamed:` or `sd_animatedImageByScalingAndCroppingToSize:`
- added `isGIF`
- added `sd_imageData` and `sd_imageDataAsFormat:`. Those methods transform a `UIImage` to the `NSData` representation
