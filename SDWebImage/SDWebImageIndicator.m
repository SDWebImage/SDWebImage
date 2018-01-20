/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageIndicator.h"

#if SD_UIKIT || SD_MAC

#if SD_MAC
#import <QuartzCore/QuartzCore.h>
#endif

#pragma mark - Activity Indicator

@interface SDWebImageActivityIndicator ()

#if SD_UIKIT
@property (nonatomic, strong, readwrite, nonnull) UIActivityIndicatorView *indicatorView;
#else
@property (nonatomic, strong, readwrite, nonnull) NSProgressIndicator *indicatorView;
#endif

@end

@implementation SDWebImageActivityIndicator

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

#if SD_UIKIT
- (void)commonInit {
#if SD_TV
    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleWhite;
#else
    UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleGray;
#endif
    self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
    self.indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
}
#endif

#if SD_MAC
- (void)commonInit {
    self.indicatorView = [[NSProgressIndicator alloc] initWithFrame:NSZeroRect];
    self.indicatorView.style = NSProgressIndicatorStyleSpinning;
    self.indicatorView.controlSize = NSControlSizeSmall;
    [self.indicatorView sizeToFit];
    self.indicatorView.autoresizingMask = NSViewMaxXMargin | NSViewMinXMargin | NSViewMaxYMargin | NSViewMinYMargin;
}
#endif

- (void)startAnimatingIndicator {
#if SD_UIKIT
    [self.indicatorView startAnimating];
#else
    [self.indicatorView startAnimation:nil];
#endif
    self.indicatorView.hidden = NO;
}

- (void)stopAnimatingIndicator {
#if SD_UIKIT
    [self.indicatorView stopAnimating];
#else
    [self.indicatorView stopAnimation:nil];
#endif
    self.indicatorView.hidden = YES;
}

@end

@implementation SDWebImageActivityIndicator (Conveniences)

#if SD_MAC || SD_IOS
+ (SDWebImageActivityIndicator *)grayIndicator {
    SDWebImageActivityIndicator *indicator = [SDWebImageActivityIndicator new];
    return indicator;
}
#endif

#if SD_MAC
+ (SDWebImageActivityIndicator *)grayLargeIndicator {
    SDWebImageActivityIndicator *indicator = SDWebImageActivityIndicator.grayIndicator;
    indicator.indicatorView.controlSize = NSControlSizeRegular;
    [indicator.indicatorView sizeToFit];
    return indicator;
}
#endif

+ (SDWebImageActivityIndicator *)whiteIndicator {
    SDWebImageActivityIndicator *indicator = [SDWebImageActivityIndicator new];
#if SD_UIKIT
    indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
#else
    CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
    [lighten setDefaults];
    [lighten setValue:@(1) forKey:kCIInputBrightnessKey];
    indicator.indicatorView.contentFilters = @[lighten];
#endif
    return indicator;
}

+ (SDWebImageActivityIndicator *)whiteLargeIndicator {
    SDWebImageActivityIndicator *indicator = SDWebImageActivityIndicator.whiteIndicator;
#if SD_UIKIT
    indicator.indicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
#else
    indicator.indicatorView.controlSize = NSControlSizeRegular;
    [indicator.indicatorView sizeToFit];
#endif
    return indicator;
}

@end

#pragma mark - Progress Indicator

@interface SDWebImageProgressIndicator ()

#if SD_UIKIT
@property (nonatomic, strong, readwrite, nonnull) UIProgressView *indicatorView;
#else
@property (nonatomic, strong, readwrite, nonnull) NSProgressIndicator *indicatorView;
#endif

@end

@implementation SDWebImageProgressIndicator

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

#if SD_UIKIT
- (void)commonInit {
    self.indicatorView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
}
#endif

#if SD_MAC
- (void)commonInit {
    self.indicatorView = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 160, 0)];
    self.indicatorView.style = NSProgressIndicatorStyleBar;
    self.indicatorView.controlSize = NSControlSizeSmall;
    [self.indicatorView sizeToFit];
    self.indicatorView.autoresizingMask = NSViewMaxXMargin | NSViewMinXMargin | NSViewMaxYMargin | NSViewMinYMargin;
}
#endif

- (CGFloat)indicatorWidth {
    return self.indicatorView.frame.size.width;
}

- (void)setIndicatorWidth:(CGFloat)indicatorWidth {
    CGRect frame = self.indicatorView.frame;
    frame.size.width = indicatorWidth;
    self.indicatorView.frame = frame;
}

- (void)startAnimatingIndicator {
    self.indicatorView.hidden = NO;
#if SD_UIKIT
    self.indicatorView.progress = 0;
#else
    self.indicatorView.indeterminate = YES;
    self.indicatorView.doubleValue = 0;
    [self.indicatorView startAnimation:nil];
#endif
}

- (void)stopAnimatingIndicator {
    self.indicatorView.hidden = YES;
#if SD_UIKIT
    self.indicatorView.progress = 1;
#else
    self.indicatorView.indeterminate = NO;
    self.indicatorView.doubleValue = 1;
    [self.indicatorView stopAnimation:nil];
#endif
}

- (void)updateProgress:(double)progress {
#if SD_UIKIT
    [self.indicatorView setProgress:progress animated:YES];
#else
    self.indicatorView.indeterminate = progress > 0 ? NO : YES;
    self.indicatorView.doubleValue = progress * 100;
#endif
}

@end

@implementation SDWebImageProgressIndicator (Conveniences)

+ (SDWebImageProgressIndicator *)defaultIndicator {
    SDWebImageProgressIndicator *indicator = [SDWebImageProgressIndicator new];
    return indicator;
}

#if SD_IOS
+ (SDWebImageProgressIndicator *)barIndicator {
    SDWebImageProgressIndicator *indicator = [SDWebImageProgressIndicator new];
    indicator.indicatorView.progressViewStyle = UIProgressViewStyleBar;
    return indicator;
}
#endif

@end

#endif
