/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "DetailViewController.h"
#import <SDWebImage/SDWebImage.h>

@interface DetailViewController ()

@property (strong, nonatomic) IBOutlet SDAnimatedImageView *imageView;
@property (assign) BOOL tintApplied;

@end

@implementation DetailViewController

- (void)configureView {
    if (!self.imageView.sd_imageIndicator) {
        self.imageView.sd_imageIndicator = SDWebImageProgressIndicator.defaultIndicator;
    }
    BOOL isHDR = [self.imageURL.absoluteString containsString:@"HDR"];
    if (@available(iOS 17.0, *)) {
        self.imageView.preferredImageDynamicRange = isHDR ? UIImageDynamicRangeHigh : UIImageDynamicRangeUnspecified;
    }
    SDWebImageContext *context = @{
        SDWebImageContextImageDecodeToHDR: @(isHDR)
    };
    [self.imageView sd_setImageWithURL:self.imageURL
                      placeholderImage:nil
                               options:SDWebImageFromLoaderOnly | SDWebImageScaleDownLargeImages
                               context:context
                              progress:nil
                             completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        NSLog(@"isHighDynamicRange %@", @(image.sd_isHighDynamicRange));
    }];
    self.imageView.shouldCustomLoopCount = YES;
    self.imageView.animationRepeatCount = 0;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem.alloc initWithTitle:@"Toggle Animation"
                                                                            style:UIBarButtonItemStylePlain
                                                                           target:self
                                                                           action:@selector(toggleAnimation:)];
    // Add a secret title click action to apply tint color
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button addTarget:self
               action:@selector(toggleTint:)
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"Tint" forState:UIControlStateNormal];
    self.navigationItem.titleView = button;
}

- (void)toggleTint:(UIResponder *)sender {
    // tint for non-opaque animation
    if (!self.imageView.isAnimating) {
        return;
    }
    SDAnimatedImage *animatedImage = (SDAnimatedImage *)self.imageView.image;
    if (animatedImage.sd_imageFormat == SDImageFormatGIF) {
        // GIF is opaque
        return;
    }
    BOOL containsAlpha = [SDImageCoderHelper CGImageContainsAlpha:animatedImage.CGImage];
    if (!containsAlpha) {
        return;
    }
    if (self.tintApplied) {
        self.imageView.animationTransformer = nil;
    } else {
        self.imageView.animationTransformer = [SDImageTintTransformer transformerWithColor:UIColor.blackColor];
    }
    self.tintApplied = !self.tintApplied;
    // refresh
    UIImage *image = self.imageView.image;
    self.imageView.image = nil;
    self.imageView.image = image;
}

- (void)toggleAnimation:(UIResponder *)sender {
    self.imageView.isAnimating ? [self.imageView stopAnimating] : [self.imageView startAnimating];
}

@end
