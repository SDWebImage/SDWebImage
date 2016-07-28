//
//  MasterViewController.m
//  SDWebImage Demo
//
//  Created by Olivier Poitrey on 09/05/12.
//  Copyright (c) 2012 Dailymotion. All rights reserved.
//

#import "MasterViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DetailViewController.h"
#import "UIImage+CCKit.h"

@interface SDTableViewCell : UITableViewCell

@property (nonatomic) UIImageView *sdImageView;

@end

@implementation SDTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _sdImageView = [[UIImageView alloc] init];
        [self.contentView addSubview:_sdImageView];
        _sdImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _sdImageView.frame = CGRectMake(0, 0, self.contentView.bounds.size.height, self.contentView.bounds.size.height);
}

@end

@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        self.title = @"SDWebImage";
        self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Clear Cache"
                                                                                style:UIBarButtonItemStylePlain
                                                                               target:self
                                                                               action:@selector(flushCache)];
        
        // HTTP NTLM auth example
        // Add your NTLM image url to the array below and replace the credentials
        [SDWebImageManager sharedManager].imageDownloader.username = @"httpwatch";
        [SDWebImageManager sharedManager].imageDownloader.password = @"httpwatch01";
        
        _objects = [NSMutableArray arrayWithObjects:
                    @"http://www.httpwatch.com/httpgallery/authentication/authenticatedimage/default.aspx?0.35786508303135633",     // requires HTTP auth, used to demo the NTLM auth
                    @"http://www.httpwatch.com/httpgallery/authentication/authenticatedimage/default.aspx?0.35786508303135633",
                    @"http://img1.cache.netease.com/catchpic/1/15/15D5A7755A09D20CD7AF179F1AD0ACE5.gif",
                    @"http://img1.cache.netease.com/catchpic/1/15/15D5A7755A09D20CD7AF179F1AD0ACE5.gif",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp",
                    nil];

        for (int i=0; i<100; i++) {
            [_objects addObject:[NSString stringWithFormat:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage%03d.jpg", i]];
            [_objects addObject:[NSString stringWithFormat:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage%03d.jpg", i]];
        }
        
        self.tableView.rowHeight = 100;

    }
    [SDWebImageManager.sharedManager.imageDownloader setValue:@"SDWebImage Demo" forHTTPHeaderField:@"AppName"];
    SDWebImageManager.sharedManager.imageDownloader.executionOrder = SDWebImageDownloaderLIFOExecutionOrder;
    return self;
}

- (void)flushCache
{
    [SDWebImageManager.sharedManager.imageCache clearMemory];
    [SDWebImageManager.sharedManager.imageCache clearDisk];
}
							
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    SDTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[SDTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    [cell.sdImageView setShowActivityIndicatorView:YES];
    [cell.sdImageView setIndicatorStyle:UIActivityIndicatorViewStyleGray];

    cell.textLabel.text = [NSString stringWithFormat:@"Image #%ld", (long)indexPath.row];
    cell.sdImageView.contentMode = UIViewContentModeScaleAspectFill;
    if (indexPath.row % 2 == 1) {
        [cell.sdImageView sd_setTransformDownloadedImageBlock:^UIImage *(UIImage *image, NSURL *imageUrl) {
            CGSize size = CGSizeMake(tableView.rowHeight, tableView.rowHeight);
            if (image.images) {
                NSMutableArray *mArray = [NSMutableArray array];
                for (UIImage *imageItem in image.images) {
                    [mArray addObject:[imageItem cc_imageWithSize:size cornerRadius:5]];
                }
                return [UIImage animatedImageWithImages:mArray duration:image.duration];
            } else {
                return [image cc_imageWithSize:size cornerRadius:5];
            }
        } transformKey:@"cornerRound"];
    } else {
        [cell.sdImageView sd_setTransformDownloadedImageBlock:nil transformKey:nil];
    }
    [cell.sdImageView sd_setImageWithURL:[NSURL URLWithString:[_objects objectAtIndex:indexPath.row]]
                        placeholderImage:[UIImage imageNamed:@"placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached:SDWebImageTransformAnimatedImage];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.detailViewController)
    {
        self.detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    }
    NSString *largeImageURL = [[_objects objectAtIndex:indexPath.row] stringByReplacingOccurrencesOfString:@"small" withString:@"source"];
    self.detailViewController.imageURL = [NSURL URLWithString:largeImageURL];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    self.detailViewController.transformKey = [cell.imageView sd_transformKey];
    self.detailViewController.transformImage = [cell.imageView sd_transformBlock];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

@end
