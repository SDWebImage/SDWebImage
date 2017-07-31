<p align="center" >
  <img src="SDWebImage_logo.png" title="SDWebImage logo" float=left>
</p>


[![Build Status](http://img.shields.io/travis/rs/SDWebImage/master.svg?style=flat)](https://travis-ci.org/rs/SDWebImage)
[![Pod Version](http://img.shields.io/cocoapods/v/SDWebImage.svg?style=flat)](http://cocoadocs.org/docsets/SDWebImage/)
[![Pod Platform](http://img.shields.io/cocoapods/p/SDWebImage.svg?style=flat)](http://cocoadocs.org/docsets/SDWebImage/)
[![Pod License](http://img.shields.io/cocoapods/l/SDWebImage.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)
[![Dependency Status](https://www.versioneye.com/objective-c/sdwebimage/badge.svg?style=flat)](https://www.versioneye.com/objective-c/sdwebimage)
[![Reference Status](https://www.versioneye.com/objective-c/sdwebimage/reference_badge.svg?style=flat)](https://www.versioneye.com/objective-c/sdwebimage/references)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/rs/SDWebImage)
[![codecov](https://codecov.io/gh/rs/SDWebImage/branch/master/graph/badge.svg)](https://codecov.io/gh/rs/SDWebImage)

This library provides an async image downloader with cache support. For convenience, we added categories for UI elements like `UIImageView`, `UIButton`, `MKAnnotationView`.

## Features

- [x] Categories for `UIImageView`, `UIButton`, `MKAnnotationView` adding web image and cache management
- [x] An asynchronous image downloader
- [x] An asynchronous memory + disk image caching with automatic cache expiration handling
- [x] A background image decompression
- [x] A guarantee that the same URL won't be downloaded several times
- [x] A guarantee that bogus URLs won't be retried again and again
- [x] A guarantee that main thread will never be blocked
- [x] Performances!
- [x] Use GCD and ARC

## Supported Image Formats

- Image formats supported by UIImage (JPEG, PNG, ...), including GIF
- WebP format, including animated WebP (use the `WebP` subspec)

## Requirements

- iOS 7.0 or later
- tvOS 9.0 or later
- watchOS 2.0 or later
- OS X 10.8 or later
- Xcode 7.3 or later

#### Backwards compatibility

- For iOS 5 and 6, use [any 3.x version up to 3.7.6](https://github.com/rs/SDWebImage/tree/3.7.6)
- For iOS < 5.0, please use the last [2.0 version](https://github.com/rs/SDWebImage/tree/2.0-compat).

## Getting Started

- Read this Readme doc
- Read the [How to use section](https://github.com/rs/SDWebImage#how-to-use)
- Read the [documentation @ CocoaDocs](http://cocoadocs.org/docsets/SDWebImage/)
- Read [How is SDWebImage better than X?](https://github.com/rs/SDWebImage/wiki/How-is-SDWebImage-better-than-X%3F)
- Try the example by downloading the project from Github or even easier using CocoaPods try `pod try SDWebImage`
- Get to the [installation steps](https://github.com/rs/SDWebImage#installation)
- Read the [SDWebImage 4.0 Migration Guide](Docs/SDWebImage-4.0-Migration-guide.md) to get an idea of the changes from 3.x to 4.x

## Who Uses It
- Find out [who uses SDWebImage](https://github.com/rs/SDWebImage/wiki/Who-Uses-SDWebImage) and add your app to the list.

## Communication

- If you **need help**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/sdwebimage). (Tag 'sdwebimage')
- If you'd like to **ask a general question**, use [Stack Overflow](http://stackoverflow.com/questions/tagged/sdwebimage).
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## How To Use

```objective-c
Objective-C:

#import <SDWebImage/UIImageView+WebCache.h>
...
[imageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
             placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
```

```swift
Swift:

import SDWebImage

imageView.sd_setImage(with: URL(string: "http://www.domain.com/path/to/image.jpg"), placeholderImage: UIImage(named: "placeholder.png"))
```

- For details about how to use the library and clear examples, see [The detailed How to use](Docs/HowToUse.md)

## Animated Images (GIF) support

- Starting with the 4.0 version, we rely on [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) to take care of our animated images. 
- If you use cocoapods, add `pod 'SDWebImage/GIF'` to your podfile.
- To use it, simply make sure you use `FLAnimatedImageView` instead of `UIImageView`.
- **Note**: there is a backwards compatible feature, so if you are still trying to load a GIF into a `UIImageView`, it will only show the 1st frame as a static image.
- **Important**: FLAnimatedImage only works on the iOS platform. For OS X, use `NSImageView` with `animates` set to `YES` to show the entire animated images and `NO` to only show the 1st frame. For all the other platforms (tvOS, watchOS) we will fallback to the backwards compatibility feature described above 

## Common Problems

### Using dynamic image size with UITableViewCell

UITableView determines the size of the image by the first image set for a cell. If your remote images
don't have the same size as your placeholder image, you may experience strange anamorphic scaling issue.
The following article gives a way to workaround this issue:

[http://www.wrichards.com/blog/2011/11/sdwebimage-fixed-width-cell-images/](http://www.wrichards.com/blog/2011/11/sdwebimage-fixed-width-cell-images/)


### Handle image refresh

SDWebImage does very aggressive caching by default. It ignores all kind of caching control header returned by the HTTP server and cache the returned images with no time restriction. It implies your images URLs are static URLs pointing to images that never change. If the pointed image happen to change, some parts of the URL should change accordingly.

If you don't control the image server you're using, you may not be able to change the URL when its content is updated. This is the case for Facebook avatar URLs for instance. In such case, you may use the `SDWebImageRefreshCached` flag. This will slightly degrade the performance but will respect the HTTP caching control headers:

``` objective-c
[imageView sd_setImageWithURL:[NSURL URLWithString:@"https://graph.facebook.com/olivier.poitrey/picture"]
             placeholderImage:[UIImage imageNamed:@"avatar-placeholder.png"]
                      options:SDWebImageRefreshCached];
```

### Add a progress indicator

Add these before you call ```sd_setImageWithURL```

``` objective-c
[imageView sd_setShowActivityIndicatorView:YES];
[imageView sd_setIndicatorStyle:UIActivityIndicatorViewStyleGray];
```

``` swift
imageView.sd_setShowActivityIndicatorView(true)
imageView.sd_setIndicatorStyle(.Gray)
```

## Installation

There are three ways to use SDWebImage in your project:
- using CocoaPods
- using Carthage
- by cloning the project into your repository

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects. See the [Get Started](http://cocoapods.org/#get_started) section for more details.

#### Podfile
```
platform :ios, '7.0'
pod 'SDWebImage', '~> 4.0'
```

If you are using Swift, be sure to add `use_frameworks!` and set your target to iOS 8+:
```
platform :ios, '8.0'
use_frameworks!
```

#### Subspecs

There are 4 subspecs available now: `Core`, `MapKit`, `GIF` and `WebP` (this means you can install only some of the SDWebImage modules. By default, you get just `Core`, so if you need `WebP`, you need to specify it). 

Podfile example:
```
pod 'SDWebImage/WebP'
```

### Installation with Carthage (iOS 8+)

[Carthage](https://github.com/Carthage/Carthage) is a lightweight dependency manager for Swift and Objective-C. It leverages CocoaTouch modules and is less invasive than CocoaPods.

To install with carthage, follow the instruction on [Carthage](https://github.com/Carthage/Carthage)

#### Cartfile
```
github "rs/SDWebImage"
```

### Installation by cloning the repository
- see [Manual install](Docs/ManualInstallation.md)

### Import headers in your source files

In the source files where you need to use the library, import the header file:

```objective-c
#import <SDWebImage/UIImageView+WebCache.h>
```

### Build Project

At this point your workspace should build without error. If you are having problem, post to the Issue and the
community can help you solve it.

## Author
- [Olivier Poitrey](https://github.com/rs)

## Collaborators
- [Konstantinos K.](https://github.com/mythodeia)
- [Bogdan Poplauschi](https://github.com/bpoplauschi)
- [Chester Liu](https://github.com/skyline75489)
- [DreamPiggy](https://github.com/dreampiggy)

## Licenses

All source code is licensed under the [MIT License](https://raw.github.com/rs/SDWebImage/master/LICENSE).

## Architecture

<p align="center" >
    <img src="Docs/SDWebImageClassDiagram.png" title="SDWebImage class diagram">
</p>

<p align="center" >
    <img src="Docs/SDWebImageSequenceDiagram.png" title="SDWebImage sequence diagram">
</p>
