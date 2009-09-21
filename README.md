Dailymotion Web Image
=====================

This library provides a drop-in remplacement for UIImageVIew with support for remote images coming from the web.

It provides:

- Drop-in replacement to UIImageView
- Asynchronous image downloader
- Asynchronous memory + disk image caching with automatic cache expiration handling

How To Use It
-------------

### DMWebImageView as UIImageWeb Drop-In Replacement

Most common use is in conjunction with an UITableView:

- Place an UIImageView as a subview of your UITableViewCell in Interface Builder
- Set its class to DMImageView in the identity panel.
- Optionally set an image from your bundle to this UIImageView, it will be used as a placeholder image waiting for the real image to be downloaded.
- In your tableView:cellForRowAtIndexPath: UITableViewDataSource method, invoke the setImageWithURL: method of the DMWebImage view with the URL of the image to download

Your done, everything will be handled for you, from parallel downloads to caching management.

### Asynchronous Image Downloader

It is possible to use the NSOperation based image downloader independently. Just create an instance of DMWebImageDownloader using its convenience constructor downloaderWithURL:target:action:.

    DMWebImageDownloader *downloader = [DMWebImageDownloader downloaderWithURL:url target:self action:@selector(downloadFinishedWithImage:)];

The download will by queued immediately and the downloadFinishedWithImage: method will be called as soon as the download of image will be completed (prepare not to be called from the main thread).

### Asynchronous Image Caching

It is also possible to use the NSOperation based image cache store independently. DMImageCache maintains a memory cache and an optional disk cache. Disk cache write operations are performed asynchronous so it doesn't add unnecessary latency to the UI.

The DMImageCache class provides a singleton instance for convenience but you can create your own instance if you want to create separated cache namespaces.

To lookup the cache, you use the imageForKey: method. If the method returns nil, it means the cache doesn't currently own the image. You are thus responsible of generating and caching it. The cache key is an application unique identifier for the image to cache. It is generally the absolute URL of the image.

    UIImage *myCachedImage = [[DMImageCache sharedImageCache] imageFromKey:myCacheKey];

By default DMImageCache will lookup the disk cache if an image can't be found in the memory cache. You can prevent this from happening by calling the alternative method imageFromKey:fromDisk: with a negative second argument.

To store an image into the cache, you use the storeImage:forKey: method:

    [[DMImageCache sharedImageCache] storeImage:myImage forKey:myCacheKey];

By default, the image will be stored in memory cache as well as on disk cache (asynchronously). If you want only the memory cache, use the alternative method storeImage:forKey:toDisk: with a negative third argument.

Future Enhancements
-------------------

- Easy way to use it with default UITableView styles without requiring to create a custom UITableViewCell
- LRU memory cache cleanup instead of reset on memory warning
