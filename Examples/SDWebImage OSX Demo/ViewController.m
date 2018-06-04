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
@property (weak) IBOutlet NSButton *clearCacheButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Add GIF coder for better animated image rendering
    [[SDWebImageCodersManager sharedInstance] addCoder:[SDWebImageGIFCoder sharedCoder]];
    
    // NOTE: https links or authentication ones do not work (there is a crash)
    
//     Do any additional setup after loading the view.
    // For animated GIF rendering, set `animates` to YES or will only show the first frame
    self.imageView1.animates = YES;
    self.imageView3.animates = YES;
    [self.imageView1 sd_setImageWithURL:[NSURL URLWithString:@"http://assets.sbnation.com/assets/2512203/dogflops.gif"]];
    [self.imageView2 sd_setImageWithURL:[NSURL URLWithString:@"http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp"]];
    [self.imageView3 sd_setImageWithURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"]];
    self.imageView4.wantsLayer = YES;
    self.imageView4.sd_imageTransition = SDWebImageTransition.fadeTransition;
    [self.imageView4 sd_setImageWithURL:[NSURL URLWithString:@"http://s3.amazonaws.com/fast-image-cache/demo-images/FICDDemoImage001.jpg"] placeholderImage:nil options:SDWebImageForceTransition];
    
    self.clearCacheButton.target = self;
    self.clearCacheButton.action = @selector(clearCacheButtonClicked:);
    [self.clearCacheButton sd_setImageWithURL:[NSURL URLWithString:@"https://png.icons8.com/color/100/000000/delete-sign.png"]];
    [self.clearCacheButton sd_setAlternateImageWithURL:[NSURL URLWithString:@"https://png.icons8.com/color/100/000000/checkmark.png"]];
}

- (void)clearCacheButtonClicked:(NSResponder *)sender {
    NSButton *button = (NSButton *)sender;
    button.state = NSControlStateValueOn;
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] clearDiskOnCompletion:^{
        button.state = NSControlStateValueOff;
    }];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
