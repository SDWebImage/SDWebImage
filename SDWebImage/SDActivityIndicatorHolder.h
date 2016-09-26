/*
 * This file is part of the SDWebImage package.
 * Created by Vadim Zhepetov on 09/09/16. <vadim.z178@gmail.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>

@interface SDActivityIndicatorHolder : NSObject

@property (nonatomic) UIActivityIndicatorViewStyle style;

- (void)addIndicatorToView:(UIView *)view;
- (void)removeIndicator;

@end
