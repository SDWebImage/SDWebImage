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

### Using UIImageView+WebCache category with UITableView

Just #import the UIImageView+WebCache.h header, and call the setImageWithURL:placeholderImage:
method from the tableView:cellForRowAtIndexPath: UITableViewDataSource method. Everything will be
handled for you, from async downloads to caching management.

    #import "UIImageView+WebCache.h"

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

### Using SDWebImageManager

The SDWebImageManager is the class behind the UIImageView+WebCache category. It ties the
asynchronous downloader with the image cache store. You can use this class directly to benefit
from web image downloading with caching in another context than a UIView (ie: with Cocoa).

Here is a simple example of how to use SDWebImageManager:

    SDWebImageManager *manager = [SDWebImageManager sharedManager];

    UIImage *cachedImage = [manager imageWithURL:url];

    if (cachedImage)
    {
        // Use the cached image immediatly
    }
    else
    {
        // Start an async download
        [manager downloadWithURL:url delegate:self];
    }

Your class will have to implement the SDWebImageManagerDelegate protocol, and to implement the
webImageManager:didFinishWithImage: method from this protocol:

    - (void)webImageManager:(SDWebImageManager *)imageManager didFinishWithImage:(UIImage *)image
    {
        // Do something with the downloaded image
    }

### Using Asynchronous Image Downloader Independently

It is possible to use the async image downloader independently. You just have to create an instance
of SDWebImageDownloader using its convenience constructor downloaderWithURL:delegate:.

    downloader = [SDWebImageDownloader downloaderWithURL:url delegate:self];

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

    UIImage *myCachedImage = [[SDImageCache sharedImageCache] imageFromKey:myCacheKey];

By default SDImageCache will lookup the disk cache if an image can't be found in the memory cache.
You can prevent this from happening by calling the alternative method imageFromKey:fromDisk: with a
negative second argument.

To store an image into the cache, you use the storeImage:forKey: method:

    [[SDImageCache sharedImageCache] storeImage:myImage forKey:myCacheKey];

By default, the image will be stored in memory cache as well as on disk cache (asynchronously). If
you want only the memory cache, use the alternative method storeImage:forKey:toDisk: with a negative
third argument.

Future Enhancements
-------------------

- LRU memory cache cleanup instead of reset on memory warning

[Dailymotion]: http://www.dailymotion.com
[Fraggle]: http://fraggle.squarespace.com
[Urban Rivals]: http://fraggle.squarespace.com/blog/2009/9/15/almost-done-here-is-urban-rivals-iphone-trailer.html
[Three20]: http://groups.google.com/group/three20
[Joe Hewitt]: http://www.joehewitt.com
