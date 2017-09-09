/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ViewController.h"

@import SDWebImage;

@interface ViewController ()

@property (weak) IBOutlet NSImageView *imageView1;
@property (weak) IBOutlet NSImageView *imageView2;
@property (weak) IBOutlet NSImageView *imageView3;
@property (weak) IBOutlet NSImageView *imageView4;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NOTE: https links or authentication ones do not work (there is a crash)
    
//     Do any additional setup after loading the view.
    // For animated GIF rendering, set `animates` to YES or will only show the first frame
    self.imageView1.animates = YES;
    [self.imageView1 sd_setImageWithURL:[NSURL URLWithString:@"http://assets.sbnation.com/assets/2512203/dogflops.gif"]];
    [self.imageView2 sd_setImageWithURL:[NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"]];
    [self.imageView3 sd_setImageWithURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"]];
    [self.imageView4 sd_setImageWithURL:[NSURL URLWithString:@"http://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage001.jpg"]];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
