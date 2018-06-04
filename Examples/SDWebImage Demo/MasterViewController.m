/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "MasterViewController.h"
#import "DetailViewController.h"
#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>

@interface MyCustomTableViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *customTextLabel;
@property (nonatomic, strong) FLAnimatedImageView *customImageView;

@end

@implementation MyCustomTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _customImageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectMake(20.0, 2.0, 60.0, 40.0)];
        [self.contentView addSubview:_customImageView];
        _customTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(100.0, 12.0, 200, 20.0)];
        [self.contentView addSubview:_customTextLabel];
        
        _customImageView.clipsToBounds = YES;
        _customImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    return self;
}

@end

@interface MasterViewController ()

@property (nonatomic, strong) NSMutableArray<NSString *> *objects;

@end

@implementation MasterViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
        
        self.objects = [NSMutableArray arrayWithObjects:
                    @"http://www.httpwatch.com/httpgallery/authentication/authenticatedimage/default.aspx?0.35786508303135633",     // requires HTTP auth, used to demo the NTLM auth
                    @"http://assets.sbnation.com/assets/2512203/dogflops.gif",
                    @"https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
                    @"http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp",
                    @"http://littlesvr.ca/apng/images/SteamEngine.webp",
                    @"http://littlesvr.ca/apng/images/world-cup-2014-42.webp",
                    @"https://isparta.github.io/compare-webp/image/gif_webp/webp/2.webp",
                    @"https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png",
                    @"http://via.placeholder.com/200x200.jpg",
                    nil];

        for (int i=0; i<100; i++) {
            [self.objects addObject:[NSString stringWithFormat:@"https://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage%03d.jpg", i]];
        }

    }
    [SDWebImageManager.sharedManager.imageDownloader setValue:@"SDWebImage Demo" forHTTPHeaderField:@"AppName"];
    SDWebImageManager.sharedManager.imageDownloader.executionOrder = SDWebImageDownloaderLIFOExecutionOrder;
    return self;
}

- (void)flushCache
{
    [SDWebImageManager.sharedManager.imageCache clearMemory];
    [SDWebImageManager.sharedManager.imageCache clearDiskOnCompletion:nil];
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
    return self.objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    static UIImage *placeholderImage = nil;
    if (!placeholderImage) {
        placeholderImage = [UIImage imageNamed:@"placeholder"];
    }
    
    MyCustomTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MyCustomTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.customImageView.sd_imageTransition = SDWebImageTransition.fadeTransition;
    }

    [cell.customImageView sd_setShowActivityIndicatorView:YES];
    [cell.customImageView sd_setIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    cell.customTextLabel.text = [NSString stringWithFormat:@"Image #%ld", (long)indexPath.row];
    [cell.customImageView sd_setImageWithURL:[NSURL URLWithString:self.objects[indexPath.row]]
                            placeholderImage:placeholderImage
                                     options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *largeImageURLString = [self.objects[indexPath.row] stringByReplacingOccurrencesOfString:@"small" withString:@"source"];
    NSURL *largeImageURL = [NSURL URLWithString:largeImageURLString];
    DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil];
    detailViewController.imageURL = largeImageURL;
    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end
