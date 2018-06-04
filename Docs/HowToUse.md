#### Using `UIImageView+WebCache` category with `UITableView`

Just import the `UIImageView+WebCache.h` header, and call the `sd_setImageWithURL:placeholderImage:`
method from the `tableView:cellForRowAtIndexPath:` `UITableViewDataSource` method. Everything will be
handled for you, from async downloads to caching management.

```objective-c
#import <SDWebImage/UIImageView+WebCache.h>

...

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"MyIdentifier";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                       reuseIdentifier:MyIdentifier] autorelease];
    }

    // Here we use the new provided sd_setImageWithURL: method to load the web image
    [cell.imageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
                      placeholderImage:[UIImage imageNamed:@"placeholder.png"]];

    cell.textLabel.text = @"My Text";
    return cell;
}
```

```swift
import SDWebImage
...
func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
    static let myIdentifier = "MyIdentifier"
    let cell = tableView.dequeueReusableCellWithIdentifier(myIdentifier, forIndexPath: indexPath) as UITableViewCell

    cell.imageView.sd_setImageWithURL(imageUrl, placeholderImage:placeholderImage)
    return cell
```

### Using blocks

With blocks, you can be notified about the image download progress and whenever the image retrieval has completed with success or not:

```objective-c
// Here we use the new provided sd_setImageWithURL: method to load the web image
[cell.imageView sd_setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
                  placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                ... completion code here ...
                             }];
```

Note: neither your success nor failure block will be call if your image request is canceled before completion.

### Using SDWebImageManager

The `SDWebImageManager` is the class behind the `UIImageView(WebCache)` category. It ties the asynchronous downloader with the image cache store. You can use this class directly to benefit from web image downloading with caching in another context than a `UIView` (ie: with Cocoa).

Note: When the image is from memory cache, it will not contains any `NSData` by default. However, if you need image data, you can pass `SDWebImageQueryDataWhenInMemory` in options arg.

Here is a simple example of how to use `SDWebImageManager`:

```objective-c
SDWebImageManager *manager = [SDWebImageManager sharedManager];
[manager loadImageWithURL:imageURL
                  options:0
                 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                        // progression tracking code
                 }
                 completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    if (image) {
                        // do something with image
                    }
                 }];
```

### Using Asynchronous Image Downloader Independently

It's also possible to use the async image downloader independently:

```objective-c
SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
[downloader downloadImageWithURL:imageURL
                         options:0
                        progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                            // progression tracking code
                        }
                       completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                            if (image && finished) {
                                // do something with image
                            }
                        }];
```

### Using Asynchronous Image Caching Independently

It is also possible to use the async based image cache store independently. SDImageCache
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
[imageCache queryDiskCacheForKey:myCacheKey done:^(UIImage *image) {
    // image is not nil if image was found
}];
```

By default SDImageCache will lookup the disk cache if an image can't be found in the memory cache.
You can prevent this from happening by calling the alternative method `imageFromMemoryCacheForKey:`.

To store an image into the cache, you use the storeImage:forKey:completion: method:

```objective-c
[[SDImageCache sharedImageCache] storeImage:myImage forKey:myCacheKey completion:^{
    // image stored
}];
```

By default, the image will be stored in memory cache as well as on disk cache (asynchronously). If
you want only the memory cache, use the alternative method storeImage:forKey:toDisk:completion: with a negative
third argument.

### Using cache key filter

Sometime, you may not want to use the image URL as cache key because part of the URL is dynamic
(i.e.: for access control purpose). SDWebImageManager provides a way to set a cache key filter that
takes the NSURL as input, and output a cache key NSString.

The following example sets a filter in the application delegate that will remove any query-string from
the URL before to use it as a cache key:

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    SDWebImageManager.sharedManager.cacheKeyFilter = ^(NSURL *url) {
        url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
        return [url absoluteString];
    };

    // Your app init code...
    return YES;
}
```
