## [3.7.3 Patch release for 3.7.0 with iOS8+ framework and Carthage on Jun 13th, 2015](https://github.com/rs/SDWebImage/releases/tag/3.7.3)

- Adds support for **iOS 8+ Framework and Carthage** [#1071](https://github.com/rs/SDWebImage/pull/1071) [#1081](https://github.com/rs/SDWebImage/pull/1081) [#1101](https://github.com/rs/SDWebImage/pull/1101) 

- [Refactor] Use `NSMutableSet` for failed URLs' storage instead of array [#1076](https://github.com/rs/SDWebImage/pull/1076) 
- Make a constant for the error domain [#1011](https://github.com/rs/SDWebImage/pull/1011) 
- Improve operation behavior [#988](https://github.com/rs/SDWebImage/pull/988) 
- Bug fix: `Collection <__NSArrayM: > was mutated while being enumerated` [#985](https://github.com/rs/SDWebImage/pull/985) 
- added `SDWebImageAvoidAutoSetImage` option to avoid automatic image addition in `UIImageView` and let developer to do it himself [#1188](https://github.com/rs/SDWebImage/pull/1188) 
- Added support for custom disk cache folder with fall back for caches directory [#1153](https://github.com/rs/SDWebImage/pull/1153) 
- Added some files to the workspace so they are easier to edit [8431481](https://github.com/rs/SDWebImage/commit/8431481)
- Doc update [72ed897](https://github.com/rs/SDWebImage/commit/72ed897) [7f99c01](https://github.com/rs/SDWebImage/commit/7f99c01) [#1016](https://github.com/rs/SDWebImage/pull/1016) [#1038](https://github.com/rs/SDWebImage/pull/1038) [#1045](https://github.com/rs/SDWebImage/pull/1045)
- [Memory Issue] Clear `SDWebImagePrefetcher` `progressBlock` when it has completed [#1017](https://github.com/rs/SDWebImage/pull/1017) 
- avoid warning `<Error>: ImageIO: CGImageSourceCreateWithData data parameter is nil` if `imageData` is nil [88ee3c6](https://github.com/rs/SDWebImage/commit/88ee3c6) [#1018](https://github.com/rs/SDWebImage/pull/1018) 
- allow override `diskCachePath` [#1041](https://github.com/rs/SDWebImage/pull/1041) 
- Use `__typeof(self)` when assigning `weak` reference for block [#1054](https://github.com/rs/SDWebImage/pull/1054) 
- [Refactor] Implement cache cost calculation as a inline function [#1075](https://github.com/rs/SDWebImage/pull/1075) 
- @3x support [9620fff](https://github.com/rs/SDWebImage/commit/9620fff) [#1005](https://github.com/rs/SDWebImage/pull/1005) 
- Fix parenthesis to avoid crashes [#1104](https://github.com/rs/SDWebImage/pull/1104) 
- Add `NSCache` countLimit property [#1140](https://github.com/rs/SDWebImage/pull/1140) 
- `failedURLs` can be removed at the appropriate time [#1111](https://github.com/rs/SDWebImage/pull/1111) 
- Purge `NSCache` on system memory notifications [#1143](https://github.com/rs/SDWebImage/pull/1143) 
- Determines at runtime is `UIApplication` is available as per [#1082](https://github.com/rs/SDWebImage/issues/1082) [#1085](https://github.com/rs/SDWebImage/pull/1085) 
- Fixes http://git.chromium.org/webm/libwebp.git/info/refs not valid [#1175](https://github.com/rs/SDWebImage/pull/1175) + Reverted [#1193](https://github.com/rs/SDWebImage/pull/1193) + [#1177](https://github.com/rs/SDWebImage/pull/1177) 
- 404 image url was causing the test to fail [0e761f4](https://github.com/rs/SDWebImage/commit/0e761f4)
- Fix for transparency being lost in transformed images. [#1121](https://github.com/rs/SDWebImage/pull/1121) 
- Add handling for additional error codes that shouldn't be considered a permanent failure [#1159](https://github.com/rs/SDWebImage/pull/1159) 
- add webp accepted content type only if `WebP` enabled [#1178](https://github.com/rs/SDWebImage/pull/1178) 
- fix `ImageIO: CGImageSourceCreateWithData` data parameter is nil [#1167](https://github.com/rs/SDWebImage/pull/1167) 
- Applied patch for issue [#1074](https://github.com/rs/SDWebImage/issues/1074) SDWebImage residing in swift module breaks the debugger [#1138](https://github.com/rs/SDWebImage/pull/1138)
- Fixed URLs with trailing parameters get assigned an incorrect image scale value [#1157](https://github.com/rs/SDWebImage/issues/1157) [#1158](https://github.com/rs/SDWebImage/pull/1158) 
- Add newline to avoid compiler warning in `WebImage.h` [#1199](https://github.com/rs/SDWebImage/pull/1199) 

## [3.7.2 Updated patch release for 3.7.0 on Mar 17th, 2015](https://github.com/rs/SDWebImage/releases/tag/3.7.2)

#### Updates
- bumped `libwep` version to `0.4.3`

#### Features:
- implement `SDWebImageDownloaderAllowInvalidSSLCertificates` option - [#937](https://github.com/rs/SDWebImage/pull/937) 
- flag to transform animated images (`SDWebImageTransformAnimatedImage`) - [#703](https://github.com/rs/SDWebImage/pull/703) 
- allows user to override default `SDWebImageDownloaderOperation` - [#876](https://github.com/rs/SDWebImage/pull/876) 
- adds option to decompress images and select prefetcher queue - [#996](https://github.com/rs/SDWebImage/pull/996)  

#### Fixes:
- fixed [#809](https://github.com/rs/SDWebImage/issues/809) `cancelAll` crash - [#838](https://github.com/rs/SDWebImage/pull/838) 
- fixed [#900](https://github.com/rs/SDWebImage/issues/900) by adding a new flag `SD_LOG_NONE` that allows silencing the SD logs from the Prefetcher
- fixed [#895](https://github.com/rs/SDWebImage/issues/895) unsafe setImage in `setImageWithURL:` - [#896](https://github.com/rs/SDWebImage/pull/896) 
- fix `NSNotificationCenter` dispatch on subthreads - [#987](https://github.com/rs/SDWebImage/pull/987) 
- fix `SDWebImageDownloader` threading issue - [#104](https://github.com/rs/SDWebImage/pull/104)6 
- fixed duplicate failed urls are added into `failedURLs` - [#994](https://github.com/rs/SDWebImage/pull/994) 
- increased default `maxConcurrentOperationCount`, fixes [#527](https://github.com/rs/SDWebImage/issues/527) - [#897](https://github.com/rs/SDWebImage/pull/897) 
- handle empty urls `NSArray` - [#929](https://github.com/rs/SDWebImage/pull/929) 
- decoding webp, depends on source image data alpha status - [#936](https://github.com/rs/SDWebImage/pull/936) 
- fix [#610](https://github.com/rs/SDWebImage/issues/610) display progressive jpeg issue - [#840](https://github.com/rs/SDWebImage/pull/840) 
- the code from `SDWebImageDownloaderOperation connection:didFailWithError:` should match the code from `connectionDidFinishLoading:`. This fixes [#872](https://github.com/rs/SDWebImage/issues/872) - [7f39e5e](https://github.com/rs/SDWebImage/commit/7f39e5e)
- `304 - Not Modified` HTTP status code handling - [#942](https://github.com/rs/SDWebImage/pull/942) 
- cost compute fix - [#941](https://github.com/rs/SDWebImage/pull/941) 
- initialise `kPNGSignatureData` data - [#981](https://github.com/rs/SDWebImage/pull/981) 

#### Documentation
- documentation updated

## [3.7.1 Patch release for 3.7.0 on Jul 23rd, 2014](https://github.com/rs/SDWebImage/releases/tag/3.7.1)

- fixed `sd_imageOrientationFromImageData:` crash if imageSource is nil - [#819](https://github.com/rs/SDWebImage/pull/819) [#813](https://github.com/rs/SDWebImage/pull/813) [#808](https://github.com/rs/SDWebImage/issues/808) [#828](https://github.com/rs/SDWebImage/issues/828) - temporary fix
- fixed `SDWebImageCombinedOperation cancel` crash (also visible as `SDWebImageManager cancelAll`) - [28109c4](https://github.com/rs/SDWebImage/commit/28109c4) [#798](https://github.com/rs/SDWebImage/issues/798) [#809](https://github.com/rs/SDWebImage/issues/809) 
- fixed duplicate symbols when using with webp via pods - [#795](https://github.com/rs/SDWebImage/pull/795) 
- fixed missing `mark` from `pragma mark` - [#827](https://github.com/rs/SDWebImage/pull/827) 

## [3.7.0 Xcode6, arm64, highlight UIImageView, imageURL ref, NTLM, ... on Jul 14th, 2014](https://github.com/rs/SDWebImage/releases/tag/3.7.0)

## Features
- Add category for imageView's highlighted state `UIImageView+HighlightedWebCache` - [#646](https://github.com/rs/SDWebImage/pull/646) [#765](https://github.com/rs/SDWebImage/pull/765)
- Keep a reference to the image URL - [#560](https://github.com/rs/SDWebImage/pull/560)
- Pass imageURL in completedBlock - [#770](https://github.com/rs/SDWebImage/pull/770)
- Implemented NTLM auth support. Replaced deprecated auth challenge methods from `NSURLConnectionDelegate` - [#711](https://github.com/rs/SDWebImage/pull/711) [50c4d1d](https://github.com/rs/SDWebImage/commit/50c4d1d)
- Ability to suspend image downloaders `SDWebImageDownloader setSuspended:` - [#734](https://github.com/rs/SDWebImage/pull/734)
- Delay the loading of the placeholder image until after load - [#701](https://github.com/rs/SDWebImage/pull/701)
- Ability to save images to cache directly - [#714](https://github.com/rs/SDWebImage/pull/714)
- Support for image orientation - [#764](https://github.com/rs/SDWebImage/pull/764)
- Added async `SDImageCache removeImageForKey:withCompletion:` - [#732](https://github.com/rs/SDWebImage/pull/732) [cd4b925](https://github.com/rs/SDWebImage/commit/cd4b925)
- Exposed cache paths - [#339](https://github.com/rs/SDWebImage/issues/339)
- Exposed `SDWebImageManager cacheKeyForURL:` - [5fd21e5](https://github.com/rs/SDWebImage/commit/5fd21e5)
- Exposing `SDWebImageManager` instance from the `SDWebImagePrefetcher` class - [6c409cd](https://github.com/rs/SDWebImage/commit/6c409cd)
- `SDWebImageManager` uses the shared instance of `SDWebImageDownloader` - [0772019](https://github.com/rs/SDWebImage/commit/0772019)
- Refactor the cancel logic - [#771](https://github.com/rs/SDWebImage/pull/771) [6d01e80](https://github.com/rs/SDWebImage/commit/6d01e80) [23874cd](https://github.com/rs/SDWebImage/commit/23874cd) [a6f11b3](https://github.com/rs/SDWebImage/commit/a6f11b3)
- Added method `SDWebImageManager cachedImageExistsForURL:` to check if an image exists in either the disk OR the memory cache - [#644](https://github.com/rs/SDWebImage/pull/644)
- Added option to use the cached image instead of the placeholder for `UIImageView`. Replaces [#541](https://github.com/rs/SDWebImage/pull/541) - [#599](https://github.com/rs/SDWebImage/issues/599) [30f6726](https://github.com/rs/SDWebImage/commit/30f6726)
- Created workspace + added unit tests target
- Updated documentation - [#476](https://github.com/rs/SDWebImage/issues/476) [#384](https://github.com/rs/SDWebImage/issues/384) [#526](https://github.com/rs/SDWebImage/issues/526) [#376](https://github.com/rs/SDWebImage/pull/376) [a8f5627](https://github.com/rs/SDWebImage/commit/a8f5627)

## Bugfixes
- Fixed Xcode 6 builds - [#741](https://github.com/rs/SDWebImage/pull/741) [0b47342](https://github.com/rs/SDWebImage/commit/0b47342)
- Fixed `diskImageExistsWithKey:` deadlock - [#625](https://github.com/rs/SDWebImage/issues/625) [6e4fbaf](https://github.com/rs/SDWebImage/commit/6e4fbaf)
For consistency, added async methods in `SDWebImageManager` `cachedImageExistsForURL:completion:` and `diskImageExistsForURL:completion:`
- Fixed race condition that causes cancellation of one download operation to stop a run loop that is now used for another download operation. Race is introduced through `performSelector:onThread:withObject:waitUntilDone:` - [#698](https://github.com/rs/SDWebImage/pull/698)
- Fixed race condition between operation cancelation and loading finish - [39db378](https://github.com/rs/SDWebImage/commit/39db378) [#621](https://github.com/rs/SDWebImage/pull/621) [#783](https://github.com/rs/SDWebImage/pull/783)
- Fixed race condition in SDWebImageManager if one operation is cancelled - [f080e38](https://github.com/rs/SDWebImage/commit/f080e38) [#699](https://github.com/rs/SDWebImage/pull/699)
- Fixed issue where cancelled operations aren't removed from `runningOperations` - [#68](https://github.com/rs/SDWebImage/issues/68)
- Should not add url to failedURLs when timeout, cancel and so on - [#766](https://github.com/rs/SDWebImage/pull/766) [#707](https://github.com/rs/SDWebImage/issues/707)
- Fixed potential *object mutated while being enumerated* crash - [#727](https://github.com/rs/SDWebImage/pull/727) [#728](https://github.com/rs/SDWebImage/pull/728) (revert a threading fix from [#727](https://github.com/rs/SDWebImage/pull/727))
- Fixed `NSURLConnection` response statusCode not valid (e.g. 404), downloader never stops its runloop and hangs the operation queue - [#735](https://github.com/rs/SDWebImage/pull/735)
- Fixed `SDWebImageRefreshCached` bug for large images - [#744](https://github.com/rs/SDWebImage/pull/744)
- Added proper handling for `SDWebImageDownloaderLowPriority` - [#713](https://github.com/rs/SDWebImage/issues/713) [#745](https://github.com/rs/SDWebImage/issues/745)
- Fixed fixing potential bug when sending a nil url for UIButton+WebCache - [#761](https://github.com/rs/SDWebImage/issues/761) [#763](https://github.com/rs/SDWebImage/pull/763)
- Fixed issue [#529](https://github.com/rs/SDWebImage/pull/529) - if the `cacheKeyFilter` was set, this was ignored when computing the `scaledImageForKey`. For most of the developers that did not set `cacheKeyFilter`, the code will work exactly the same - [eb91fdd](https://github.com/rs/SDWebImage/commit/eb91fdd)
- Returning error in setImage completedBlock if the url was nil. Added `dispatch_main_async_safe` macro - [#505](https://github.com/rs/SDWebImage/issues/505) [af3e4f8](https://github.com/rs/SDWebImage/commit/af3e4f8)
- Avoid premature completion of prefetcher if request fails - [#751](https://github.com/rs/SDWebImage/pull/751)
- Return nil from `SDScaledImageForKey` if the input image is nil - [#365](https://github.com/rs/SDWebImage/issues/365) [#750](https://github.com/rs/SDWebImage/pull/750)
- Do not load placeholder image if `SDWebImageDelayPlaceholder` option specified - [#780](https://github.com/rs/SDWebImage/pull/780)
- Make sure we call the `startPrefetchingAtIndex:` method from main queue - [#694](https://github.com/rs/SDWebImage/pull/694)
- Save image in cache before calling completion block - [#700](https://github.com/rs/SDWebImage/pull/700)
- Fixed arm64 warnings - [#685](https://github.com/rs/SDWebImage/pull/685) [#720](https://github.com/rs/SDWebImage/pull/720) [#721](https://github.com/rs/SDWebImage/pull/721) [#687](https://github.com/rs/SDWebImage/pull/687)
- Improved logging - [#721](https://github.com/rs/SDWebImage/pull/721)
- Added `SDWebImageCompat.m` to `SDWebImage+MKAnnotation` target

## [3.6 Fix and cleanup on Mar 24th, 2014](https://github.com/rs/SDWebImage/releases/tag/3.6)

## [3.5.4 ARM64 Support on Feb 24th, 2014](https://github.com/rs/SDWebImage/releases/tag/3.5.4)

## [3.5.3 on Jan 7th, 2014](https://github.com/rs/SDWebImage/releases/tag/3.5.3)

## [3.5.2 on Jan 2nd, 2014](https://github.com/rs/SDWebImage/releases/tag/3.5.2)

## [3.5.1 on Dec 3rd, 2013](https://github.com/rs/SDWebImage/releases/tag/3.5.1)

## [3.5 WebP Target, iOS 7, Fixes on Oct 4th, 2013](https://github.com/rs/SDWebImage/releases/tag/3.5)

- Fix iOS 7 related issues
- Move `WebP` support to a dedicated target
- Removed strong reference to `UIImageView` which was causing a crash in the nested block
- Fix timeout issue
- Add some methods that allow to check if an image exists on disk without taking it off disk and decompressing it first

## [3.4 Animated image category, bug fixes on Aug 13th, 2013](https://github.com/rs/SDWebImage/releases/tag/3.4)

- Add `calculateSizeWithCompletionBlock`
- Add multiple download of images for animationImages property of `UIImageView`
- Add background task for disk cleanup [#306](https://github.com/rs/SDWebImage/issues/306) 
- Fix dead thread issue on iOS 5 [#444](https://github.com/rs/SDWebImage/pull/444), [#399](https://github.com/rs/SDWebImage/issues/399), [#466](https://github.com/rs/SDWebImage/issues/466)
- Make IO operations cancelable to fix perf issue with heavy images [#462](https://github.com/rs/SDWebImage/issues/462) 
- Fix crash `Collection <__NSArrayM: ...> was mutated while being enumerated.` [#471](https://github.com/rs/SDWebImage/pull/471) 

## [3.3 WebP, Animated GIF and more on Jun 14th, 2013](https://github.com/rs/SDWebImage/releases/tag/3.3)

- WebP image format support [#410](https://github.com/rs/SDWebImage/issues/410)
- Animated GIF support [#375](https://github.com/rs/SDWebImage/pull/375)
- Custom image cache search paths [#156](https://github.com/rs/SDWebImage/pull/156)
- Bug fixes

## [3.2 Bug fixes on Mar 13th, 2013](https://github.com/rs/SDWebImage/releases/tag/3.2)

- `SDWebImageRefreshCached` download option [#326](https://github.com/rs/SDWebImage/pull/326)
- New `SDWebImageManager` delegate methods [ebd63a88c1](https://github.com/rs/SDWebImage/commit/ebd63a88c116ac7acfbeded5c84d0fffa2443438)
- Fix long standing issue with alpha en JPEGs [#299](https://github.com/rs/SDWebImage/pull/299)
- Add synchronous disk-cache loading method [#297](https://github.com/rs/SDWebImage/pull/297)
- Fix `SDWebImageCacheMemoryOnly` flag
- Bug fixes

## [3.1 Bug fixes on Jan 21st, 2013](https://github.com/rs/SDWebImage/releases/tag/3.1)

## [3.0 Complete rewrite on Nov 29th, 2012](https://github.com/rs/SDWebImage/releases/tag/3.0)

- Complete rewrite of the library using `GCD`, `ARC`, `NSCache` and blocks
- Drop compatibility with iOS 3 and 4

## [2.7.4 Bug fixes on Nov 14th, 2012](https://github.com/rs/SDWebImage/releases/tag/2.7.4)

## [2.7.3 on Nov 3rd, 2012](https://github.com/rs/SDWebImage/releases/tag/2.7.3)

## [2.7.2 on Oct 23rd, 2012](https://github.com/rs/SDWebImage/releases/tag/2.7.2)

## [2.7.1 on Oct 19th, 2012](https://github.com/rs/SDWebImage/releases/tag/2.7.1)

## [2.7 on Sep 8th, 2012](https://github.com/rs/SDWebImage/releases/tag/2.7)

## [2.6 on May 4th, 2012](https://github.com/rs/SDWebImage/releases/tag/2.6)

## [2.5 on Mar 22nd, 2012](https://github.com/rs/SDWebImage/releases/tag/2.5)

## [2.4 on Oct 1st, 2011](https://github.com/rs/SDWebImage/releases/tag/2.4)

## [2.3 on Sep 16th, 2010](https://github.com/rs/SDWebImage/releases/tag/2.3)

## [2.2 on Aug 29th, 2010](https://github.com/rs/SDWebImage/releases/tag/2.2)

## [2.1.0 on Jun 12th, 2010](https://github.com/rs/SDWebImage/releases/tag/2.1.0)

## [2.1 on Jun 12th, 2010](https://github.com/rs/SDWebImage/releases/tag/2.1)

## [2.0.0 on Jun 9th, 2010](https://github.com/rs/SDWebImage/releases/tag/2.0.0)

## [2.0 on Jun 9th, 2010](https://github.com/rs/SDWebImage/releases/tag/2.0)

## [1.0.0 on Dec 31st, 2009](https://github.com/rs/SDWebImage/releases/tag/1.0.0)

## [1.0 on Dec 31st, 2009](https://github.com/rs/SDWebImage/releases/tag/1.0)