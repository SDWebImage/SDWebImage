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

### Using blocks

If your project's deployement target is set to iOS 4+, you may want to use the success/failure blocks to be
notified when image have been retrieved from cache.

    // Here we use the new provided setImageWithURL: method to load the web image
    [cell.imageView setImageWithURL:[NSURL URLWithString:@"http://www.domain.com/path/to/image.jpg"]
                   placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                            success:^(UIImage *image) {... success code here ...}
                            failure:^(NSError *error) {... failure code here ...}];
];

Note: neither your success nor failure block will be call if your image request is canceled before completion.

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

You can chose to copy all the files in your project or to import the it as a static library.

The following instructions are adapted from the excellent "Using Open Source Static Libraries in Xcode 4"
[tutorial][] from Jonah Williams.

### Add the SDWebImage project to your workspace

Make sure your project is in a workspace. If it's not, click File -> Save As Workspace first. 

Right-click on the project navigator and select "Add Files to "Your Project" and select SDWebImage.xcodeproj.
You may want to include the SDWebImage directory in your workspace repository before adding it to your project. 

![Add SDWebImage](http://blog.carbonfive.com/wp-content/uploads/2011/04/adding_an_existing_project.png?w=300)

You should end up with your project and SDWebimage project at the same level in the workspace.

### Build libSDWebImage.a File

Set your build target to iOS Device, then click Build. Make sure the libSDWebImage.a file inside SDWebImage -> Products is not red. 

### Add build target dependency

Select your project's build target and add the 'libSDWebImage.a' library to the "Link Binary With Libraries" inside the "Build Phases" tab.

![Add target dependency](http://blog.carbonfive.com/wp-content/uploads/2011/04/linkable_libraries.png?w=214)

You may also need to add MapKit.framework here too as 'MKAnnotationView_WebCache.h' depends on it. 

### Add headers

Open the "Build Settingsæ tab and locate the "User Header Search Paths" setting. Set this to 
"$(BUILT_PRODUCTS_DIR)/../../Headers" and check the "Recursive" check box.

![Header Search Paths](http://blog.carbonfive.com/wp-content/uploads/2011/04/header_search_path_value.png?w=300)

Add the "-ObjC" flag to the "Other Linker Flags" build setting.

### Build Project
At this point your workspace should build without error. If you are having problem, post to the Issue and the community can help you solve it. 

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
