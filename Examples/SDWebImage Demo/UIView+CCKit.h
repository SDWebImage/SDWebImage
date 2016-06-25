#import <UIKit/UIKit.h>

@interface UIView (CCKit)

+ (CGRect)cc_frameOfContentWithContentSize:(CGSize)contentSize
                             containerSize:(CGSize)size
                               contentMode:(UIViewContentMode)contentMode;

@end
