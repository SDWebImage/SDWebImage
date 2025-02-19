/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ViewController.h"
#import <SDWebImage/SDWebImage.h>

@interface ViewController ()

@property (strong) NSImageView *imageView1;
@property (strong) SDAnimatedImageView *imageView2;

@property (strong) NSImageView *imageView3;
@property (strong) SDAnimatedImageView *imageView4;

@property (strong) NSImageView *imageView5;
@property (strong) NSImageView *imageView6;

@property (weak) IBOutlet NSButton *clearCacheButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.imageView1 = [NSImageView new];
    self.imageView2 = [SDAnimatedImageView new];
    self.imageView3 = [NSImageView new];
    self.imageView4 = [SDAnimatedImageView new];
    self.imageView5 = [NSImageView new];
    self.imageView6 = [NSImageView new];
    
    [self.view addSubview:self.imageView1];
    [self.view addSubview:self.imageView2];
    [self.view addSubview:self.imageView3];
    [self.view addSubview:self.imageView4];
    [self.view addSubview:self.imageView5];
    [self.view addSubview:self.imageView6];
    
    // For animated GIF rendering, set `animates` to YES or will only show the first frame
    self.imageView3.animates = YES; // `SDAnimatedImageRep` can be used for built-in `NSImageView` to support better GIF & APNG rendering as well. No need `SDAnimatedImageView`
    self.imageView4.animates = YES;
    
#pragma mark - Static Image
    // NSImageView + Static Image
    self.imageView1.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    [self.imageView1 sd_setImageWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/recurser/exif-orientation-examples/master/Landscape_2.jpg"] placeholderImage:nil options:SDWebImageProgressiveLoad];
    // SDAnimatedImageView + Static Image
    [self.imageView2 sd_setImageWithURL:[NSURL URLWithString:@"https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png"]];
    
#pragma mark - Animated Image
    // NSImageView + Animated Image
    self.imageView3.sd_imageIndicator = SDWebImageActivityIndicator.largeIndicator;
    [self.imageView3 sd_setImageWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/onevcat/APNGKit/2.2.0/Tests/APNGKitTests/Resources/General/APNG-cube.apng"]];
    NSMenu *menu1 = [[NSMenu alloc] initWithTitle:@"Toggle Animation"];
    NSMenuItem *item1 = [menu1 addItemWithTitle:@"Toggle Animation" action:@selector(toggleAnimation:) keyEquivalent:@""];
    item1.tag = 1;
    self.imageView3.menu = menu1;
    // SDAnimatedImageView + Animated Image
    self.imageView4.sd_imageTransition = SDWebImageTransition.fadeTransition;
    self.imageView4.imageScaling = NSImageScaleProportionallyUpOrDown;
    self.imageView4.imageAlignment = NSImageAlignLeft; // supports NSImageView's layout properties
    [self.imageView4 sd_setImageWithURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/SteamEngine.webp"]];
    NSMenu *menu2 = [[NSMenu alloc] initWithTitle:@"Toggle Animation"];
    NSMenuItem *item2 = [menu2 addItemWithTitle:@"Toggle Animation" action:@selector(toggleAnimation:) keyEquivalent:@""];
    item2.tag = 2;
    self.imageView4.menu = menu2;
    
#pragma mark - HDR Image
    // HDR Image
    if (@available(macOS 14.0, *)) {
        self.imageView5.preferredImageDynamicRange = NSImageDynamicRangeHigh;
        self.imageView6.preferredImageDynamicRange = NSImageDynamicRangeHigh;
    }
    [self.imageView5 sd_setImageWithURL:[NSURL URLWithString:@"https://lightroom.adobe.com/v2c/spaces/113ab046f0d04b40aa7f8e10285961a7/assets/cd191116be514e1288ca6ea372303139/revisions/2749aff3294e404c9ffce3518e467d4a/renditions/99673919d096b42650b448f6516089cc.avif"] placeholderImage:nil options:0 context:@{SDWebImageContextImageDecodeToHDR : @(YES)}];
    // SDR Image
    [self.imageView6 sd_setImageWithURL:[NSURL URLWithString:@"https://lightroom.adobe.com/v2c/spaces/113ab046f0d04b40aa7f8e10285961a7/assets/cd191116be514e1288ca6ea372303139/revisions/2749aff3294e404c9ffce3518e467d4a/renditions/99673919d096b42650b448f6516089cc"] placeholderImage:nil options:0 context:@{SDWebImageContextImageDecodeToHDR : @(NO)}];
    
    self.clearCacheButton.target = self;
    self.clearCacheButton.action = @selector(clearCacheButtonClicked:);
    [self.clearCacheButton sd_setImageWithURL:[NSURL URLWithString:@"https://png.icons8.com/color/100/000000/delete-sign.png"]];
    [self.clearCacheButton sd_setAlternateImageWithURL:[NSURL URLWithString:@"https://png.icons8.com/color/100/000000/checkmark.png"]];
}

- (void)viewDidLayout {
    [super viewDidLayout];
    CGFloat space = 20;
    CGFloat imageWidth = (self.view.frame.size.width - space * 4) / 3;
    CGFloat imageHeight = (self.view.frame.size.height - space * 3) / 2;
    
    self.imageView1.frame = CGRectMake(space * 1 + imageWidth * 0, space, imageWidth, imageHeight);
    self.imageView2.frame = CGRectMake(self.imageView1.frame.origin.x, self.imageView1.frame.origin.y + imageHeight + space, imageWidth, imageHeight);
    self.imageView3.frame = CGRectMake(space * 2 + imageWidth * 1, space, imageWidth, imageHeight);
    self.imageView4.frame = CGRectMake(self.imageView3.frame.origin.x, self.imageView3.frame.origin.y + imageHeight + space, imageWidth, imageHeight);
    self.imageView5.frame = CGRectMake(space * 3 + imageWidth * 2, space, imageWidth, imageHeight);
    self.imageView6.frame = CGRectMake(self.imageView5.frame.origin.x, self.imageView5.frame.origin.y + imageHeight + space, imageWidth, imageHeight);
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
    NSImageView *imageView = sender.tag == 1 ? self.imageView3 : self.imageView4;
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
