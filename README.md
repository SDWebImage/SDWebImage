Web Image
=========
[![Build Status](http://img.shields.io/travis/rs/SDWebImage/master.svg?style=flat)](https://travis-ci.org/rs/SDWebImage)
[![Pod Version](http://img.shields.io/cocoapods/v/SDWebImage.svg?style=flat)](http://cocoadocs.org/docsets/SDWebImage/)
[![Pod Platform](http://img.shields.io/cocoapods/p/SDWebImage.svg?style=flat)](http://cocoadocs.org/docsets/SDWebImage/)
[![Pod License](http://img.shields.io/cocoapods/l/SDWebImage.svg?style=flat)](https://www.apache.org/licenses/LICENSE-2.0.html)

This library provides a category for UIImageView with support for remote images coming from the web.

It provides:

- An UIImageView category adding web image and cache management to the Cocoa Touch framework
- An asynchronous image downloader
- An asynchronous memory + disk image caching with automatic cache expiration handling
- Animated GIF support
- WebP format support
- A background image decompression
- A guarantee that the same URL won't be downloaded several times
- A guarantee that bogus URLs won't be retried again and again
- A guarantee that main thread will never be blocked
- Performances!
- Use GCD and ARC
- Arm64 support

NOTE: The version 3.0 of SDWebImage isn't fully backward compatible with 2.0 and requires iOS 5.1.1
minimum deployement version. If you need iOS < 5.0 support, please use the last [2.0 version](https://github.com/rs/SDWebImage/tree/2.0-compat).

[How is SDWebImage better than X?](https://github.com/rs/SDWebImage/wiki/How-is-SDWebImage-better-than-X%3F)

Who Use It
----------

Find out [who uses SDWebImage](https://github.com/rs/SDWebImage/wiki/Who-Uses-SDWebImage) and add your app to the list.

How To Use
----------

API documentation is available at [http://hackemist.com/SDWebImage/doc/](http://hackemist.com/SDWebImage/doc/)

### Using UIImageView+WebCache category with UITableView

Just #import the UIImageView+WebCache.h header, and call the setImageWithURL:placeholderImage:
method from the tableView:cellForRowAtIndexPath: UITableViewDataSource method. Everything will be
handled for you, from async downloads to caching management.

```objective-c
#import <SDWebImage/UIImageView+WebCache.h>

...

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyIdentifier = @"MyIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];

    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:MyIdentifier] autorelease];
    }

    // Here we use the new provided setImageWithURL: method to load the web image
    [cell.imageView setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
                   placeholderImage:[UIImage imageNamed:@"placeholder.png"]];

    cell.textLabel.text = @"My Text";
    return cell;
}
```

### Using blocks

With blocks, you can be notified about the image download progress and whenever the image retrival
has completed with success or not:

```objective-c
// Here we use the new provided setImageWithURL: method to load the web image
[cell.imageView setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
               placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {... completion code here ...}];
```

Note: neither your success nor failure block will be call if your image request is canceled before completion.

### Using SDWebImageManager

The SDWebImageManager is the class behind the UIImageView+WebCache category. It ties the
asynchronous downloader with the image cache store. You can use this class directly to benefit
from web image downloading with caching in another context than a UIView (ie: with Cocoa).

Here is a simple example of how to use SDWebImageManager:

```objective-c
SDWebImageManager *manager = [SDWebImageManager sharedManager];
[manager downloadWithURL:imageURL
                 options:0
                 progress:^(NSInteger receivedSize, NSInteger expectedSize)
                 {
                     // progression tracking code
                 }
                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished)
                 {
                     if (image)
                     {
                         // do something with image
                     }
                 }];
```

### Using Asynchronous Image Downloader Independently

It's also possible to use the async image downloader independently:

```objective-c
[SDWebImageDownloader.sharedDownloader downloadImageWithURL:imageURL
                                                    options:0
                                                   progress:^(NSInteger receivedSize, NSInteger expectedSize)
                                                   {
                                                       // progression tracking code
                                                   }
                                                   completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
                                                   {
                                                       if (image && finished)
                                                       {
                                                           // do something with image
                                                       }
                                                   }];
```

### Using Asynchronous Image Caching Independently

It is also possible to use the aync based image cache store independently. SDImageCache
maintains a memory cache and an optional disk cache. Disk cache write operations are performed
asynchronous so it doesn't add unnecessary latency to the UI.

The SDImageCache class provides a singleton instance for convenience but you can create your own
instance if you want to create separated cache namespace.

To lookup the cache, you use the `queryDiskCacheForKey:done:` method. If the method returns nil, it means the cache
doesn't currently own the image. You are thus responsible for generating and caching it. The cache
key is an application unique identifier for the image to cache. It is generally the absolute URL of
the image.

```objective-c
SDImageCache *imageCache = [[SDImageCache alloc] initWithNamespace:@"myNamespace"];
[imageCache queryDiskCacheForKey:myCacheKey done:^(UIImage *image)
{
    // image is not nil if image was found
}];
```

By default SDImageCache will lookup the disk cache if an image can't be found in the memory cache.
You can prevent this from happening by calling the alternative method `imageFromMemoryCacheForKey:`.

To store an image into the cache, you use the storeImage:forKey: method:

```objective-c
[[SDImageCache sharedImageCache] storeImage:myImage forKey:myCacheKey];
```

By default, the image will be stored in memory cache as well as on disk cache (asynchronously). If
you want only the memory cache, use the alternative method storeImage:forKey:toDisk: with a negative
third argument.

### Using cache key filter

Sometime, you may not want to use the image URL as cache key because part of the URL is dynamic
(i.e.: for access control purpose). SDWebImageManager provides a way to set a cache key filter that
takes the NSURL as input, and output a cache key NSString.

The following example sets a filter in the application delegate that will remove any query-string from
the URL before to use it as a cache key:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SDWebImageManager.sharedManager.cacheKeyFilter:^(NSURL *url)
    {
        url = [[[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path] autorelease];
        return [url absoluteString];
    };

    // Your app init code...
    return YES;
}
```


Common Problems
---------------

### Using dynamic image size with UITableViewCell

UITableView determins the size of the image by the first image set for a cell. If your remote images
don't have the same size as your placeholder image, you may experience strange anamorphic scaling issue.
The following article gives a way to workaround this issue:

[http://www.wrichards.com/blog/2011/11/sdwebimage-fixed-width-cell-images/](http://www.wrichards.com/blog/2011/11/sdwebimage-fixed-width-cell-images/)


### Handle image refresh

SDWebImage does very aggressive caching by default. It ignores all kind of caching control header returned by the HTTP server and cache the returned images with no time restriction. It implies your images URLs are static URLs pointing to images that never change. If the pointed image happen to change, some parts of the URL should change accordingly.

If you don't control the image server you're using, you may not be able to change the URL when its content is updated. This is the case for Facebook avatar URLs for instance. In such case, you may use the `SDWebImageRefreshCached` flag. This will slightly degrade the performance but will respect the HTTP caching control headers:

``` objective-c
[imageView setImageWithURL:[NSURL URLWithString:@"https://graph.facebook.com/olivier.poitrey/picture"]
          placeholderImage:[UIImage imageNamed:@"avatar-placeholder.png"]
                   options:SDWebImageRefreshCached];
```

### Add a progress indicator

See this category: https://github.com/JJSaccolo/UIActivityIndicator-for-SDWebImage

Installation
------------

There are three ways to use SDWebImage in your project:
- using Cocoapods
- copying all the files into your project
- importing the project as a static library

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects. See the [Get Started](http://cocoapods.org/#get_started) section for more details.

#### Podfile
```
platform :ios, '6.1'
pod 'SDWebImage', '~>3.6'
```

### Add the SDWebImage project to your project

- Download and unzip the last version of the framework from the [download page](https://github.com/rs/SDWebImage/releases)
- Right-click on the project navigator and select "Add Files to "Your Project":
- In the dialog, select SDWebImage.framework:
- Check the "Copy items into destination group's folder (if needed)" checkbox

### Add dependencies

- In you application project app’s target settings, find the "Build Phases" section and open the "Link Binary With Libraries" block:
- Click the "+" button again and select the "ImageIO.framework", this is needed by the progressive download feature:

### Add Linker Flag

Open the "Build Settings" tab, in the "Linking" section, locate the "Other Linker Flags" setting and add the "-ObjC" flag:

![Other Linker Flags](http://dl.dropbox.com/u/123346/SDWebImage/10_other_linker_flags.jpg)

Alternatively, if this causes compilation problems with frameworks that extend optional libraries, such as Parse,  RestKit or opencv2, instead of the -ObjC flag use:

```
-force_load SDWebImage.framework/Versions/Current/SDWebImage
```

### Import headers in your source files

In the source files where you need to use the library, import the header file:

```objective-c
#import <SDWebImage/UIImageView+WebCache.h>
```

### Build Project

At this point your workspace should build without error. If you are having problem, post to the Issue and the
community can help you solve it.

Future Enhancements
-------------------

- LRU memory cache cleanup instead of reset on memory warning

## Licenses

All source code is licensed under the [MIT License](https://raw.github.com/rs/SDWebImage/master/LICENSE).
