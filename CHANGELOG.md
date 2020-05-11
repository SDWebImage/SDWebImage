## [5.8.0 - Transform original cache and more, on May 11th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.8.0)
See [all tickets marked for the 5.8.0 release](https://github.com/SDWebImage/SDWebImage/milestone/69)

### Features

#### Transformer
- Add query original cache for transformed image without downloading #2992
- This can be used to query the original image from cache then do transforming when transformed key cache miss, without any downloading happened.

#### Animated Image
- Added autoplay control property to AnimatedImageView (autoPlayAnimatedImage) #3003

#### Manager
- Mark the black list formal error code, support remove the failed URL from black list #2997
- Polish the error description between image decode failed and image size is 0 #3005

#### Downloader
- Add the convenient request/response modifier, which provide HTTP header directly #2990

#### View Category
- Added the convenient transition options for macOS user. Deprecate the old timingFunction, which can use System API to achieve #2985
- Feature pass the set operation key into context option from upstream. Fix the potential retain cycle if user use custom manager #2986

#### Coder
- Feature: Encoding options supports embed thumbnail (works for JPEG/HEIF/AVIF) #2988

#### Project
- Support the SwiftPM Objective-C user to use `#improt <SDWebImage/SDWebImage.h>` #2987

## [5.7.4 - 5.7 Patch, on May 6th, 2020](https://github.com/SDWebImage/SDWebImage/releases/tag/5.7.4)
See [all tickets marked for the 5.7.4 release](https://github.com/SDWebImage/SDWebImage/milestone/71)

### Fixes
- Fix the issue that NSOperation conforms to `SDWebImageOperation` check failed. Fix cancelling prefetcher hung up #2999 #2998

## [5.7.3 - 5.7 Patch, on Apr 21st, 2020](https://github.com/SDWebImage/SDWebImage/releases/tag/5.7.3)
See [all tickets marked for the 5.7.3 release](https://github.com/SDWebImage/SDWebImage/milestone/70)

### Fixes
- Fix the encoding options which does not passthrough the correct value to ImageIO #2989

## [5.7.2 - 5.7 Patch, on Apr 11th, 2020](https://github.com/SDWebImage/SDWebImage/releases/tag/5.7.2)
See [all tickets marked for the 5.7.2 release](https://github.com/SDWebImage/SDWebImage/milestone/68)

### Fixes
- SDAnimatedImageView animation rendering should not use CGContext force decoding, use `kCGImageSourceShouldCacheImmediately` instead which can avoid OOM for large number of GIFs #2977
- Fix that when first play animated image and use maxBufferSize to 0, the calculation does not works (The CGImage is nil) #2982

### Project
- Rename the private header `UIColor+HexString` and `NSBezierPath+SDRoundedCorners` with SD prefix, to avoid the conflict when using CocoaPods #2983

## [5.7.1 - 5.7 Patch, on Apr 8th, 2020](https://github.com/SDWebImage/SDWebImage/releases/tag/5.7.1)
See [all tickets marked for the 5.7.1 release](https://github.com/SDWebImage/SDWebImage/milestone/67)

### Fixes
- Don't copy attributes from originalImage to transformedImage when caching transformedImage #2976. Thanks @bdaz
- Fix the wrong value assignment for SDAnimatedImageView code on macOS, warning #2974

## [5.7.0 - Query Cache Type and Encoding Options, on Apr 4th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.7.0)
See [all tickets marked for the 5.7.0 release](https://github.com/SDWebImage/SDWebImage/milestone/66)

### Features

#### Cache
- Added the async version API to query disk image data only
- Added the sync API to query disk image with context and options, which matches the async version

#### Coder
- Feature supports encoding options like max file size, max pixel size, as well as background color when using JPEG for alpha image #2972
- You can use `.encodeMaxFileSize` to limit the desired lossy file size, better than compression quality
- You can use `.encodeMaxPixelSize` to limit the pixel size, like thumbnail encoding

#### Transformer
- Refactory the current thumbnail && transformer about cache key. Developer should have the API to calculate the cache key from thumbnail or transformer, not hard-coded. #2966

#### Context Option
- Added new query cache type support, including the SDImageCache API and context option #2968
- You use `.queryCacheType` to query image from memory/disk/both cache during image pipeline loading

### Fixes
- Fix the issue for Carthage/SwiftPM framework version symbols, this should match the framework name SDWebImage, or will get a link error when used #2971 #2969
- Simplify the xattr helper method's code with modern Objective-C syntax #2967. Thanks @huangboju 

### Changes
- Change the behavior to return the abstract type for unknown image format, this can solve the accident issue for custom coder who provide a new format #2973

## [5.6.1 - 5.6 Patch, on Mar 13th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.6.1)
See [all tickets marked for the 5.6.1 release](https://github.com/SDWebImage/SDWebImage/milestone/65)

### Performances
- Keep the progressive decoding process only exist one per image download. Cancel the unused progressive decoding when full pixel data is available. #2483

### Fixes
- Fix the NotificationCenter does not remove the observer and little private header garden #2959

## [5.6.0 - URLSession Metrics && Vector Format, on Mar 5th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.6.0)
See [all tickets marked for the 5.6.0 release](https://github.com/SDWebImage/SDWebImage/milestone/63)

### Features

#### URLSession Metrics
- Added the URLSessionTaskMetrics support for downloader && operation, which can be used for network metrics #2937
- Typically you use custom operation class to collect all metrics in your app. You can also collect metrics for single url request level. Check the #2937 example code to grab the download token and check metrics.

#### Vector Image
- Feature - better support for vector format detection, now PDF rasterized bitmap is built-in #2936
- Pass `.thumbnailPixelSize` to control the PDF bitmap size. If you want vector PDF rendering, you still need to use [SDWebImagePDFCoder](https://github.com/SDWebImage/SDWebImagePDFCoder).
- Vector image like SVG (via [SDWebImageSVGCoder](https://github.com/SDWebImage/SDWebImageSVGCoder)) and PDF (via [SDWebImagePDFCoder](https://github.com/SDWebImage/SDWebImagePDFCoder)), or system symbol images, can be detected by new API `sd_isVector`.
- Vector image does not pass to transformer by default, because they support dynamic size changing. Pass `.transformVectorImage` option to allow transformation.

#### Cache
- Add a better check to handle the cases when call `storeImage` without imageData #2953
- Which means, if you store image to disk without data, we will use extra information via `sd_imageFormat` or custom image class, to choose the the image format (including GIF and PDF) for encoding. Previously we only encode it into PNG or JPEG.

#### Context Option
- Feature add context option for cache, loader and coder, deprecated SDWebImageContextCustomManager #2955
- This makes it easy to use custom loader, cache, and decoder, without need to create a dummy SDWebImageManager instance.

### Fixes
- Fix the rare case when call `SDWebImageDownloaderOperation.cancel`, the completion block may callback twice #2954

### Warnings
- Suppress the deprecation warning when min deployment target version set to iOS 13+ or macCatalyst
- Complete all the SDWebImage error code with the localized description, make it easy for debugging #2948

## [5.5.2 - 5.5 Patch, on Jan 26th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.5.2)
See [all tickets marked for the 5.5.2 release](https://github.com/SDWebImage/SDWebImage/milestone/62)

### Fixes
- Fix the issue that `maxBufferSize` property does not correctly works for `SDAnimatedImageView` #2934

## [5.5.1 - 5.5 Patch, on Jan 18th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.5.1)
See [all tickets marked for the 5.5.1 release](https://github.com/SDWebImage/SDWebImage/milestone/59)

### Fixes
- Fix the SDAnimatedImageView's progressive animation bug, which reset the frame index to 0 each time new frames available #2931

## [5.5.0 - Thumbnail Decoding && Core Image, on Jan 16th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.5.0)
See [all tickets marked for the 5.5.0 release](https://github.com/SDWebImage/SDWebImage/milestone/55)

### Features

#### Thumbnail Decoding
- Supports to load the large web image with thumbnail, control the limit size and aspect ratio #2922 #2810
- Better than resize transformer, which does not allocate full pixel RAM and faster on CPU. If you've already use transformer to generate thumbnail, you'd better have a try
- Works for both animated images and progressive images, each frame using the thumbnail decoding
- Applies for Vector Format like SVG/PDF as well, see more in [Coder Plugin List](https://github.com/SDWebImage/SDWebImage/wiki/Coder-Plugin-List)

#### Core Image
- Support all transformer method on CIImage based UIImage/NSImage #2918
- For CIImage based UIImage/NSImage, using the CIFilter to take shortcut, which is faster and lazy (rasterize on demand)

#### Cache
- Support to use the creation date and the change date to determine the disk cache expire date compare #2915

### Performances
- Using UIGraphicsImageRenderer on iOS 10+, save memory when image bitmap is RGB(-25%) or Grayscale(-75%) #2907
- Provide the polyfill APIs for firmware iOS 10- and macOS. If you already use `SDGraphicsBeginImageContext` for drawing, you'd better replace that instead.

### Fixes
- Fix Gaussian Blur's bug which take half of the blur radius compared to the standard, should match Core Image's behavior #2927

## [5.4 Patch, on Jan 18th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.4.3)
See [all tickets marked for the 5.4.3 release](https://github.com/SDWebImage/SDWebImage/milestone/61)

### Fixes
- Fix the SDAnimatedImageView's progressive animation bug, which reset the frame index to 0 each time new frames available #2931

## [5.4.2 - 5.4 Patch, on Jan 7th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.4.2)
See [all tickets marked for the 5.4.2 release](https://github.com/SDWebImage/SDWebImage/milestone/58)

### Fixes
- SDAnimatedImage now only keep the animated coder when frame count >=1 , else we will behave like UIImage to save RAM usage #2924

## [5.4.1 - 5.4 Patch, on Dec 27th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.4.1)
See [all tickets marked for the 5.4.1 release](https://github.com/SDWebImage/SDWebImage/milestone/56)

### Fixes
- Fix the issue that "There may be no complete callback when download the picture of the local path" #2917

## [5.4.0 Extended Cache Metadata, on Dec 6th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.4.0)
See [all tickets marked for the 5.4.0 release](https://github.com/SDWebImage/SDWebImage/milestone/51)

### Features

#### Cache
- Allows advanced user to read/write extended metadata associated with image data from disk cache #2898
- This metadata will be processed at the same time when store or query the image. The metadata should conforms to `NSCoding` for archive and unarchive.

#### Manager
- Add `SDWebImageWaitStoreCache`, which wait for all the async disk cache written finished and then callback, useful for advanced user who want to touch the cache right in completion block #2900

### Fixes
- Using one global function to ensure we always sync all the UIImage category associated object status correctly inside our framework #2902
- Fix the thread safe issue with Downloader and DownloaderOperation during cancel #2903

## [5.3 Patch, on Jan 18th, 2020](https://github.com/rs/SDWebImage/releases/tag/5.3.4)
See [all tickets marked for the 5.3.4 release](https://github.com/SDWebImage/SDWebImage/milestone/60)

### Fixes
- Fix the SDAnimatedImageView's progressive animation bug, which reset the frame index to 0 each time new frames available #2931

## [5.3 Patch, on Dec 3rd, 2019](https://github.com/rs/SDWebImage/releases/tag/5.3.3)
See [all tickets marked for the 5.3.3 release](https://github.com/SDWebImage/SDWebImage/milestone/54)

### Fixes
- Fix the crash when using NSCache delegate with SDMemoryCache default implementation on dealloc #2899

## [5.3 Patch, on Nov 22nd, 2019](https://github.com/rs/SDWebImage/releases/tag/5.3.2)
See [all tickets marked for the 5.3.2 release](https://github.com/SDWebImage/SDWebImage/milestone/53)

### Fixes
- Fix animated image playback bugs that cause rendering frame is previous frame index #2895. Thanks @ZXIOU 

## [5.3 Patch, on Nov 9th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.3.1)
See [all tickets marked for the 5.3.1 release](https://github.com/SDWebImage/SDWebImage/milestone/52)

### Fixes
- Fix the case even when Animated Image View is not visible, user call startAnimating can still do animation #2888

## [5.3.0 Animated Player & Data Decryptor, on Nov 6th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.3.0)
See [all tickets marked for the 5.3.0 release](https://github.com/SDWebImage/SDWebImage/milestone/45)

### Features

#### Animated Image
- Refactoring the SDAnimatedImageView with player backend called `SDAnimatedImagePlayer`, make it easier for common usage. #2882
- The player use protocol based implementation, which can be used for many scenarios, like WatchKit, CALayer, or even SwiftUI. See [wiki](https://github.com/SDWebImage/SDWebImage/wiki/Advanced-Usage#animated-player-530)
- Supports the control of AnimatedImage View/Player 's play rate #2885
- Supports the runloop mode control for macOS. Which can be useful when user want to pause animation when drag the mouse, or presenting modal window #2886

#### Data Decryptor
- Decrypt the encrypted image data after download and just before decoding. #2866
- Provide a built-in convenience for Base64-encoded image data. See [wiki](https://github.com/SDWebImage/SDWebImage/wiki/Advanced-Usage#data-decryptor-530)

#### Response Modifier
- Modify the HTTP response after download, paired with request modifier #2866
- Can be used for custom HTTP header check, mock data, etc. See [wiki](https://github.com/SDWebImage/SDWebImage/wiki/How-to-use#use-response-modifier-530)

## [5.2 Patch, on Oct 27th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.2.5)
See [all tickets marked for the 5.2.5 release](https://github.com/SDWebImage/SDWebImage/milestone/50)

### Fixes
- Fix macOS SDWebImageIndicator center layout issue when indicator was initialized with 0 frame #2875

## [5.2 Patch, on Oct 27th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.2.4)
See [all tickets marked for the 5.2.4 release](https://github.com/SDWebImage/SDWebImage/milestone/49)

### Fixes
- Fix the regression issue that SDAnimatedImageView on macOS will change the wrong duration speed when pause and resume again #2873
- Fix SDAnimatedImage on macOS use extra animates property check, which is not intuitive and cause extra setup before usage #2874

## [5.2 Patch, on Oct 9th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.2.3)
See [all tickets marked for the 5.2.3 release](https://github.com/SDWebImage/SDWebImage/milestone/48)

### Fixes
- Revert the change for APNG constants fix for iOS 8 devices which cause crash #2863

## [5.2 Patch, on Oct 2rd, 2019](https://github.com/rs/SDWebImage/releases/tag/5.2.2)
See [all tickets marked for the 5.2.2 release](https://github.com/SDWebImage/SDWebImage/milestone/47)

### Fixes
- Fix warnings when deployment target version set to iOS 13+ #2860 #2859

## [5.2 Patch, on Oct 1st, 2019](https://github.com/rs/SDWebImage/releases/tag/5.2.1)
See [all tickets marked for the 5.2.1 release](https://github.com/SDWebImage/SDWebImage/milestone/46)

### Fixes
- Make the SDWebImageDownloadToken to not retain the completion block so that user don't need weak-strong dance #2856 #2855

### Tests
- Try to fix the test case `test15DownloaderLIFOExecutionOrder` #2857

## [5.2.0 - Mac Catalyst && HEIC Animation, on Sep 27th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.2.0)
See [all tickets marked for the 5.2.0 release](https://github.com/SDWebImage/SDWebImage/milestone/43)

### Features

#### Mac Catalyst
- Full compatible with Catalyst (UIKit for macOS)
- Supports CococaPods and SwiftPM only. Carthage need their own toolchain upgrade in the future
- Provide the build script to build xcframework contains Mac Catalyst variant, see [Installation Guide](https://github.com/SDWebImage/SDWebImage/wiki/Installation-Guide).

#### Image Coder
- Supports HEIC sequence (animated) image on iOS 13/macOS 10.15+ #2849
    - Note the HEIC animated coder does not enable by default. Add `SDImageHEICCoder` if you need the animation.
- Refactor APNG and GIF coder implementation with abstract base class #2846
    - Now we use `SDImageIOAnimatedCoder` base class for all animated Image/IO coder implementation. Developer can get use of this as well.

#### Animated Image
- Support to clear frame buffer or reset frame index when stopped for SDAnimatedImageView #2815

### Fixes
- Fix the downloader LIFO order inverse issue when adding new urls during previous url query #2852 #2823
- Fix the macOS SDAnimatedImageRep to match Netscape standard of GIF loop count, which should use 1 when there are no loop count information #2847 #2155

## [5.1 Patch, on Sep 5th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.1.1)
See [all tickets marked for the 5.1.1 release](https://github.com/SDWebImage/SDWebImage/milestone/44)

### Fixes

- Fix that some option mask check with local BOOL variable, error result on 32 bit device. #2819 #2817
- Fix the macOS that SDAnimatedImageView does not works for imageScaling and imageAlignment properties #2820
- Fix the case when SDAnimatedImageView dealloc on the fetch queue, will cause it trigger the UIKit/AppKit method on non-main queue and captured by UI Main Thread Checker #2825

## [5.1.0 - SwiftPM and more, on Aug 3rd, 2019](https://github.com/rs/SDWebImage/releases/tag/5.1.0)
See [all tickets marked for the 5.1.0 release](https://github.com/SDWebImage/SDWebImage/milestone/38)

### Features

#### Swift Package Manager

- Add support for Swift Package Manager #2756

#### Options Processor

- Supports global control on options and context for individual image request #2736

#### Context Option

- Supports store original image to cache for transformer via `SDWebImageContextOriginalStoreCacheType` #2590
- Add a new option `SDWebImageMatchAnimatedImageClass`, to ensure we always match the custom image class instead of UIImage/NSImage class #2801

#### Cache

- Expose the memoryCache and diskCache object on `SDImageCache`, Make it useful for user who have custom property beyond `SDImageCacheConfig` #2779

### Fixes

- Fix SDAnimatedImageView's frame buffer bug when display link is pause #2782
- Fix the bug that UIButton setBackgroundImage convenient method does not pass the options arg to next function call #2785
- Add a autoreleasepool when prefetch many images #2792
- Feature supports dynamic style indicator for iOS 13, fix indicator color on macOS 10.14+ #2753
- Fix for CocoaPods modular headers warning by removing the custom modulemap #2749

### Project

- Follow App Store submit rule, upgrade the minimum Xcode version to Xcode 10.0 #2780
- Provide a script target to directly build all SDWebImage framework and generate all in one XCFramework from Xcode 11 #2764

### Notable Behavior Changes

- Ensure we always callback user's completion block even when cancelled with `SDWebImageErrorCancelled` error code #2692

This may effect some users. In previous 4.0~5.0 version, we will not callback completion block when we receive `cancel` call. (including all View Category/Cache/Manager/Downloader APIs)

But from 5.1, we always callback on this case with error code `SDWebImageErrorCancelled`. You can filter this error code if you don't care about cancel.

This change makes usages like Dispatch Group, observer, or any logic which relay on the completion's callback become acceptable, which is not reliable and will cause issue in previous versions.

- Change that the `sd_imageProgress` property to not auto-create instance by framework #2763

Now, we don't create the NSProgress object from internal method call, this does not affect user's KVO usage.

- Change the default value of accept request header #2772

Now, the default HTTP header filed `Accept`, use `image/*,*/*;q=0.8`, instead of `image/*;q=0.8`.

## [5.0 Patch, on Jun 5th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.6)
See [all tickets marked for the 5.0.6 release](https://github.com/SDWebImage/SDWebImage/milestone/42)

#### Fixes
- Fix the SDAnimatedImageRep which use the deprecated API and cause compile issue on Xcode 11 #2745

## [5.0 Patch, on Jun 3rd, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.5)
See [all tickets marked for the 5.0.5 release](https://github.com/SDWebImage/SDWebImage/milestone/41)

#### Project
- Fix the Static Library target issue of headers, which cause the integrated application failed to Archive because of copied headers #2741

## [5.0 Patch, on May 29th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.4)
See [all tickets marked for the 5.0.4 release](https://github.com/SDWebImage/SDWebImage/milestone/40)

#### Fixes
- Fix get button background image operation key bug #2737
- Fix that `CGImageDestinationCreateWithData` 0 count arg will log a warning #2739

#### Tests
- Fix the example NSLog issue, and replace the unavailable test image dataset #2740

## [5.0 Patch, on May 16th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.3)
See [all tickets marked for the 5.0.3 release](https://github.com/SDWebImage/SDWebImage/milestone/39)

#### Fixes
- Fix SDWebImageDecodeFirstFrameOnly flag is ignored when image loaded from cache #2725
- Fix that SDAnimatedImageView initWithImage will skip the initialize logic and crash #2728
- Replace if judge with MAX() function in scale less than 1 #2710

#### Project
- Replace the private prefix header files with the manually import for each implementation files #2723

#### Tests
- Added many test case to ensure the code behavior and coverage #2711

#### Documentation
- Update the documentation coverage for jazzy. Use the correct format to provide class/protocol/type API Documentation #2722

## [5.0 Patch, on Apr 25th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.2)
See [all tickets marked for the 5.0.2 release](https://github.com/SDWebImage/SDWebImage/milestone/37)

#### Fixes
- Fix the bug of SDAnimatedImageView on macOS, which can only render `SDAnimatedImage` but not normal NSImage (including animated image) #2706
- Fix that `CGImageCreateDecoded:orientation:` use the wrong aspect ratio when orientation is left/leftMirrored/right/rightMirrored #2708
- Fix one bug of sd_colorAtPoint:, which set the alpha value default to 255 and should be 1. #2708

#### Documentation
- Fixes typo in SDImageCacheConfig maxDiskAge info #2699

## [5.0 Patch, on Apr 11th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.1)
See [all tickets marked for the 5.0.1 release](https://github.com/SDWebImage/SDWebImage/milestone/36)

#### Fixes
- Fixes crash for apng coder when properties are nil #2691
- Fix rounded corner bug which leads to image upside down #2673
- Fix tint image bug which leads to image upside down #2674

#### Project
- Fix the Travis-CI script about code coverage submit #2676

## [5.0.0 Major release - Customizable SDWebImage, on Apr 2nd, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.0)
See [all tickets marked for the 5.0.0 release](https://github.com/SDWebImage/SDWebImage/milestone/15)

### Features

#### Animated Image
- Introduce `SDAnimatedImageView` and `SDAnimatedImage` for full stack solution of animated images.
- Supports custom coders for nearly every animated image format.
- Supports progressive loading for animated images.
- iOS/tvOS/macOS cross-platform support.

#### Transformer
- Using transformer to apply image processing after image was loaded.
- Built-in transformer for common usage: Rounded Corner, Resize, Crop, Flip, Rotate, Tint Color, Blur Effect, Core Image Filter...
- Convenient category methods for `UIImage`/`NSImage`

#### Custom Loader
- Using `SDImageLoader` protocol to implements your own image loader.
- Not limited on HTTP, you can even using SDWebImage with PhotoKit and third-party SDKs.
- Supports multiple loaders at the same time when using `SDImageLoadersManager`.

#### Custom Cache
- Using `SDImageCache` protocol to implement your own image cache.
- Standalone disk cache and memory cache class for advanced usage and customization.
- Supports multiple caches at the same time when using `SDImageCachesManager`.

#### Indicator
- Use indicator to provide a loading view, customizable.
- Built-in Activity Indicator and Progress Indicator.
- iOS/tvOS/macOS cross-platform support.

#### Plugins
- All external image format coders are plugins. Supports WebP, HEIF, BPG, FLIF, SVG, PDF... Choose what you need in: [Coder Plugin List](https://github.com/SDWebImage/SDWebImage/wiki/Coder-Plugin-List)
- PhotoKit loader as a plugin: [SDWebImagePhotosPlugin](https://github.com/SDWebImage/SDWebImagePhotosPlugin)
- FLAnimatedImage integration as a plugin: [SDWebImageFLPlugin](https://github.com/SDWebImage/SDWebImageFLPlugin)
- YYImage/YYCache integration as a plugin: [SDWebImageYYPlugin](https://github.com/SDWebImage/SDWebImageYYPlugin)

### Improvements

#### Swift
- Better Swift support with some manual renaming APIs.
- Full nullability annotation.
- Using class property for shared instance.
- Using `NS_TYPED_ENUM` and `NS_STRING_ENUM` for better generated APIs.

#### API
- Using context option to control detail behavior for each image request beyond the limit of enums.
- Using prefetcher to manage token (list of URL requests) to avoid conflict.
- Use request modifier to modify constructed URLRequest.

### Project

- Supports the latest Xcode 10.
- Supports iOS 8.0+/tvOS 9.0+/watchOS 2.0+/macOS 10.10+.
- MapKit support for Carthage moved the standalone `SDWebImageMapKit` target.
- Using module map and umbrella headers.

### Migration

Check [5.0 migration guide](https://github.com/SDWebImage/SDWebImage/wiki/5.0-Migration-guide) for the migration from 4.x to 5.x.


## [5.0.0-beta6 - 5.0 Beta, on Mar 15th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.0-beta6)
See [all tickets marked for the 5.0.0-beta6 release](https://github.com/rs/SDWebImage/milestone/30)

#### Fixes
- Fix the issue that SDWebImagePrefetch in 5.x, will submit all prefetch URLs to manager without any concurrent limit #2631
- Fix the current transformer cache key generating rules, try to keep the image file extension #2635

#### Project
- Move some internal classes into private header files, make it easy to maintain the code #2634

## [4.4.6 - 4.4 patch, on Feb 26th, 2019](https://github.com/SDWebImage/SDWebImage/releases/tag/4.4.6)
See [all tickets marked for the 4.4.6 release](https://github.com/SDWebImage/SDWebImage/milestone/33)

#### Fixes
- Fix the unused user header search path warning for CocoaPods 1.6.0. #2622
- Fix that WebP with custom ICC Profile will randomly crash, because `CGColorSpaceCreateWithICCProfile` does not copy the ICC data pointer #2621
- Fix the issue when WebP contains the ICC Profile with colorSpace other than RGB, which cause the CGImageCreate failed #2627

#### Project
- Update the libwebp dependency to support using 1.0 version and above #2625

#### Performances
- Nil imageData before decode process to free memory #2624

## [5.0.0-beta5 - Customizable SDWebImage, on Jan 31st, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.0-beta5)
See [all tickets marked for the 5.0.0-beta5 release](https://github.com/rs/SDWebImage/milestone/32)

#### Fixes
- Fix encoding options does not works #2602
- Remove unnecessary CGImage check when encode first frame #2609

## [4.4.5 - 4.4 patch, on Jan 31st, 2019](https://github.com/SDWebImage/SDWebImage/releases/tag/4.4.5)
See [all tickets marked for the 4.4.5 release](https://github.com/SDWebImage/SDWebImage/milestone/31)

#### Fixes
- Revert the modular framework, try to fix some user's install issue when using SDWebImage in prefix header #2604
- Fix wrong decompression scale calculation #2608
- Fix shouldDecode check when image format is GIF #2606
- Fix modify data pointer if webp image scaled down #2607

## [5.0.0-beta4 - Customizable SDWebImage, on Jan 26th, 2019](https://github.com/rs/SDWebImage/releases/tag/5.0.0-beta4)
See [all tickets marked for the 5.0.0 release](https://github.com/rs/SDWebImage/milestone/15)

#### Features
- Expose the graphics helper method for coder plugin author and fix scale issue #2523

#### Performances
- Decrease animated decode times when cache enable #2468
- Remove kCGImageSourceShouldCache option when creating image source #2472
- Add autoreleasepool to release autorelease objects in advance when using GCD #2474

#### Fixes
- Add protect when custom animated image class image data is nil during progressive animation check #2466
- Fix background download #2500

#### Project
- Merged targets + MapKit dedicated target for Carthage installs #2476. Carthage user now does not enable MapKit support by default.
- Upgrade Xcode 10 + using xcconfig for project settings #2494

#### Notable Changes (from beta3)

Behavior:

- Move webp component (and libwebp dependency) to SDWebImage/SDWebImageWebPCoder #2469. Any user who use WebP in 5.0.0 should add [SDWebImageWebPCoder](https://github.com/SDWebImage/SDWebImageWebPCoder) to your Podfile or Cartfile instead.
- Refactory cache path about namespace && final cache directory #2535. Now the default disk cache path was moved to suitable path with the namespace.
- Use the memory bytes size, instead of pixel size to calculate the memory cost function #2568. Now the memory cost function use bytes size instead of pixels count.

Swift Only:

- Fix the accident changes of Swift API naming for `sd_imageDataAsFormat:` #2517

You can always check [5.0 migration guide](https://github.com/SDWebImage/SDWebImage/wiki/5.0-Migration-guide) for the latest information for these changes.

## [5.0.0-beta3 - Customizable SDWebImage, on Aug 30th, 2018](https://github.com/rs/SDWebImage/releases/tag/5.0.0-beta3)
See [all tickets marked for the 5.0.0 release](https://github.com/rs/SDWebImage/milestone/15)

#### Features
- Minimum progress interval config for `SDWebImageDownloader` #2415 #2437 1d8454d
- Feature disk cache migration from 4.x #2417 #2433
- Add `SDImageFormatHEIF` represent `mif1` && `msf1` brands #2423 (imported from 4.4.3)
- Add default `HTTP User-Agent` for specific system #2409 (imported from 4.4.3)
- Replace `valueForKey` with `objectForKey` when access NSDictionary #2399
- Improved unit tests #2438 #2434
- Enhanced contributing guide #2416
- Adopt all the protocol APIs which contains getter value to use property instead, to make the API easy to use or Swift user #2452
- Remove `sd_setAnimationImagesWithURLs` API, because its cause ambiguity, behave not consistently and have rare use case #2459
- Improved `SDAnimatedImage` protocol with `initWithData:scale:options:` #2453
- Extra args for `SDSetImageBlock` (added `cacheType` and `imageURL`) #2449

#### Fixes
- Fix that using `NS_TYPED_ENUM` on `SDImageFormat` cause the existing Swift API (`sd_UTTypeFromImageFormat`) naming changed #2413
- Fix that downloader options about image decoding is not correctly set #2414
- Make download receive response notification only dispatch to specific observer #2426
- Fix a race condition during progressive animation load in `SDAnimatedImageView` #2435
- Fix the bug that `SDWebImageContextCacheKeyFilter` wrongly be used as cache serializer and cause crash #2451
- Fix resource key invalid when clean cached disk file #2462
- Add no expiration file support of disk cache #2461

## [5.0.0-beta2 - Customizable SDWebImage, on Jul 31st, 2018](https://github.com/rs/SDWebImage/releases/tag/5.0.0-beta2)
See [all tickets marked for the 5.0.0 release](https://github.com/rs/SDWebImage/milestone/15)

#### Features
- Add `SDImageCoderWebImageContext` coder option, which allow custom coder plugin, to receive the context option from top-level API #2405
- Updated all existing diagrams for 5.0 release + added new ones (small detailed diagrams for the most important components) #2407

#### Fixes
- Fix nullable key for `sd_imageLoadOperationForKey` #2389
- Replace `__bridge_transfer` with `__bridge` when convert from `CFStringRef` to `NSString` #2392
- Rename `sd_UTTypeFromSDImageFormat` to `sd_UTTypeFromImageFormat` #2395
- Change `SDImageFormat` to use `NS_TYPED_EXTENSIBLE_ENUM` instead of fixed enum, to allow custom coder plugins to extend it #2400

## [4.4.4 - 4.4 patch, on Jan 26th, 2019](https://github.com/SDWebImage/SDWebImage/releases/tag/4.4.4)
See [all tickets marked for the 4.4.4 release](https://github.com/SDWebImage/SDWebImage/milestone/29)

#### Fixes
- Fix memory cache image cost miscalculation for 4.x #2486
- Fix background download for 4.x #2570
- Fix race condition for creation of download operation when isCancelled is YES but isFinished is NO #2574
- Fix the current image cost (pixels) for FLAnimatedImage #2558
- Fix the FLAnimatedImage compatible code issue by introduce a private API #2588
- Fix that WebP image with ICC Profile does not show color correctly, should use the profile colorspace instead of device colorspace #2585
- Fix potential memory leaks for ICCP && optimize ICCP handler #2596
- Fix that WebP decoder in master branch, does not consider the global `shouldDecompressImages` config and always do pre-draw for static WebP images #2592
- Fix rare crash when NSMapTable empty keys #2556
- Retain operation when post download related notifications (Hopefully fix, but if you face crash, please open a issue) #2576

#### Performances
- Prioritize SDWebImageDownloaderHighPriority if operation already exists #2575

#### Project
- Let SD can be imported using static library by CocoaPods using `DEFINES_MODULE` #2549

## [4.4.3 - 4.4 patch, on Nov 25th, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.4.3)
See [all tickets marked for the 4.4.3 release](https://github.com/SDWebImage/SDWebImage/milestone/28)

#### Fixes
- Revert the hack code for `FLAnimatedImage`, because of the `FLAnimatedImage` initializer method blocks the main queue #2441
- Fix extention long length of file name #2516 6c6d848
- Fix resource key invalid when clean cached disk file #2463
- Fix the test case `testFLAnimatedImageViewSetImageWithURL` because of remote resource is not available #2450
- Add default `HTTP User-Agent` for specific system #2409
- Add `SDImageFormatHEIF` represent `mif1` && `msf1` brands #2423
- remove `addProgressCallback`, add `createDownloaderOperationWithUrl` #2336
- Fix the bug when `FLAnimatedImageView` firstly show one EXIF rotation JPEG `UIImage`, later animated GIF `FLAnimatedImage` will also be rotated #2406
- Replace `SDWebImageDownloaderOperation` with `NSOperation<SDWebImageDownloaderOperationInterface>` to make generic #2397
- Fix wrong image cache type when disk and memory cache missed #2529
- Fix FLAnimatedImage version check issue for custom property `optimalFrameCacheSize` && `predrawingEnabled` #2543

#### Performances
- Add autoreleasepool to release autorelease objects in advance when using GCD for 4.x #2475
- Optimize when scale = 1 #2520

#### Docs
- Updated URLs after project was transfered to [SDWebImage organization](https://github.com/SDWebImage) #2510 f9d05d9
- Tidy up spacing for `README.md` #2511
- Remove versioneye from README #2424

## [4.4.2 - 4.4 patch, on July 18th, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.4.2)
See [all tickets marked for the 4.4.2 release](https://github.com/SDWebImage/SDWebImage/milestone/27)

#### Features
- Ability to change the clear cache option `SDImageCacheConfig.diskCacheExpireType` #2357
- Add option to enable or disable weak memory cache for `SDImageCache` via `SDImageCacheConfig.shouldUseWeakMemoryCache` #2379
- Add cache control for `FLAnimatedImage`, this allow user to disable memory cache for associated `FLAnimatedImage` instance #2378
- Add `diskImageDataForKey:` sync API for `SDImageCache` to directly get the image data from disk #2391

#### Fixes
-  `SDWebImageManager.runningOperations` type changed from `Array` to `Set` #2382
- Keep the information about image's original compressed format #2390
- Fix `FLAnimatedImageView+WebCache` delayed draw due to #2047 which is now reverted #2393
- Check for nullable key when cancel image load operation #2386
- Replace `__bridge_transfer` with `__bridge` when convert from `CFStringRef` to `NSString` #2394

## [5.0.0-beta - Customizable SDWebImage, on Jul 17th, 2018](https://github.com/rs/SDWebImage/releases/tag/5.0.0-beta)
See [all tickets marked for the 5.0.0 release](https://github.com/rs/SDWebImage/milestone/15)

#### Infrastructure
- the new requirements are **iOS 8.0+** and **macOS 10.10+** #2147
- **Xcode 9+**

#### Backwards incompatible changes

See the [5.0 Migration Guide](https://raw.githubusercontent.com/rs/SDWebImage/master/Docs/SDWebImage-5.0-Migration-guide.md) for a list of comprehensive changes and the way to update your code

#### Features
- Introduce `SDAnimatedImageView`, `SDAnimatedImage` and refactor the way we handle animated images #2140
- Added APNG support via dedicated coder `SDImageAPNGCoder` #2149
- Refactored `SDWebImageDownloader` configs, separated them into a dedicated `SDWebImageDownloaderConfig` object #2263
- Refactored the way we work with the scale factor #2266
- Created request and response modifier #2261
- Refactor Cache Path API #2276
- Refactor custom cache serializer & headers filter for request level #2280
- Refactor cache - Support custom memory cache & disk cache #2282
- Refactor cache - Support custom web cache #2278
- Refactor - custom image loader - Supports loader protocol #2256
- Use `SDWebImageAvoidDecodeImage` to allow user to control force decode feature for individual image request #2283

- `SDImageCache` supports disk cache writing options. See `SDImageCacheConfig diskCacheWritingOptions` #2148
- `SDImageCache` now uses `NSData writeToFile:options:error` instead of `NSFileManager createFileAtPath:contents:attributes` #2148
- Moved `SDImageCache maxMemoryCost` and `SDImageCache maxMemoryCountLimit` to `SDImageCacheConfig` #2151
- Added `SDImageCache diskImageDataExistsWithKey:` synchronous method #2151
- Moved `UIImage sd_imageLoopCount` and `UIImage isGIF` (and renamed to `sd_isAnimated`) to `UIImage+Metadata` category, removed the outdated methods #2152
- Move context and other type definitions to a separate header (`SDWebImageDefine`) to allow to be included without dependency #2188
- Pass `context` arg from the top level APIs to the bottom level APIs to allow specify logic in the future #2189 d6a3e2c c24c3d3
- Refactor the image indicator by creating `SDWebImageIndicator` and `SDWebImageProgressIndicator` protocols and two concrete classes that implement activity and progress indicators for both UIKit and AppKit #2185 46b62cf
- Refactor the implementation of `SDWebImagePrefetcher` so it behaves more like a "shared instance" object, similar to other platform classes. Each instance will manage its own list of urls. #2191 1efc247 92f3d2c bc164d6
- Refactored and enhanced the way we allow image transformations. Switched from a single delegate method to composition of `SDImageTransformer` #2219
- API style refactoring - #2250
  - Use property instead of setters and getters to make the property available in Swift
  - Use class property with the correct name instead of `+(instanceType)sharedInstance` in singleton to make it more easy to use in Swift. The generated interface should be simple `open class var shared { get }`
  - Add all nullability annotation to avoid any `AnyObject!` implicitly unwrapped optionals (Except that `null_resettable`)
  - Add all Core Foundation Ownership using `CF_RETURNS_RETAINED` for
    Get Rule and `CF_RETURNS_NOT_RETAINED` for Create Rule to avoid any `Unmanaged` CF value
  - Change all key for Dictionary with `NS_STRING_ENUM` to make it easy to use in Swift with dot syntax
  - Change all global value type which represent enum with `NS_TYPED_ENUM` to make it easy to use in Swift with dot syntax
- Remove the extra calculation of image orientation for ImageIO coder & Fix macOS image orientation #2271
- Added `SDWebImageError` (defined as `NS_ERROR_ENUM`) to group all our errors together #2290
- Added tests for macOS
- Add the `SDWebImageContextStoreCacheType` context option to specify target cache type when the image is downloaded by manager and will store to cache #2360
- Feature watchOS `WKInterfaceImage` with `sd_setImageWithURL` #2331
- Add options to specify query cache sync/async behavior #2312

#### Fixes
- `SDWebImageManager loadImageWithURL:options:progress:completed:` changed the `completed` param requirement from `nullable` to `nonnull` #2164

## [4.4.1 - 4.4 patch, on June 7th, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.4.1)
See [all tickets marked for the 4.4.1 release](https://github.com/SDWebImage/SDWebImage/milestone/26)
	
#### Fixes
- Coder
	- Fix that WebP (including Animated WebP) decoding issue on iOS 12 #2348 #2347
- Downloader
	- Fix that the downloader operation may not call the completion block when requesting the same image url in race condition #2346 #2344

## [4.4.0 - watchOS View Category, on May 31st, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.4.0)
See [all tickets marked for the 4.4.0 release](https://github.com/SDWebImage/SDWebImage/milestone/25)

#### Features
- View Category
	- Add the support for watchOS to use View Category method (`sd_setImageWithURL:`) on WKInterfaceImage #2343
	- Add optimalFrameCacheSize && predrawingEnabled options for FLAnimatedImage #2323
- Cache
	- Add `SDImageCacheScaleDownLargeImages` to allow cache to scale down large images if need #2281 #2273

#### Improvements
- View Category
	- Add `UIViewAnimationOptionAllowUserInteraction` as default options for convenient image transition #2315
- Manager
	- Replace `@synchronized` with dispatch_semaphore_t in SDWebImageManager #2340

#### Performances
- Coder
	- Remove the extra calculation of image orientation for ImageIO coder #2313
	- Remove the duplicated process to force decode (draw on bitmap context) in Image/IO's progressive decoding #2314
- Common
	- Minor optimize for dispatch_queue_async_safe #2329
	
#### Fixes
- Coder
	- Fix that force decode not works for alpha-channel images #2272 #2297
	- Fix WebP Encoding only works for RGBA8888 CGImage but not other color mode #2318
	- Fix the thread-safe issue for coders manager #2274 #2249 #1484
	- Fix the wrong declaration of NSArray generics #2260

#### Docs
- Fix function storeImageDataToDisk description #2301

## [4.3.3 - Cache Serializer, on Mar 12th, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.3.3)
See [all tickets marked for the 4.3.3 release](https://github.com/SDWebImage/SDWebImage/milestone/24)

#### Features
- Manager
	- Add cacheSerializer to allow user provide modified version of data when storing the disk cache in SDWebImageManager #2245
	- Add a delegate method to control the custom logic when blocking the failed url #2246

#### Improvements
- Project
	- Enable CLANG\_WARN\_OBJC\_IMPLICIT\_RETAIN\_SELF and fix warning #2242


## [4.3.2 - 4.3 Patch, on Feb 28th, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.3.2)
See [all tickets marked for the 4.3.2 release](https://github.com/SDWebImage/SDWebImage/milestone/23)

#### Fixes
- Download Operation
	- Fix that iOS 8 NSURLSessionTaskPriorityHigh symbol not defined in Foundation framework and cause crash #2231 #2230

#### Improvements
- Downloader
	- Follow Apple's doc, add NSOperation only after all configuration done #2232

## [4.3.1 - 4.3 Patch, on Feb 25th, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.3.1)
See [all tickets marked for the 4.3.1 release](https://github.com/SDWebImage/SDWebImage/milestone/22)

#### Fixes
- Cache
	- Fix that SDImageCacheQueryDataWhenInMemory should response cacheType to memory cache when the in-memory cache hit #2218
- Project
	- Fix the macOS wrong minimum deployment target version to 10.9 #2206

#### Performances
- Download Operation
	- Decode the image in the operation level's queue instead of URLSession delegate queue #2199

#### Improvements
- Coder
	- Create a subclass of NSBitmapImageRep to fix the GIF frame duration issue on macOS #2223 
- View Category
	- Expose the read write to FLAnimatedImage associate to the UIImage to allow advanced feature like placeholder #2220
- Cache
	- Create a subclass of NSCache using a weak cache #2228
- Download Operation
	- Improvement download operation for priority and some protect #2208
- Project
	- Fix CLANG\_WARN\_OBJC\_IMPLICIT\_RETAIN\_SELF warning #2225 


## [4.3.0 - Image Progress & Transition, on Jan 31th, 2018](https://github.com/SDWebImage/SDWebImage/releases/tag/4.3.0)
See [all tickets marked for the 4.3.0 release](https://github.com/SDWebImage/SDWebImage/milestone/21)

#### Features
- View Category
	- Add NSProgress API in `sd_imageProgress` property represent the image loading progress, this allow user add KVO on it for complicated logic #2172
	- Add Image Transition API in `sd_imageTransition` property support custom image transition after image load finished #2182
	- Add NSButton WebCache category on macOS #2183
- Cache
	- Add query cache options for query method #2162
	- Add sync version API diskImageDataExistsWithKey and diskCacheWritingOptions #2190
- Manager
	- Add a option SDWebImageFromCacheOnly to load the image from cache only and prevent network #2186

#### Fixes
- Coder
	- Fix GIF loopCount when the GIF image has no Netscape 2.0 loop extension #2155
- View Category
	- Fix the issue that `setAnimationImagesWithURLs` weak reference may dealloc before the animated images was set #2178
- Cache
	- Fix the getSize method which use the default file manager instead of current file manager #2180
- Manager
	- Fix the leak of runningOperations on race condition #2177
- Downloader
	- Ensure all the session delegate completionHandler called and fix the leak when response error code below iOS 10 #2197
	- Fix dispatch_sync blocking the main queue on race condition #2184
	- Fix the thread-safe issue for headers mutable dictionary in downlaoder #2204
- Download Operation
	- Fix that 0 pixels error should be used when width OR height is zero but not AND #2160
	- Use the synchronized to access NSURLCache and try fix the potential thread-safe problem #2174
- Prefetcher
	- Fix the issue that prefetcher will cause stack overflow when the input urls list is huge because of recursion function call #2196

#### Performances
- View Category
	- Use the associate object to store the FLAnimatedImage into memory cache, avoid blinking or UIView transition #2181

#### Improvements
- Cache
	- Remove the extra memory warning notification for AutoPurgeCache #2153
- Downloader
	- Avoid user accidentally invalidates the session used in shared downloader #2154
- Project
	- Update the spec file to define the dependency version for libwebp #2169

## [4.2.3 - 4.2 Patch, on Nov 30th, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.2.3)
See [all tickets marked for the 4.2.3 release](https://github.com/SDWebImage/SDWebImage/milestone/20)

#### Features
- Add a public API to allow user to invalidate URLSession used in SDWebImageDownloader to avoid memory leak on non-singleton instance #2116
- Add a SDWebImageExternalCustomManagerKey context arguments to allow user to custom image manager for UIView category #2115
- Allow custom SDWebImageDownloaderOperation to handle HTTP redirect #2123

#### Fixes
- Fix that FLAnimatedImageView blink and flash when collectionView reload #2102 #2106
- Fix that SDWebImagePrefetcher startPrefetchingAtIndex accident crash #2110 #2111
- Fix that Progressive WebP decoding not showing on iOS 11.2 #2130 #2131
- Fix crash in method implementation of sd_cancelImageLoadOperationWithKey, and avoid retain of operation #2113 #2125 #2132
- Fix Clang Static Analyzer warning for number nil check from Xcode 9.2 #2142 #2143

#### Improvements
- Adopt the current requirement, change ImageIO coder's canDecodeFromHEIC to actual implementation #2146 #2138
- When store image with no data for SDImageCache, check whether it contains alpha to use PNG or JPEG format #2136

## [4.2.2 - 4.2 Patch, on Nov 7th, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.2.2)
See [all tickets marked for the 4.2.2 release](https://github.com/SDWebImage/SDWebImage/milestone/19)

#### Features
- Update our iOS demo to modern way, add a `UIProgressView` to show image download progress #2096

#### Fixes
- Fix that completion block and set image block are called asynchronously for `UIView+WebCache` #2093 #2097 #2092
- Fix WebP progressive decoding may do extra calculate #2095

## [4.2.1 - 4.2 Patch, on Oct 31st, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.2.1)
See [all tickets marked for the 4.2.1 release](https://github.com/SDWebImage/SDWebImage/milestone/18)

#### Features
- Feature refactor built-in coders and support animated webp on macOS #2082 (reusable code into `SDWebImageCoderHelper`; `SDWebImageFrame` abstracts animated images frames)

#### Fixes
- Fixed EXIF orientation method will crash on iOS 7 because it’s an iOS 8 above API #2082

## [4.2.0 - Pluginable coders, on Oct 30th, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.2.0)
See [all tickets marked for the 4.2.0 release](https://github.com/SDWebImage/SDWebImage/milestone/16)

#### Features
- Refactor decoding code and provide decoding plugin #1991
- HEIC format support #2080 #1853 #2038
- Welcome back our previous `UIImage+GIF` category for animated GIF! Not enabled by default. #2064
- Add the animated GIF encoding support for `SDWebImageGIFCoder` on `macOS` (use `NSImage` API) #2067
- Implemented `-[NSImage isGIF]` method to return whether current `NSImage` has GIF representation #2071
- Allow user to provide reading options such as mapped file to improve performance in `SDImageCache` disk cache #2057
- Add progressive image load for WebP images #1991 #1987 #1986
- CI builds use Xcode 9
- Fixed our tests and improved the code coverage #2068

#### Fixes
- Fixed lost orientation issues #1991 #2034 #2026 #1014 #1040 #815
- Fixed `UIImage(GIF) sd_animatedGIFWithData` crash #1991 #1837
- Fixed progressive WebP height issue #2066
- Fixed `SDWebImageManager.m __destroy_helper_block_` crash #2048 #1941
- Fixed cached image filename are sometimes generated with invalid path extensions #2061
- Fixed GIF performance problem #1901 by creating `FLAnimatedImage` instance on global queue #2047

#### Docs
- Updated diagrams

## [4.1.2 - 4.1 patch, on Oct 9th, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.1.2)
See [all tickets marked for the 4.1.2 release](https://github.com/SDWebImage/SDWebImage/milestone/17)

#### Fixes

- Fix `SDWebImageDownloaderOperation` not call `done` when use `SDWebImageDownloaderIgnoreCachedResponse` #2049
- Static `WebP` decoding little enhancement. Do not need create `WebP` iterator for static images #2050
- Change `finished` check from `equal` to `equal or greater than` to protect accident condition #2051

## [4.1.1 - 4.1 patch, on Oct 6th, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.1.1)
See [all tickets marked for the 4.1.1 release](https://github.com/SDWebImage/SDWebImage/milestone/14)

#### Fixes

- Fixed crash on `[SDWebImageDownloaderOperation reset]_block_invoke` 2f892f9 fixes #1883
- Fixed `SDWebImageDownloadOperation` `imageData` multi-thread issue #2011 fixes #1998 `[SDWebImageDownloaderOperation URLSession:dataTask:didReceiveData:]` crash
- Fixed `CFRelease` on `NULL` if `CGImageSourceRef` create failed #1978 fixes #1968 #1834 #1947
- Fixed request cache policy #1994 #2032 fixes #1993 #1861 #1623 was introduced by #1737 (unit test #2031)
- Fixed `CGBitmapContextCreate` bitmap memory leak #1976 replaces #1860 fixes #1974
- Fixed issue #2001, add `sd_currentBackgroundImageURL` and `sd_backgroundImageURLForState:` for `UIButton` #2002
- Set `UIButton` placeholer-image even if the url is `nil` #2043 fixes #1721 #1964 replaces #1790
- Use `CGImageSourceCreateIncremental` to perform progressive decoding instead of decode partial data each time from the beginning to improve performance and remove that gray background #2040 fixes #1899
- Fix *SDWebImage v4* can not import *libwebp* framework's header files #1983 fixes #1887
- Fix unreachable code build warning on `macOS` #1984

#### Improvements

- Performance enhancement related to single `WebP` and animated `WebP` decoding #1985 fixes #1999 #1885
- Use `FOUNDATION_EXPORT` over `extern` #1977
- Move common test logic to `SDTestCase` #1980
- Enabled `CLANG_WARN_STRICT_PROTOTYPES` #1995 #2027 fixes #2022
- Update `macOS Demo` deployment target to `10.10` to support build on `Xcode 9` #2035

#### Docs

- Updated *Manual Installation* section #2030 fixes #2012

## [4.1.0 - Swift API cleanup, on Jul 31st, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.1.0)
See [all tickets marked for the 4.1.0 release](https://github.com/SDWebImage/SDWebImage/milestone/13)

#### Features

- add ability to change `NSURLSessionConfiguration` used by `SDWebImageDownloader` #1891 fixes #1870
- support animated GIF on `macOS` #1975
- cleanup the Swift interface by making unavailable all methods with missing params that have alternatives - see #1797 - this may cause require some changes in the Swift code

#### Fixes

- handle `NSURLErrorNetworkConnectionLost` #1767
- fixed `CFBundleVersion` and `CFBundleShortVersionString` not valid for all platforms #1784 + 23a8be8 fixes #1780
- fixed `UIActivityIndicator` not always initialized on main thread #1802 + a6af214 fixes #1801
- `SDImageCacheConfig` forward declaration changed to import #1805
- making image downloading cache policy more clearer #1737
- added `@autoreleasepool` to `SDImageCache.storeImage` #1849
- fixed 32bit machine `long long` type transfer to NSInteger may become negative #1879
- fixed crash on multiple concurrent downloads when accessing `self.URLOperations` dictionary #1911 fixes #1909 #1950 #1835 #1838
- fixed crash due to incorrectly retained pointer to operation `self` which appears to create a dangled pointer #1940 fixes #1807 #1858 #1859 #1821 #1925 #1883 #1816 #1716
- fixed Swift naming collision (due to the Obj-C interface that offers multiple variants of the same method but with mixed and missing params) #1797 fixes #1764
- coding style #1971
- fixed Umbrella header warning for the FLAnimatedImage (while using Carthage) d9f7cf4 (replaces #1781) fixes #1776
- fixed issue where animated image arrays could be populated out of order (order of download) #1452
- fixed animated WebP decoding issue, including canvas size, the support for dispose method and the duration per frame #1952 (replaces #1694) fixes #1951

#### Docs

- #1778 #1779 #1788 #1799 b1c3bb7 (replaces #1806) 0df32ea #1847 5eb83c3 (replaces #1828) #1946 #1966

## [4.0.0 - New platforms (Mac OS X and watchOS) + refactoring, on Jan 28th, 2017](https://github.com/SDWebImage/SDWebImage/releases/tag/4.0.0)

See [all tickets marked for the 4.0.0 release](https://github.com/SDWebImage/SDWebImage/milestone/3)
Versions 4.0.0-beta and 4.0.0-beta 2 list all the changes. 

## [4.0.0 beta 2 - New platforms (Mac OS X and watchOS) + refactoring, on Oct 6th, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/4.0.0-beta2)

See [all tickets marked for the 4.0.0 release](https://github.com/SDWebImage/SDWebImage/milestone/3)

#### Features

- Add an option to scale down large images #787 00bf467 efad1e5 8d1a0ae. Fixed #538, #880 and #586. This one is a more robust solution than #884 or #894. Can be activated via `SDWebImageScaleDownLargeImages` or `SDWebImageDownloaderScaleDownLargeImages`

#### Fixes

- Fixed #1668 CGContextDrawImage: invalid context 0x0 - b366d84

## [4.0.0 beta - New platforms (Mac OS X and watchOS) + refactoring, on Oct 5th, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/4.0.0-beta)

See [all tickets marked for the 4.0.0 release](https://github.com/SDWebImage/SDWebImage/milestone/3)

#### Infrastructure:

- support for **watchOS** and **OS X** platforms #1595
- the `SDWebImage xcodeproj` contains the following targets:
    - `SDWebImage iOS static` (iOS static lib)
    - `SDWebImage watchOS static` (watchOS static lib)
    - `SDWebImage OSX` (OSX dynamic framework)
    - `SDWebImage iOS` (iOS dynamic framework)
    - `SDWebImage tvOS` (tvOS dynamic framework)
    - `SDWebImage watchOS` (watchOS dynamic framework)
  - the `SDWebImage Demo xcodeproj` contains the following targets:
    - `SDWebImage OSX Demo`
    - `SDWebImage iOS Demo`
    - `SDWebImage TV Demo`
    - `SDWebImage Watch Demo`
- bumped `libwep` version to `0.5.1`
- improved unit testing code coverage (*35%* -> **77%**) and integrated [CodeCov](https://codecov.io/gh/SDWebImage/SDWebImage)

#### Backwards incompatible changes

- removed all deprecated methods (that we carried around for backwards compatibility in previous versions) #774
- Renamed `SDWebImageManager` `downloadImageWithURL:options:progress:completed:` to `loadImageWithURL:options:progress:completed:` as it makes more sense, since we check the cache first and download only if needed a32a177
- Deleted targets: `SDWebImage+MKAnnotation`, `SDWebImage+WebP`, `SDWebImageFramework`:  
  - `SDWebImage `target that build as a static library (all subspecs included) -> `libSDWebImage.a`
  - `SDWebImageiOS` and `SDWebImagetvOS` targets that build as dynamic frameworks
- Renamed the dynamic frameworks targets from `WebImage` to `SDWebImage`. Renamed the `WebImage.h` to `SDWebImage.h` to match the framework naming
- Renamed the schemes for consistency. Updated the Tests Podfile + project.
- For #883 Fix multiple requests for same image and then canceling one, several breaking changes were needed:
  - `SDWebImageDownloader` method `- downloadImageWithURL:options:progress:completed:` now returns a `SDWebImageDownloadToken *` instead of `id <SDWebImageOperation>` (give the ability to cancel downloads using the returned token)
  - `SDWebImageDownloaderOperation` initializer `- initWithRequest:options:progress:completed:cancelled` split into `- initWithRequest:options` and `addHandlersForProgress:completed:`. Note: there is no more cancel block
- Modern Objective-C syntax done in 64382b9 includes:
  - initializers now return `instancetype` instead of `id`
  - explicit designated initializers (i.e. for `SDImageCache`)
- For #1575 GIF support using FLAnimatedImage, several changes were needed:
  - replaced type `SDWebImageQueryCompletedBlock` with `SDCacheQueryCompletedBlock` and added an `NSData *` param
  - because of the change above, the `done` param of `SDImageCache` `queryDiskCacheForKey:done:` is now a `SDCacheQueryCompletedBlock` and those blocks must now include an `NSData *` param
  - replaced type `SDWebImageCompletionWithFinishedBlock` with `SDInternalCompletionBlock` and added an `NSData *` param
  - because of the change above, the `completed` param of `SDWebImageManager` `loadImageWithURL:options:progress:completed:` is now `SDInternalCompletionBlock` and those blocks must now include an `NSData *` param
  - for consistency with the previous change, also renamed `SDWebImageCompletionBlock` to `SDExternalCompletionBlock`
  - `UIImage` will no longer respond to `sd_animatedGIFNamed:` or `sd_animatedImageByScalingAndCroppingToSize:`
- Xcode 7 Objective-C updates (Lightweight Generics and Nullability) #1581
  - breaks compatibility at least for Swift users of the framework
- **watchOS** and **OS X** support #1595 required
  - renamed `SDWebImage` iOS static lib target to `SDWebImage iOS static` for clarity
- improving the unit tests code coverage #1681 required
  - Refactored `NSData` `ImageContentType` category, instead of returning the contentType as a string, the new added method `sd_imageFormatForImageData` will return a `SDImageFormat` enum value
  - `SDImageCache` configuration properties moved into `SDImageCacheConfig` (which is now available via `config` property):
    - `shouldDecompressImages`
    - `shouldDisableiCloud`
    - `shouldCacheImagesInMemory`
    - `maxCacheAge`
    - `maxCacheSize`
  - The `storeImage:` methods from `SDImageCache` were async already, but declared as sync. Properly marked them as async + added completion. Got rid of the recalculate param. If the `NSData` is provided, use it. Otherwise, recalculate from the `UIImage`
  - Removed the synchronous methods `diskImageExistsForURL:` and `cachedImageExistsForURL:` from `SDWebImageManager`
  - Removed the synchronous method `diskImageExistsWithKey:` from `SDImageCache`
  - Get rid of the confusion caused by `cleanDisk` and `clearDisk` on `SDImageCache`. Renamed `cleanDisk` to `deleteOldFiles`. No longer expose the sync `clearDisk` and `deleteOldFiles`, just the async ones.
  - Renamed `SDImageCache` `queryDiskCacheForKey:done:` to `queryCacheOperationForKey:done:`
  - Another `SDImageCache` clarification: `imageFromDiskCacheForKey:` used to also check the memory cache which I think is misleading. Now `imageFromDiskCacheForKey` only checks the disk cache and the new method `imageFromCacheForKey` checks both caches
  - Got rid of `removeImageForKey:` and `removeImageForKey:fromDisk:` from `SDImageCache` that looked sync but were async. Left only the 2 async ones
  - Removed `UIImageView` `sd_cancelCurrentHighlightedImageLoad`
- Added `sd_` prefix to the activity indicator related methods (`setShowActivityIndicatorView:`, `setIndicatorStyle:`, `showActivityIndicatorView`, `addActivityIndicator`, `removeActivityIndicator`) #1640
- Use `dispatch_main_async_safe` for all the completion blocks on the main queue (used to be `dispatch_sync`) - avoiding locks.
- Removed `dispatch_main_sync_safe` as it can be mistakenly used
- Add `url` as param to progress block `SDWebImageDownloaderProgressBlock` - #984

#### Features:

- Switched our GIF support to a better implementation: [FLAnimatedImage by Flipboard](https://github.com/Flipboard/FLAnimatedImage) #1575
  - requires iOS 8+ (it's the only way due to FLAnimatedImage requirements)
  - the implementation relies on a `WebCache` category on top of `FLAnimatedImageView`
  - details in the [README](README.md#animated-images-gif-support)
- Converted any remaining code to Modern Objective-C syntax - 64382b9
- Xcode 7 Objective-C updates (Lightweight Generics and Nullability) #1581
- via #1595 Clarified and simplified the usage of `TARGET_OS_*` macros. Added `SD_MAC`, `SD_UIKIT`, `SD_IOS`, `SD_TV`, `SD_WATCH`. The biggest issue here was `TARGET_OS_MAC` was 1 for all platforms and we couldn't rely on it.
- Replaces #1398 Allow to customise cache and image downloader instances used with `SDWebImageManager` - added a new initializer (`initWithCache:downloader:`) 9112170
- `UIImage` responds to `sd_imageData` and `sd_imageDataAsFormat:` via the `MultiFormat` category. Those methods transform a `UIImage` to the `NSData` representation 82d1f2e
- Created `SDWebImageDownloaderOperationInterface` to describe the behavior of a downloader operation. Any custom operation must conform to this protocol df3b6a5
- Refactored all the duplicate code from our `WebCache` categories into a `UIView` `WebCache` category. All the other categories will make calls to this one. Customization of setting the image is done via the `setImageBlock` and the `operationKey` e1840c3
- Due to the change above, the activity indicator can now be added to `UIButton`, `MKAnnotationView`, `UIImageView`
- Animated WebP support #1438
- The shared objects (not really singletons) should allow subclassing, therefore the return type of the shared resource method should be `instancetype` and not a fixed type - c57cf7e
- Allow to specify `NSURLSessionConfiguration` for `SDWebImageDownloader` #1654
- Add `url` as param to progress block `SDWebImageDownloaderProgressBlock` - #984

#### Fixes:

- Fix multiple requests for same image and then canceling one #883 + 8a78586
- Fixed #1444 and the master build thanks to [@kenmaz](https://github.com/kenmaz/SDWebImage/commit/5034c334be50765dfe4e97c48bcb74ef64175188)
- Fixed an issue with the `SDWebImageDownloaderOperation` : `cancelInternal` was not called because of the old mechanism rellying on the `thread` property - probably because that thread did not have a runloop. Removed that and now cancelInternal is called as expected f4bdae6
- Replaced #781 on replacing dispatch_sync with dispatch_async for the main queue 062e50a f7e8246 c77adf4 fdb8b2c 265ace4 0c47bc3. Check for main queue instead of main thread.
- Fixed #1619 iOS 10 crash (`setObjectForKey: object cannot be nil`) - #1676 7940577
- Fixed #1326 #1424 (`Carthage bitcode issue`) - #1593
- Fixed #1639 via #1657 (`Add support for downloading images behind redirect`)
- Replaced #1537 via 9cd6779 - fixed a potential retain cycle
- Updated `dispatch_main_async_safe` macro in order to avoid redefinition when included as Pod
- Fixed #1089 by updating the docs on the calling queue for the `progressBlock` (background queue)
- Fixed a compilation issue on `FLAnimatedImageView+WebCache` - #1687

## [3.8.2 Patch release for 3.8.0 on Sep 5th, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/3.8.2)

#### Fixes:

- Fixed #1608 #1623 #1644 Crash in `[NSURLCache cachedResponseForRequest:]` -  the fix is actually avoiding to access `NSURLCache` which appears to generate a race condition. We only call it if necesarry (`SDWebImageRefreshCached` is used and the image cannot be cached by the system when it's too big or behind authentication)

## [3.8.1 Patch release for 3.8.0 on Jun 7th, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/3.8.1)

#### Fixes:

- SDWebImage 3.8.0 get wrong image #1589 - the issue was caused by the changes in 3.8.0 (Removed the URL query params from the filename (key) fb0cdb6d 1bf62d4 #1584 - fixes #1433 #1553 #1583 #1585) - Reverted. 
- Note: The solution for those issues (i.e. #1433 #1553) is to set the `SDWebImageManager` `cacheKeyFilter` block and do their own calculations there.

## [3.8.0 Minor release - Replaces NSURLConnection (deprecated) with NSURLSession - on Jun 6th, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/3.8.0)

#### Infrastructure:

- Had to update the iOS deployment target to 7.0 from 5 - 6545a3a

#### Features:

- Replace deprecated `NSURLConnection` with `NSURLSession` #1578 #1586 - fixes #1291 #1318 #823 #1566 #1515
- Allow to customise cache and image downloader instances used with `SDWebImageManager` 86fc47bf7b - fixes #1398 #870

#### Fixes:

- Removed the URL query params from the filename (key) fb0cdb6d 1bf62d4 #1584 - fixes #1433 #1553 #1583 #1585
- Fixed the WebP build with the official 1.0.0 CocoaPods release f1a471e - fixes #1444
- Updated doc: `removeImageForKey:` not synchronous e6e5c51 - fixes #1379 #1415

## [3.7.6 Patch release for 3.7.0 on May 8th, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/3.7.6)

#### Infrastructure:
- Changed the **libwebp git url** so that people from China can access it - #1390 (from `https://chromium.googlesource.com/webm/libwebp` to `https://github.com/webmproject/libwebp`)

#### Features:
- Added `cancelAllDownloads` method to `SDWebImageDownloader` #1504 
- Added API to save image `NSData` to disk cache: `[SDImageCache storeImageDataToDisk:forKey:]` #1453 

#### Fixes:
- Fix #1449: Version 3.7.5 breaks semantic versioning (removes public API). Re-added `sd_setImageWithPreviousCachedImageWithURL:andPlaceholderImage:options:progress:completed:` and deprecated it. Will remove it in 4.0.0 b40124c
- Fix `CGContextDrawImage: invalid context 0x0` - #1496 (fixes #1401 #1454 #1457)
- Fix `CGBitmapContextCreateImage: invalid context 0x0` - #1464 (fixes #1423)
- Fix changed image size when loading from disk #1540 (fixes #1437)
- Repair memory release in the iPad environment #1549 (had to switch `#if TARGET_OS_IPHONE` to `#if TARGET_OS_IOS`)
- Fixed completion logic in `MKAnnotationView+WebCache` #1547 
- Optimize the decoder to avoid unwanted blended layer - #1527 (fixes #1524)
- Protect against malformed frame for GIFs - #1447
- updated doc: #1462 #1466 #1486 #1532 #1461 

## [3.7.5 Patch release for 3.7.0 on Jan 21st, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/3.7.5)
- fixed #1425 and #1426 - Continuation of Fix #1366, addresses #1350 and reverts a part of #1221 - from commit 6406d8e, the wrong usage of `dispatch_apply`
- fixed #1422 - Added a fallback for #976 so that if there are images saved with the old format (no extension), they can still be loaded

## [3.7.4 Patch release for 3.7.0 with tvOS support on Jan 8th, 2016](https://github.com/SDWebImage/SDWebImage/releases/tag/3.7.4)

#### Updates
- bumped `libwep` version to `0.4.4`

#### Features:
- added tvOS support #1327 and #1358 - fix #1368 and #1302

#### Fixes:
- #1217 contains several of the above fixes
- fix #391 -> option to cache only on Disk. will replace #1130
- fix #343 -> iCloud backup Option
- fix #371 -> CGBitmapContextCreate: unsupported parameter combination + #1268 #1412 #1340
- fix #576 -> scale set to screen scale
- fix #1035 -> progress queue with dispatch_async
- new feature -> activity indicator using auto layout. The activity indicator feature will replace #131
- #1218 progress callbacks now report on main thread - fixes #1035
- #1321 Added a new constructor to SDWebImagePrefetcher - replaces #956
- #976 append the original path extension to the hash filename - fixes #967
- replaced #999 with #1221
- added cache tests #1125
- #1236 fixes #1203
- bf899e2 fixes #1261 #1263 compilation issue CocoaPods vs non-CocoaPods
- #1367 fixes a bug where image scale & orientation are ignored when decoding / decompressing an image
- cac21e1 fixes #1366, addresses #1350 and reverts a part of #1221 - from commit 6406d8e, the wrong usage of dispatch_apply
- #1363 fixes #1361 sd_cancelBackgroundImageLoadForState
- #1348 Create a strong ref of weakOperation in the entry of The image download subOperation, use the strong ref instead weakOperation. At the same time, repair some logic of the 'If cancelled'
- dcb7985 replaces #1345 - Load local credential file
- #1323 don't to perform download if url is "" but not nil
- #1310 Added support for SDWebImageAvoidAutoSetImage option to UIButton and highlighted UIImageView categories
- #1308 Added Swift installation tips
- 32923fa Xcode 7.1 updates
- #1297 cleaner implementation of failedUrl error handling - fixes #1275
- #1280 Fix sd_animatedImageByScalingAndCroppingToSize
- Remove logging from the image prefetcher - #1276
- Fix typos #1256 #1257 #1258 #1331 #1290

## [3.7.3 Patch release for 3.7.0 with iOS8+ framework and Carthage on Jun 13th, 2015](https://github.com/SDWebImage/SDWebImage/releases/tag/3.7.3)

- Adds support for **iOS 8+ Framework and Carthage** [#1071](https://github.com/SDWebImage/SDWebImage/pull/1071) [#1081](https://github.com/SDWebImage/SDWebImage/pull/1081) [#1101](https://github.com/SDWebImage/SDWebImage/pull/1101) 

- [Refactor] Use `NSMutableSet` for failed URLs' storage instead of array [#1076](https://github.com/SDWebImage/SDWebImage/pull/1076) 
- Make a constant for the error domain [#1011](https://github.com/SDWebImage/SDWebImage/pull/1011) 
- Improve operation behavior [#988](https://github.com/SDWebImage/SDWebImage/pull/988) 
- Bug fix: `Collection <__NSArrayM: > was mutated while being enumerated` [#985](https://github.com/SDWebImage/SDWebImage/pull/985) 
- added `SDWebImageAvoidAutoSetImage` option to avoid automatic image addition in `UIImageView` and let developer to do it himself [#1188](https://github.com/SDWebImage/SDWebImage/pull/1188) 
- Added support for custom disk cache folder with fall back for caches directory [#1153](https://github.com/SDWebImage/SDWebImage/pull/1153) 
- Added some files to the workspace so they are easier to edit [8431481](https://github.com/SDWebImage/SDWebImage/commit/8431481)
- Doc update [72ed897](https://github.com/SDWebImage/SDWebImage/commit/72ed897) [7f99c01](https://github.com/SDWebImage/SDWebImage/commit/7f99c01) [#1016](https://github.com/SDWebImage/SDWebImage/pull/1016) [#1038](https://github.com/SDWebImage/SDWebImage/pull/1038) [#1045](https://github.com/SDWebImage/SDWebImage/pull/1045)
- [Memory Issue] Clear `SDWebImagePrefetcher` `progressBlock` when it has completed [#1017](https://github.com/SDWebImage/SDWebImage/pull/1017) 
- avoid warning `<Error>: ImageIO: CGImageSourceCreateWithData data parameter is nil` if `imageData` is nil [88ee3c6](https://github.com/SDWebImage/SDWebImage/commit/88ee3c6) [#1018](https://github.com/SDWebImage/SDWebImage/pull/1018) 
- allow override `diskCachePath` [#1041](https://github.com/SDWebImage/SDWebImage/pull/1041) 
- Use `__typeof(self)` when assigning `weak` reference for block [#1054](https://github.com/SDWebImage/SDWebImage/pull/1054) 
- [Refactor] Implement cache cost calculation as a inline function [#1075](https://github.com/SDWebImage/SDWebImage/pull/1075) 
- @3x support [9620fff](https://github.com/SDWebImage/SDWebImage/commit/9620fff) [#1005](https://github.com/SDWebImage/SDWebImage/pull/1005) 
- Fix parenthesis to avoid crashes [#1104](https://github.com/SDWebImage/SDWebImage/pull/1104) 
- Add `NSCache` countLimit property [#1140](https://github.com/SDWebImage/SDWebImage/pull/1140) 
- `failedURLs` can be removed at the appropriate time [#1111](https://github.com/SDWebImage/SDWebImage/pull/1111) 
- Purge `NSCache` on system memory notifications [#1143](https://github.com/SDWebImage/SDWebImage/pull/1143) 
- Determines at runtime is `UIApplication` is available as per [#1082](https://github.com/SDWebImage/SDWebImage/issues/1082) [#1085](https://github.com/SDWebImage/SDWebImage/pull/1085) 
- Fixes http://git.chromium.org/webm/libwebp.git/info/refs not valid [#1175](https://github.com/SDWebImage/SDWebImage/pull/1175) + Reverted [#1193](https://github.com/SDWebImage/SDWebImage/pull/1193) + [#1177](https://github.com/SDWebImage/SDWebImage/pull/1177) 
- 404 image url was causing the test to fail [0e761f4](https://github.com/SDWebImage/SDWebImage/commit/0e761f4)
- Fix for transparency being lost in transformed images. [#1121](https://github.com/SDWebImage/SDWebImage/pull/1121) 
- Add handling for additional error codes that shouldn't be considered a permanent failure [#1159](https://github.com/SDWebImage/SDWebImage/pull/1159) 
- add webp accepted content type only if `WebP` enabled [#1178](https://github.com/SDWebImage/SDWebImage/pull/1178) 
- fix `ImageIO: CGImageSourceCreateWithData` data parameter is nil [#1167](https://github.com/SDWebImage/SDWebImage/pull/1167) 
- Applied patch for issue [#1074](https://github.com/SDWebImage/SDWebImage/issues/1074) SDWebImage residing in swift module breaks the debugger [#1138](https://github.com/SDWebImage/SDWebImage/pull/1138)
- Fixed URLs with trailing parameters get assigned an incorrect image scale value [#1157](https://github.com/SDWebImage/SDWebImage/issues/1157) [#1158](https://github.com/SDWebImage/SDWebImage/pull/1158) 
- Add newline to avoid compiler warning in `WebImage.h` [#1199](https://github.com/SDWebImage/SDWebImage/pull/1199) 

## [3.7.2 Updated patch release for 3.7.0 on Mar 17th, 2015](https://github.com/SDWebImage/SDWebImage/releases/tag/3.7.2)

#### Updates
- bumped `libwep` version to `0.4.3`

#### Features:
- implement `SDWebImageDownloaderAllowInvalidSSLCertificates` option - [#937](https://github.com/SDWebImage/SDWebImage/pull/937) 
- flag to transform animated images (`SDWebImageTransformAnimatedImage`) - [#703](https://github.com/SDWebImage/SDWebImage/pull/703) 
- allows user to override default `SDWebImageDownloaderOperation` - [#876](https://github.com/SDWebImage/SDWebImage/pull/876) 
- adds option to decompress images and select prefetcher queue - [#996](https://github.com/SDWebImage/SDWebImage/pull/996)  

#### Fixes:
- fixed [#809](https://github.com/SDWebImage/SDWebImage/issues/809) `cancelAll` crash - [#838](https://github.com/SDWebImage/SDWebImage/pull/838) 
- fixed [#900](https://github.com/SDWebImage/SDWebImage/issues/900) by adding a new flag `SD_LOG_NONE` that allows silencing the SD logs from the Prefetcher
- fixed [#895](https://github.com/SDWebImage/SDWebImage/issues/895) unsafe setImage in `setImageWithURL:` - [#896](https://github.com/SDWebImage/SDWebImage/pull/896) 
- fix `NSNotificationCenter` dispatch on subthreads - [#987](https://github.com/SDWebImage/SDWebImage/pull/987) 
- fix `SDWebImageDownloader` threading issue - [#104](https://github.com/SDWebImage/SDWebImage/pull/104)6 
- fixed duplicate failed urls are added into `failedURLs` - [#994](https://github.com/SDWebImage/SDWebImage/pull/994) 
- increased default `maxConcurrentOperationCount`, fixes [#527](https://github.com/SDWebImage/SDWebImage/issues/527) - [#897](https://github.com/SDWebImage/SDWebImage/pull/897) 
- handle empty urls `NSArray` - [#929](https://github.com/SDWebImage/SDWebImage/pull/929) 
- decoding webp, depends on source image data alpha status - [#936](https://github.com/SDWebImage/SDWebImage/pull/936) 
- fix [#610](https://github.com/SDWebImage/SDWebImage/issues/610) display progressive jpeg issue - [#840](https://github.com/SDWebImage/SDWebImage/pull/840) 
- the code from `SDWebImageDownloaderOperation connection:didFailWithError:` should match the code from `connectionDidFinishLoading:`. This fixes [#872](https://github.com/SDWebImage/SDWebImage/issues/872) - [7f39e5e](https://github.com/SDWebImage/SDWebImage/commit/7f39e5e)
- `304 - Not Modified` HTTP status code handling - [#942](https://github.com/SDWebImage/SDWebImage/pull/942) 
- cost compute fix - [#941](https://github.com/SDWebImage/SDWebImage/pull/941) 
- initialise `kPNGSignatureData` data - [#981](https://github.com/SDWebImage/SDWebImage/pull/981) 

#### Documentation
- documentation updated

## [3.7.1 Patch release for 3.7.0 on Jul 23rd, 2014](https://github.com/SDWebImage/SDWebImage/releases/tag/3.7.1)

- fixed `sd_imageOrientationFromImageData:` crash if imageSource is nil - [#819](https://github.com/SDWebImage/SDWebImage/pull/819) [#813](https://github.com/SDWebImage/SDWebImage/pull/813) [#808](https://github.com/SDWebImage/SDWebImage/issues/808) [#828](https://github.com/SDWebImage/SDWebImage/issues/828) - temporary fix
- fixed `SDWebImageCombinedOperation cancel` crash (also visible as `SDWebImageManager cancelAll`) - [28109c4](https://github.com/SDWebImage/SDWebImage/commit/28109c4) [#798](https://github.com/SDWebImage/SDWebImage/issues/798) [#809](https://github.com/SDWebImage/SDWebImage/issues/809) 
- fixed duplicate symbols when using with webp via pods - [#795](https://github.com/SDWebImage/SDWebImage/pull/795) 
- fixed missing `mark` from `pragma mark` - [#827](https://github.com/SDWebImage/SDWebImage/pull/827) 

## [3.7.0 Xcode6, arm64, highlight UIImageView, imageURL ref, NTLM, ... on Jul 14th, 2014](https://github.com/SDWebImage/SDWebImage/releases/tag/3.7.0)

## Features
- Add category for imageView's highlighted state `UIImageView+HighlightedWebCache` - [#646](https://github.com/SDWebImage/SDWebImage/pull/646) [#765](https://github.com/SDWebImage/SDWebImage/pull/765)
- Keep a reference to the image URL - [#560](https://github.com/SDWebImage/SDWebImage/pull/560)
- Pass imageURL in completedBlock - [#770](https://github.com/SDWebImage/SDWebImage/pull/770)
- Implemented NTLM auth support. Replaced deprecated auth challenge methods from `NSURLConnectionDelegate` - [#711](https://github.com/SDWebImage/SDWebImage/pull/711) [50c4d1d](https://github.com/SDWebImage/SDWebImage/commit/50c4d1d)
- Ability to suspend image downloaders `SDWebImageDownloader setSuspended:` - [#734](https://github.com/SDWebImage/SDWebImage/pull/734)
- Delay the loading of the placeholder image until after load - [#701](https://github.com/SDWebImage/SDWebImage/pull/701)
- Ability to save images to cache directly - [#714](https://github.com/SDWebImage/SDWebImage/pull/714)
- Support for image orientation - [#764](https://github.com/SDWebImage/SDWebImage/pull/764)
- Added async `SDImageCache removeImageForKey:withCompletion:` - [#732](https://github.com/SDWebImage/SDWebImage/pull/732) [cd4b925](https://github.com/SDWebImage/SDWebImage/commit/cd4b925)
- Exposed cache paths - [#339](https://github.com/SDWebImage/SDWebImage/issues/339)
- Exposed `SDWebImageManager cacheKeyForURL:` - [5fd21e5](https://github.com/SDWebImage/SDWebImage/commit/5fd21e5)
- Exposing `SDWebImageManager` instance from the `SDWebImagePrefetcher` class - [6c409cd](https://github.com/SDWebImage/SDWebImage/commit/6c409cd)
- `SDWebImageManager` uses the shared instance of `SDWebImageDownloader` - [0772019](https://github.com/SDWebImage/SDWebImage/commit/0772019)
- Refactor the cancel logic - [#771](https://github.com/SDWebImage/SDWebImage/pull/771) [6d01e80](https://github.com/SDWebImage/SDWebImage/commit/6d01e80) [23874cd](https://github.com/SDWebImage/SDWebImage/commit/23874cd) [a6f11b3](https://github.com/SDWebImage/SDWebImage/commit/a6f11b3)
- Added method `SDWebImageManager cachedImageExistsForURL:` to check if an image exists in either the disk OR the memory cache - [#644](https://github.com/SDWebImage/SDWebImage/pull/644)
- Added option to use the cached image instead of the placeholder for `UIImageView`. Replaces [#541](https://github.com/SDWebImage/SDWebImage/pull/541) - [#599](https://github.com/SDWebImage/SDWebImage/issues/599) [30f6726](https://github.com/SDWebImage/SDWebImage/commit/30f6726)
- Created workspace + added unit tests target
- Updated documentation - [#476](https://github.com/SDWebImage/SDWebImage/issues/476) [#384](https://github.com/SDWebImage/SDWebImage/issues/384) [#526](https://github.com/SDWebImage/SDWebImage/issues/526) [#376](https://github.com/SDWebImage/SDWebImage/pull/376) [a8f5627](https://github.com/SDWebImage/SDWebImage/commit/a8f5627)

## Bugfixes
- Fixed Xcode 6 builds - [#741](https://github.com/SDWebImage/SDWebImage/pull/741) [0b47342](https://github.com/SDWebImage/SDWebImage/commit/0b47342)
- Fixed `diskImageExistsWithKey:` deadlock - [#625](https://github.com/SDWebImage/SDWebImage/issues/625) [6e4fbaf](https://github.com/SDWebImage/SDWebImage/commit/6e4fbaf)
For consistency, added async methods in `SDWebImageManager` `cachedImageExistsForURL:completion:` and `diskImageExistsForURL:completion:`
- Fixed race condition that causes cancellation of one download operation to stop a run loop that is now used for another download operation. Race is introduced through `performSelector:onThread:withObject:waitUntilDone:` - [#698](https://github.com/SDWebImage/SDWebImage/pull/698)
- Fixed race condition between operation cancelation and loading finish - [39db378](https://github.com/SDWebImage/SDWebImage/commit/39db378) [#621](https://github.com/SDWebImage/SDWebImage/pull/621) [#783](https://github.com/SDWebImage/SDWebImage/pull/783)
- Fixed race condition in SDWebImageManager if one operation is cancelled - [f080e38](https://github.com/SDWebImage/SDWebImage/commit/f080e38) [#699](https://github.com/SDWebImage/SDWebImage/pull/699)
- Fixed issue where cancelled operations aren't removed from `runningOperations` - [#68](https://github.com/SDWebImage/SDWebImage/issues/68)
- Should not add url to failedURLs when timeout, cancel and so on - [#766](https://github.com/SDWebImage/SDWebImage/pull/766) [#707](https://github.com/SDWebImage/SDWebImage/issues/707)
- Fixed potential *object mutated while being enumerated* crash - [#727](https://github.com/SDWebImage/SDWebImage/pull/727) [#728](https://github.com/SDWebImage/SDWebImage/pull/728) (revert a threading fix from [#727](https://github.com/SDWebImage/SDWebImage/pull/727))
- Fixed `NSURLConnection` response statusCode not valid (e.g. 404), downloader never stops its runloop and hangs the operation queue - [#735](https://github.com/SDWebImage/SDWebImage/pull/735)
- Fixed `SDWebImageRefreshCached` bug for large images - [#744](https://github.com/SDWebImage/SDWebImage/pull/744)
- Added proper handling for `SDWebImageDownloaderLowPriority` - [#713](https://github.com/SDWebImage/SDWebImage/issues/713) [#745](https://github.com/SDWebImage/SDWebImage/issues/745)
- Fixed fixing potential bug when sending a nil url for UIButton+WebCache - [#761](https://github.com/SDWebImage/SDWebImage/issues/761) [#763](https://github.com/SDWebImage/SDWebImage/pull/763)
- Fixed issue [#529](https://github.com/SDWebImage/SDWebImage/pull/529) - if the `cacheKeyFilter` was set, this was ignored when computing the `scaledImageForKey`. For most of the developers that did not set `cacheKeyFilter`, the code will work exactly the same - [eb91fdd](https://github.com/SDWebImage/SDWebImage/commit/eb91fdd)
- Returning error in setImage completedBlock if the url was nil. Added `dispatch_main_async_safe` macro - [#505](https://github.com/SDWebImage/SDWebImage/issues/505) [af3e4f8](https://github.com/SDWebImage/SDWebImage/commit/af3e4f8)
- Avoid premature completion of prefetcher if request fails - [#751](https://github.com/SDWebImage/SDWebImage/pull/751)
- Return nil from `SDScaledImageForKey` if the input image is nil - [#365](https://github.com/SDWebImage/SDWebImage/issues/365) [#750](https://github.com/SDWebImage/SDWebImage/pull/750)
- Do not load placeholder image if `SDWebImageDelayPlaceholder` option specified - [#780](https://github.com/SDWebImage/SDWebImage/pull/780)
- Make sure we call the `startPrefetchingAtIndex:` method from main queue - [#694](https://github.com/SDWebImage/SDWebImage/pull/694)
- Save image in cache before calling completion block - [#700](https://github.com/SDWebImage/SDWebImage/pull/700)
- Fixed arm64 warnings - [#685](https://github.com/SDWebImage/SDWebImage/pull/685) [#720](https://github.com/SDWebImage/SDWebImage/pull/720) [#721](https://github.com/SDWebImage/SDWebImage/pull/721) [#687](https://github.com/SDWebImage/SDWebImage/pull/687)
- Improved logging - [#721](https://github.com/SDWebImage/SDWebImage/pull/721)
- Added `SDWebImageCompat.m` to `SDWebImage+MKAnnotation` target

## [3.6 Fix and cleanup on Mar 24th, 2014](https://github.com/SDWebImage/SDWebImage/releases/tag/3.6)

## [3.5.4 ARM64 Support on Feb 24th, 2014](https://github.com/SDWebImage/SDWebImage/releases/tag/3.5.4)

## [3.5.3 on Jan 7th, 2014](https://github.com/SDWebImage/SDWebImage/releases/tag/3.5.3)

## [3.5.2 on Jan 2nd, 2014](https://github.com/SDWebImage/SDWebImage/releases/tag/3.5.2)

## [3.5.1 on Dec 3rd, 2013](https://github.com/SDWebImage/SDWebImage/releases/tag/3.5.1)

## [3.5 WebP Target, iOS 7, Fixes on Oct 4th, 2013](https://github.com/SDWebImage/SDWebImage/releases/tag/3.5)

- Fix iOS 7 related issues
- Move `WebP` support to a dedicated target
- Removed strong reference to `UIImageView` which was causing a crash in the nested block
- Fix timeout issue
- Add some methods that allow to check if an image exists on disk without taking it off disk and decompressing it first

## [3.4 Animated image category, bug fixes on Aug 13th, 2013](https://github.com/SDWebImage/SDWebImage/releases/tag/3.4)

- Add `calculateSizeWithCompletionBlock`
- Add multiple download of images for animationImages property of `UIImageView`
- Add background task for disk cleanup [#306](https://github.com/SDWebImage/SDWebImage/issues/306) 
- Fix dead thread issue on iOS 5 [#444](https://github.com/SDWebImage/SDWebImage/pull/444), [#399](https://github.com/SDWebImage/SDWebImage/issues/399), [#466](https://github.com/SDWebImage/SDWebImage/issues/466)
- Make IO operations cancelable to fix perf issue with heavy images [#462](https://github.com/SDWebImage/SDWebImage/issues/462) 
- Fix crash `Collection <__NSArrayM: ...> was mutated while being enumerated.` [#471](https://github.com/SDWebImage/SDWebImage/pull/471) 

## [3.3 WebP, Animated GIF and more on Jun 14th, 2013](https://github.com/SDWebImage/SDWebImage/releases/tag/3.3)

- WebP image format support [#410](https://github.com/SDWebImage/SDWebImage/issues/410)
- Animated GIF support [#375](https://github.com/SDWebImage/SDWebImage/pull/375)
- Custom image cache search paths [#156](https://github.com/SDWebImage/SDWebImage/pull/156)
- Bug fixes

## [3.2 Bug fixes on Mar 13th, 2013](https://github.com/SDWebImage/SDWebImage/releases/tag/3.2)

- `SDWebImageRefreshCached` download option [#326](https://github.com/SDWebImage/SDWebImage/pull/326)
- New `SDWebImageManager` delegate methods [ebd63a88c1](https://github.com/SDWebImage/SDWebImage/commit/ebd63a88c116ac7acfbeded5c84d0fffa2443438)
- Fix long standing issue with alpha en JPEGs [#299](https://github.com/SDWebImage/SDWebImage/pull/299)
- Add synchronous disk-cache loading method [#297](https://github.com/SDWebImage/SDWebImage/pull/297)
- Fix `SDWebImageCacheMemoryOnly` flag
- Bug fixes

## [3.1 Bug fixes on Jan 21st, 2013](https://github.com/SDWebImage/SDWebImage/releases/tag/3.1)

## [3.0 Complete rewrite on Nov 29th, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/3.0)

- Complete rewrite of the library using `GCD`, `ARC`, `NSCache` and blocks
- Drop compatibility with iOS 3 and 4

## [2.7.4 Bug fixes on Nov 14th, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/2.7.4)

## [2.7.3 on Nov 3rd, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/2.7.3)

## [2.7.2 on Oct 23rd, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/2.7.2)

## [2.7.1 on Oct 19th, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/2.7.1)

## [2.7 on Sep 8th, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/2.7)

## [2.6 on May 4th, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/2.6)

## [2.5 on Mar 22nd, 2012](https://github.com/SDWebImage/SDWebImage/releases/tag/2.5)

## [2.4 on Oct 1st, 2011](https://github.com/SDWebImage/SDWebImage/releases/tag/2.4)

## [2.3 on Sep 16th, 2010](https://github.com/SDWebImage/SDWebImage/releases/tag/2.3)

## [2.2 on Aug 29th, 2010](https://github.com/SDWebImage/SDWebImage/releases/tag/2.2)

## [2.1.0 on Jun 12th, 2010](https://github.com/SDWebImage/SDWebImage/releases/tag/2.1.0)

## [2.1 on Jun 12th, 2010](https://github.com/SDWebImage/SDWebImage/releases/tag/2.1)

## [2.0.0 on Jun 9th, 2010](https://github.com/SDWebImage/SDWebImage/releases/tag/2.0.0)

## [2.0 on Jun 9th, 2010](https://github.com/SDWebImage/SDWebImage/releases/tag/2.0)

## [1.0.0 on Dec 31st, 2009](https://github.com/SDWebImage/SDWebImage/releases/tag/1.0.0)

## [1.0 on Dec 31st, 2009](https://github.com/SDWebImage/SDWebImage/releases/tag/1.0)


