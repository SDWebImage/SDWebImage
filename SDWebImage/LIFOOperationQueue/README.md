LIFOOperationQueue
==================

A last-in-first-out NSOperation queue written in Objective-C.

What's it for?
-------------

A LIFO queue can help prioritize new operations over old ones. One such example would be loading images in a `UITableView`. The LIFO approach will ensure that images on screen take higher priority than those a user has already scrolled past.

How does it work?
-----------------

LIFOOperationQueue is very much like `NSOperationQueue`. Just like the native implementation, you can configure the maximum number of concurrent operations. The only difference is that operations are added to the front of the queue and `NSOperationQueuePriority` has no effect. Initialization looks like this:

    // initialize LIFOOperationQueue with a maximum thread count of 4
    LIFOOperationQueue *operationQueue = [[LIFOOperationQueue alloc] initWithMaxConcurrentOperationCount:4];

Here are some quick examples of loading images in a `UITableView` with [AFNetworking](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&ved=0CEcQFjAA&url=https%3A%2F%2Fgithub.com%2FAFNetworking%2FAFNetworking&ei=jTwxUNnPNY6NigLmuYHoAw&usg=AFQjCNE6c3SnPVzdrmQ1-UQ5mEf8Kl9JXg&sig2=WtTzATbO_YTH888N5ZEcAQ) and LIFOOperationQueue.

    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        // create cell
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
        }
        
        // initialize imageView.image
        cell.imageView.image = [UIImage imageNamed:@"blankImage.png"];
        
        // create image request
        NSURL *imageUrl = [NSURL URLWithString:@"http://www.i-love-cats.com/software/Adorable-Cats-Screensaver.jpg"];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:imageUrl];
        AFImageRequestOperation *imageRequestOperation = [AFImageRequestOperation imageRequestOperationWithRequest:urlRequest success:^(UIImage *image) {
            UITableViewCell updateCell = [tableView cellForRowAtIndexPath:indexPath];
            if (updateCell)
                updateCell.imageView.image = image;
        }];
        
        // add to LIFOOperationQueue
        [self.operationQueue addOperation:imageRequestOperation];
        
        return cell;
    }

The code above would prioritize the latest cell's image over those that may not be on screen anymore. You can accomplish the same thing without AFNetworking by using blocks.

    - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        // create cell
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellIdentifier"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CellIdentifier"];
        }
        
        // initialize imageView.image
        cell.imageView.image = [UIImage imageNamed:@"blankImage.png"];
        
        // add block to LIFOOperationQueue
        [self.operationQueue addOperationWithBlock:^{
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
            
            // be sure to display image on main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                UITableViewCell updateCell = [tableView cellForRowAtIndexPath:indexPath];
                if (updateCell)
                    updateCell.imageView.image = image;
            });
        }];
        
        return cell;
    }

`addOperationWithBlock:` executes the block asynchronously by default.

License
-------
LIFOOperationQueue is available under the MIT license. See the LICENSE file for more info.
