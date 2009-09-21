Dailymotion Web Image
=====================

This library provides a drop-in remplacement for UIImageVIew with support for remote images coming from the web.

It provides:
- Asynchronous image downloader
- Drop-in replacement to UIImageView
- Memory + disk image caching
- Uses NSOperation to perform parallel downloads and caching
- Handles cache expiration transparently

How To Use It
-------------

Most common use is in conjunction with an UITableView. Just place an UIImageView in you UITableViewCell in interface builder, and set its class to DMImageView in the identity panel. Then, in tableView:cellForRowAtIndexPath:, you just have to send a setImageWithURL: to the DMWebImage view with the URL of the image.

If in interface builder, an image was configured in the UIImageView, this image will be used as a placeholder, waiting for the web image to be loaded.

Future Enhancements
-------------------

- Easy way to use it with default UITableView styles without requiring to create a custom UITableViewCell
- LRU memory cache cleanup instead of reset on memory warning
