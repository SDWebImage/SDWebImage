Web Image
=========

This library provides a category for UIImageVIew with support for remote images coming from the web.

It provides:

- An UIImageView category adding web image and cache management to the Cocoa Touch framework
- An asynchronous image downloader
- An asynchronous memory + disk image caching with automatic cache expiration handling
- A guarantee that the same URL won't be downloaded several times
- A guarantee that bogus URLs won't be retried again and again
- Performances!

Motivation
----------

As a dummy Objective-C developer working on my first iPhone application for my company
([Dailymotion][]), I've been very frustrated by the lack of support in the Cocoa Touch framework for
UITableView with remote images. After some Googling, I found lot of forums and blogs coming up with
their solution, most of the time based on asynchronous usage with NSURLConnection, but none provided
a simple library doing the work of async image grabbing + caching for you.

Actually there is one in the famous [Three20][] framework by [Joe Hewitt][], but it's a massive
and undocumented piece of code. You can't import just the the libraries you want without taking the
whole framework (damn #import "TTGlobal.h"). Anyway, the [Three20][] implementation is based on
NSURLConnection, and I soon discovered this solution wasn't ideal. Keep reading to find out why.

As a hurried beginner in iPhone development, I couldn't attempt to implement my own async image
grabber with caching support as my first steps in this new world. Thus, I asked for help from my good
friend Sebastien Flory ([Fraggle][]), who was working on his great iPhone game ([Urban Rivals][], a
future app-store hit) for almost a year. He spent quite an amount of time implementing the very
same solution for his needs, and was kind enough to give me his implementation for my own use. This
worked quite well and allowed me to concentrate on other parts of my application. But when I started
to compare my application with its direct competitor - the built-in Youtube application - I was very
unhappy with the loading speed of the images. After some network sniffing, I found that every HTTP
requests for my images was 10 times slower than Youtube's... On my own network, Youtube was 10
time faster than my own servers... WTF??

In fact, my servers were fine but a lot of latency was added to the requests, certainly because my
application wasn't responsive enough to handle the requests at full speed. Right then, I
understood something important, asynchronous NSURLConnections are tied to the main runloop in the
NSEventTrackingRunLoopMode. As explained in the documentation, this runloop mode is affected by
UI events:

> Cocoa uses this mode to restrict incoming events during mouse-dragging loops and other sorts of
> user interface tracking loops.

A simple test to recognize an application using NSURLConnection in its default mode to load
remote images is to scroll the UITableView with your finger to disclose an unloaded image, and to
keep your finger pressed on the screen. If the image doesn't load until you release you finger,
you've got one (try with the Facebook app for instance). It took me quite some time to understand
the reason for this lagging issue. Actually I first used NSOperation to workaround this issue.

This technique combined with an image cache instantly gave a lot of responsiveness to my app.
I thought this library could benefit other Cocoa Touch applications so I open-sourced it.

How To Use It
-------------

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

If your project's deployement target is set to iOS 4+, you may want to use the success/failure blocks to be
notified when image have been retrieved from cache.
```objective-c
// Here we use the new provided setImageWithURL: method to load the web image
[cell.imageView setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
               placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                        success:^(UIImage *image) {... success code here ...}
                        failure:^(NSError *error) {... failure code here ...}];
];
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
                delegate:self
                 options:0
                 success:^(UIImage *image)
                 {
                     // do something with image
                 }
                 failure:nil];
```

### Using Asynchronous Image Downloader Independently

It is possible to use the async image downloader independently. You just have to create an instance
of SDWebImageDownloader using its convenience constructor downloaderWithURL:delegate:.
```objective-c
downloader = [SDWebImageDownloader downloaderWithURL:url delegate:self];
```

The download will start immediately and the imageDownloader:didFinishWithImage: method from the
SDWebImageDownloaderDelegate protocol will be called as soon as the download of image is completed.

### Using Asynchronous Image Caching Independently

It is also possible to use the NSOperation based image cache store independently. SDImageCache
maintains a memory cache and an optional disk cache. Disk cache write operations are performed
asynchronous so it doesn't add unnecessary latency to the UI.

The SDImageCache class provides a singleton instance for convenience but you can create your own
instance if you want to create separated cache namespace.

To lookup the cache, you use the imageForKey: method. If the method returns nil, it means the cache
doesn't currently own the image. You are thus responsible for generating and caching it. The cache
key is an application unique identifier for the image to cache. It is generally the absolute URL of
the image.

```objective-c
UIImage *myCachedImage = [[SDImageCache sharedImageCache] imageFromKey:myCacheKey];
```

By default SDImageCache will lookup the disk cache if an image can't be found in the memory cache.
You can prevent this from happening by calling the alternative method imageFromKey:fromDisk: with a
negative second argument.

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
    [[SDWebImageManager sharedManager] setCacheKeyFilter:^(NSURL *url)
    {
        url = [[[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path] autorelease];
        return [url absoluteString];
    }];

    // Your app init code...
    return YES;
}
```


Common Problems
---------------

### No image appear when using UITableViewCell

If choose to use a default cell template provided by UITableViewCell with SDWebImage, ensure you are
providing a placeholder image, otherwise the cell will be initialized with no image.

### Using dynamic image size with UITableViewCell

UITableView determins the size of the image by the first image set for a cell. If your remote images
don't have the same size as your placeholder image, you may experience strange anamorphic scaling issue.
The following article gives a way to workaround this issue:

[http://www.wrichards.com/blog/2011/11/sdwebimage-fixed-width-cell-images/](http://www.wrichards.com/blog/2011/11/sdwebimage-fixed-width-cell-images/)

Automatic Reference Counting (ARC)
----------------------------------

You can use either style in your Cocoa project. SDWebImage Will figure out which you are using at compile
time and do the right thing.


Installation
------------

There are two ways to use this in your project: copy all the files into your project, or import the project as a static library.

### Add the SDWebImage project to your project

Right-click on the project navigator and select "Add Files to "Your Project":

![Add Library Project](http://dl.dropbox.com/u/123346/SDWebImage/01_add_library_project.jpg)

In the dialog, select SDWebImage.xcodeproj:

![Add Library Project Dialog](http://dl.dropbox.com/u/123346/SDWebImage/02_add_library_project_dialog.jpg)

After you’ve added the subproject, it’ll appear below the main project in Xcode’s Navigator tree:

![Library Added](http://dl.dropbox.com/u/123346/SDWebImage/03_library_added.jpg)

You may want to add the SDWebImage directory in your project source tree as a submodule before adding it to your project.

### Add build target dependencies

In you application project app’s target settings, find the "Build Phases" section and open the "Target Dependencies" block:

![Add Target Dependencies](http://dl.dropbox.com/u/123346/SDWebImage/04_add_target_dependencies.jpg)

Click the "+" button and select "SDWebImage ARC" (you may choose the non ARC target if you want to support iOS <3 or the ARC+MKAnnotation if you need MapKit category):

![Add Target Dependencies Dialog](http://dl.dropbox.com/u/123346/SDWebImage/05_add_target_dependencies_dialog.jpg)

Open the "Link Binary With Libraries" block:

![Add Library Link](http://dl.dropbox.com/u/123346/SDWebImage/06_add_library_link.jpg)

Click the "+" button and select "libSDWebImageARC.a" library (use non ARC version if you chose non ARC version in the previous step):

![Add Library Link Dialog](http://dl.dropbox.com/u/123346/SDWebImage/07_add_library_link_dialog.jpg)

If you chose to link against the ARC+MKAnnotation target, click the "+" button again and select "MapKit.framework":

![Add ImageIO Framework](http://dl.dropbox.com/u/123346/SDWebImage/08_add_imageio_framework.jpg)

Click the "+" button again and select the "ImageIO.framework", this is needed by the progressive download feature:

![Add MapKit Framework](http://dl.dropbox.com/u/123346/SDWebImage/09_add_mapkit_framework.jpg)

### Add headers

Open the "Build Settings" tab, locate the "Other Linker Flags" setting and add the "-ObjC" flag:

![Other Linker Flags](http://dl.dropbox.com/u/123346/SDWebImage/10_other_linker_flags.jpg)

Locate "Header Search Paths" (and not "User Header Search Paths") and add two settings: ”$(TARGET_BUILD_DIR)/usr/local/lib/include” and ”$(OBJROOT)/UninstalledProducts/include”. Make sure to include the quotes here:

![User Header Search Paths](http://dl.dropbox.com/u/123346/SDWebImage/11_user_header_search_paths.jpg)

### Import headers in your source files

In the source files where you need to use the library, use ``#import <SDWebImage/HeaderFileName.h>``:

```objective-c
#import <SDWebImage/UIImageView+WebCache.h>
```

### Build Project

At this point your workspace should build without error. If you are having problem, post to the Issue and the
community can help you solve it.

### Fixing indexing

If you have problem with auto-completion of SDWebImage methods, you may have to copy the header files in
your project.


Future Enhancements
-------------------

- LRU memory cache cleanup instead of reset on memory warning

[Dailymotion]: http://www.dailymotion.com
[Fraggle]: http://fraggle.squarespace.com
[Urban Rivals]: http://fraggle.squarespace.com/blog/2009/9/15/almost-done-here-is-urban-rivals-iphone-trailer.html
[Three20]: http://groups.google.com/group/three20
[Joe Hewitt]: http://www.joehewitt.com
[tutorial]: http://blog.carbonfive.com/2011/04/04/using-open-source-static-libraries-in-xcode-4
