/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ViewController.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>

@interface ViewController ()

@property (weak) IBOutlet NSImageView *imageView1;
@property (weak) IBOutlet NSImageView *imageView2;
@property (weak) IBOutlet SDAnimatedImageView *imageView3;
@property (weak) IBOutlet SDAnimatedImageView *imageView4;
@property (weak) IBOutlet NSButton *clearCacheButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
    
    // For animated GIF rendering, set `animates` to YES or will only show the first frame
    self.imageView2.animates = YES; // `SDAnimatedImageRep` can be used for built-in `NSImageView` to support better GIF & APNG rendering as well. No need `SDAnimatedImageView`
    self.imageView4.animates = YES;
    
    // NSImageView + Static Image
    self.imageView1.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    [self.imageView1 sd_setImageWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/recurser/exif-orientation-examples/master/Landscape_2.jpg"] placeholderImage:nil options:SDWebImageProgressiveLoad];
    
    // NSImageView + Animated Image
    self.imageView2.sd_imageIndicator = SDWebImageActivityIndicator.largeIndicator;
    [self.imageView2 sd_setImageWithURL:[NSURL URLWithString:@"https:raw.githubusercontent.com/onevcat/APNGKit/master/TestImages/APNG-cube.apng"]];
    NSMenu *menu1 = [[NSMenu alloc] initWithTitle:@"Toggle Animation"];
    NSMenuItem *item1 = [menu1 addItemWithTitle:@"Toggle Animation" action:@selector(toggleAnimation:) keyEquivalent:@""];
    item1.tag = 1;
    self.imageView2.menu = menu1;
    
    // SDAnimatedImageView + Static Image
    [self.imageView3 sd_setImageWithURL:[NSURL URLWithString:@"https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png"]];
    
    // SDAnimatedImageView + Animated Image
    self.imageView4.sd_imageTransition = SDWebImageTransition.fadeTransition;
    self.imageView4.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.imageView4.imageAlignment = NSImageAlignLeft; // supports NSImageView's layout properties
    [self.imageView4 sd_setImageWithURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"] placeholderImage:nil options:SDWebImageForceTransition];
    NSMenu *menu2 = [[NSMenu alloc] initWithTitle:@"Toggle Animation"];
    NSMenuItem *item2 = [menu2 addItemWithTitle:@"Toggle Animation" action:@selector(toggleAnimation:) keyEquivalent:@""];
    item2.tag = 2;
    self.imageView4.menu = menu2;
    
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

- (void)toggleAnimation:(NSMenuItem *)sender {
    NSImageView *imageView = sender.tag == 1 ? self.imageView2 : self.imageView4;
    if (imageView.animates) {
        imageView.animates = NO;
    } else {
        imageView.animates = YES;
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
