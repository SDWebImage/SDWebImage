#import "UIView+CCKit.h"

@implementation UIView (CCKit)

+ (CGRect)cc_frameOfContentWithContentSize:(CGSize)contentSize
                             containerSize:(CGSize)size
                               contentMode:(UIViewContentMode)contentMode {
    CGFloat (^centerImageOriX)(void) = ^{
        return size.width/2 - contentSize.width/2;
    };
    CGFloat (^centerImageOriY)(void) = ^{
        return size.height/2 - contentSize.height/2;
    };
    
    CGRect frameImage = CGRectMake(0.0, 0.0, contentSize.width, contentSize.height);
    switch (contentMode) {
        case UIViewContentModeScaleToFill:
            frameImage = CGRectMake(0, 0, size.width, size.height);
            break;
        case UIViewContentModeScaleAspectFit: {
            CGFloat ratioW = size.width/contentSize.width;
            CGFloat ratioH = size.height/contentSize.height;
            CGFloat ratio = MIN(ratioW, ratioH);
            frameImage.size = CGSizeMake(floor(ratio * contentSize.width), floor(ratio * contentSize.height));
            frameImage.origin.x = size.width/2 - frameImage.size.width/2;
            frameImage.origin.y = size.height/2 - frameImage.size.height/2;
        }
            break;
        case UIViewContentModeScaleAspectFill: {
            CGFloat ratioW = size.width/contentSize.width;
            CGFloat ratioH = size.height/contentSize.height;
            CGFloat ratio = MAX(ratioW, ratioH);
            frameImage.size = CGSizeMake(floor(ratio * contentSize.width), floor(ratio * contentSize.height));
            frameImage.origin.x = size.width/2 - frameImage.size.width/2;
            frameImage.origin.y = size.height/2 - frameImage.size.height/2;
        }
            break;
            
        case UIViewContentModeCenter: {
            frameImage.origin.x = centerImageOriX();
            frameImage.origin.y = centerImageOriY();
        }
            break;
            
        case UIViewContentModeTop: {
            frameImage.origin.x = centerImageOriX();
            frameImage.origin.y = 0.0;
        }
            break;
            
        case UIViewContentModeBottom: {
            frameImage.origin.x = centerImageOriX();
            frameImage.origin.y = size.height - contentSize.height;
        }
            break;
            
        case UIViewContentModeLeft: {
            frameImage.origin.x = 0.0;
            frameImage.origin.y = centerImageOriY();
        }
            break;
            
        case UIViewContentModeRight: {
            frameImage.origin.x = size.width - contentSize.width;
            frameImage.origin.y = centerImageOriY();
        }
            break;
            
        case UIViewContentModeTopLeft: {
            frameImage.origin.x = 0.0;
            frameImage.origin.y = 0.0;
        }
            break;
            
        case UIViewContentModeTopRight: {
            frameImage.origin.x = size.width - contentSize.width;
            frameImage.origin.y = centerImageOriY();
        }
            break;
            
        case UIViewContentModeBottomLeft: {
            frameImage.origin.x = 0.0;
            frameImage.origin.y = size.height - contentSize.height;
        }
            break;
            
        case UIViewContentModeBottomRight: {
            frameImage.origin.x = size.width - contentSize.width;
            frameImage.origin.y = size.height - contentSize.height;
        }
            break;
            
        default:
            break;
    }
    return frameImage;
}

@end
