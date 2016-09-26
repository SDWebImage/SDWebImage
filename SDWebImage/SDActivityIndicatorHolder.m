/*
 * This file is part of the SDWebImage package.
 * Created by Vadim Zhepetov on 09/09/16. <vadim.z178@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDActivityIndicatorHolder.h"
#import "SDWebImageCompat.h"

@interface SDActivityIndicatorHolder()

@property (nonatomic) UIActivityIndicatorView *indicator;

@end

@implementation SDActivityIndicatorHolder

- (void)addIndicatorToView:(UIView *)view {
    if (!self.indicator) {
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:self.style];
        self.indicator.translatesAutoresizingMaskIntoConstraints = NO;
        
        dispatch_main_async_safe(^{
            [view addSubview:self.indicator];
            
            [view addConstraint:[NSLayoutConstraint constraintWithItem:self.indicator
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0
                                                              constant:0.0]];
            [view addConstraint:[NSLayoutConstraint constraintWithItem:self.indicator
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                              constant:0.0]];
        });
    }
    
    dispatch_main_async_safe(^{
        [self.indicator startAnimating];
    });
    
}

- (void)removeIndicator {
    if (self.indicator) {
        [self.indicator removeFromSuperview];
        self.indicator = nil;
    }
}

@end
