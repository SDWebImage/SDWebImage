Web Image
=========

This library provides a drop-in remplacement for UIImageVIew with support for remote images coming
from the web.

It provides:

- Drop-in replacement to UIImageView
- Asynchronous image downloader
- Asynchronous memory + disk image caching with automatic cache expiration handling

Motivation
----------

As a dummy Objective-C developer working on my first iPhone application for my company
([Dailymotion][]), I've been very frustrated by the lack of support in the Cocoa Touch framework for
UITableView with remote images. After some googling, I found lot of forums and blogs coming with
their solution, most of the time based on asynchronous usage have NSURLConnection, but none provides
a simple library doing the work of async image grabbing + caching for you.

Actually there is one in the famous [Three20][] framework by [Joe Hewitt][], but it's yet massive
and undocumented piece of code. You can't import just the the libraries you want without taking the
whole framework (damn #import "TTGlobal.h"). Anyway, the [Three20][] implementation is based on
NSURLConnection, and I soon discovered this solution wasn't ideal, keep reading to find out why.

As a hurried beginner in iPhone development, I couldn't admit to implement my own async image
grabber with caching support as my first steps in this new world. Thus, I asked for help to my good
friend Sebastien Flory ([Fraggle][]), who was working on his great iPhone game ([Urban Rivals][], a
future app-store hit) since almost a year. He spent quite an amount of time on implementing the very
same solution for his needs, and was kind enough to give me his implementation for my own use. This
worked quite well and allowed me to concentrate on other parts of my application. But when I started
to compare my application with its direct competitor - the built-in Youtube application - I was very
unhappy with the loading speed of the images. After some network sniffing, I found that every HTTP
requests for my images was 10 times slower than Youtube's ones... On my own network, Youtube was 10
time faster than my own servers... WTF??

In fact, my servers were well but a lot of latency was added to the requests, certainly because my
application wasn't responsive enough to handle the requests at full speed. At this moment, I
understood something important, asynchronous NSURLConnections are tied to the main runloop (I
guess). It's certainly based on the poll multiplexer system call, which allows a single thread to
handle quite a huge number of simultaneous connections. It works well while nothing blocks in the
loop, but in this loop, there is also the events handling. A simple test to recognize an application
using NSURLConnection to load there remote images is to scroll the UITableView with your finger to
disclose an unloaded image, and to keep your finger pressed on the screen. If the image doesn't load
until you release you finger, the application is certainly using NSURLConnection (try with the
Facebook app for instance). I'm not completely clear about the reason of this blocking, I thought
the iPhone was running a dedicated run-loop for connections, but the fact is, NSURLConnection is
affected by the application events and/or UI handling (or something else I'm not aware of).

Thus I explored another path and found this marvelous NSOperation class to handle concurrency with
love. I ran some quick tests with this tool and I instantly got enhanced responsiveness of the image
loading in my UITableView by... a lot. Thus I rewrote the [Fraggle][]'s implementation using the
same concept of drop-in remplacement for UIImageView but with this new technic. I thought the result
could benefits to a lot of other applications, thus we decided, with [Fraggle][], to open-sourced
it, et voila!

How To Use It
-------------

### DMWebImageView as UIImageWeb Drop-In Replacement

Most common use is in conjunction with an UITableView:

- Place an UIImageView as a subview of your UITableViewCell in Interface Builder
- Set its class to DMImageView in the identity panel.
- Optionally set an image from your bundle to this UIImageView, it will be used as a placeholder
  image waiting for the real image to be downloaded.
- In your tableView:cellForRowAtIndexPath: UITableViewDataSource method, invoke the setImageWithURL:
  method of the DMWebImage view with the URL of the image to download

Your done, everything will be handled for you, from parallel downloads to caching management.

### Asynchronous Image Downloader

It is possible to use the NSOperation based image downloader independently. Just create an instance
of DMWebImageDownloader using its convenience constructor downloaderWithURL:target:action:.

    downloader = [DMWebImageDownloader downloaderWithURL:url
                                                  target:self
                                                  action:@selector(downloadFinishedWithImage:)];

The download will by queued immediately and the downloadFinishedWithImage: method will be called as
soon as the download of image will be completed (prepare not to be called from the main thread).

### Asynchronous Image Caching

It is also possible to use the NSOperation based image cache store independently. DMImageCache
maintains a memory cache and an optional disk cache. Disk cache write operations are performed
asynchronous so it doesn't add unnecessary latency to the UI.

The DMImageCache class provides a singleton instance for convenience but you can create your own
instance if you want to create separated cache namespaces.

To lookup the cache, you use the imageForKey: method. If the method returns nil, it means the cache
doesn't currently own the image. You are thus responsible of generating and caching it. The cache
key is an application unique identifier for the image to cache. It is generally the absolute URL of
the image.

    UIImage *myCachedImage = [[DMImageCache sharedImageCache] imageFromKey:myCacheKey];

By default DMImageCache will lookup the disk cache if an image can't be found in the memory cache.
You can prevent this from happening by calling the alternative method imageFromKey:fromDisk: with a
negative second argument.

To store an image into the cache, you use the storeImage:forKey: method:

    [[DMImageCache sharedImageCache] storeImage:myImage forKey:myCacheKey];

By default, the image will be stored in memory cache as well as on disk cache (asynchronously). If
you want only the memory cache, use the alternative method storeImage:forKey:toDisk: with a negative
third argument.

Future Enhancements
-------------------

- Easy way to use it with default UITableView styles without requiring to create a custom UITableViewCell
- LRU memory cache cleanup instead of reset on memory warning


[Dailymotion]: http://www.dailymotion.com
[Fraggle]: http://fraggle.squarespace.com
[Urban Rivals]: http://fraggle.squarespace.com/blog/2009/9/15/almost-done-here-is-urban-rivals-iphone-trailer.html
[Three20]: http://groups.google.com/group/three20
[Joe Hewitt]: http://www.joehewitt.com