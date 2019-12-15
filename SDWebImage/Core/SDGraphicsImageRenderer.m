/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDGraphicsImageRenderer.h"
#import "SDImageGraphics.h"

@interface SDGraphicsImageRendererFormat ()
#if SD_UIKIT
@property (nonatomic, strong) UIGraphicsImageRendererFormat *uiformat API_AVAILABLE(ios(10.0), tvos(10.0));
#endif
@end

@implementation SDGraphicsImageRendererFormat

- (instancetype)init {
    self = [super init];
    if (self) {
#if SD_UIKIT
        if (@available(iOS 10.0, tvOS 10.10, *)) {
            UIGraphicsImageRendererFormat *uiformat = [[UIGraphicsImageRendererFormat alloc] init];
            self.uiformat = uiformat;
            self.scale = uiformat.scale;
            self.opaque = uiformat.opaque;
            if (@available(iOS 12.0, tvOS 12.0, *)) {
                self.preferredRange = (SDGraphicsImageRendererFormatRange)uiformat.preferredRange;
            } else {
                if (uiformat.prefersExtendedRange) {
                    self.preferredRange = SDGraphicsImageRendererFormatRangeExtended;
                } else {
                    self.preferredRange = SDGraphicsImageRendererFormatRangeStandard;
                }
            }
        } else {
#endif
            self.scale = 1.0;
            self.opaque = NO;
            self.preferredRange = SDGraphicsImageRendererFormatRangeUnspecified;
#if SD_UIKIT
        }
#endif
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
- (instancetype)initForMainScreen {
    self = [super init];
    if (self) {
#if SD_UIKIT
        if (@available(iOS 10.0, tvOS 10.0, *)) {
            UIGraphicsImageRendererFormat *uiformat;
            // iOS 11.0.0 GM does have `preferredFormat`, but iOS 11 betas did not (argh!)
            if ([UIGraphicsImageRenderer respondsToSelector:@selector(preferredFormat)]) {
                uiformat = [UIGraphicsImageRendererFormat preferredFormat];
            } else {
                uiformat = [UIGraphicsImageRendererFormat defaultFormat];
            }
            self.uiformat = uiformat;
            self.scale = uiformat.scale;
            self.opaque = uiformat.opaque;
            if (@available(iOS 12.0, tvOS 12.0, *)) {
                self.preferredRange = (SDGraphicsImageRendererFormatRange)uiformat.preferredRange;
            } else {
                if (uiformat.prefersExtendedRange) {
                    self.preferredRange = SDGraphicsImageRendererFormatRangeExtended;
                } else {
                    self.preferredRange = SDGraphicsImageRendererFormatRangeStandard;
                }
            }
        } else {
#endif
#if SD_WATCH
            CGFloat screenScale = [WKInterfaceDevice currentDevice].screenScale;
#elif SD_UIKIT
            CGFloat screenScale = [UIScreen mainScreen].scale;
#elif SD_MAC
            CGFloat screenScale = [NSScreen mainScreen].backingScaleFactor;
#endif
            self.scale = screenScale;
            self.opaque = NO;
            self.preferredRange = SDGraphicsImageRendererFormatRangeUnspecified;
#if SD_UIKIT
        }
#endif
    }
    return self;
}
#pragma clang diagnostic pop

+ (instancetype)preferredFormat {
    SDGraphicsImageRendererFormat *format = [[SDGraphicsImageRendererFormat alloc] initForMainScreen];
    return format;
}

@end

@interface SDGraphicsImageRenderer ()
@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) SDGraphicsImageRendererFormat *format;
#if SD_UIKIT
@property (nonatomic, strong) UIGraphicsImageRenderer *uirenderer API_AVAILABLE(ios(10.0), tvos(10.0));
#endif
@end

@implementation SDGraphicsImageRenderer

- (instancetype)initWithSize:(CGSize)size {
    return [self initWithSize:size format:SDGraphicsImageRendererFormat.preferredFormat];
}

- (instancetype)initWithSize:(CGSize)size format:(SDGraphicsImageRendererFormat *)format {
    NSParameterAssert(format);
    self = [super init];
    if (self) {
        self.size = size;
        self.format = format;
#if SD_UIKIT
        if (@available(iOS 10.0, tvOS 10.0, *)) {
            UIGraphicsImageRendererFormat *uiformat = format.uiformat;
            self.uirenderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:uiformat];
        }
#endif
    }
    return self;
}

- (UIImage *)imageWithActions:(NS_NOESCAPE SDGraphicsImageDrawingActions)actions {
    NSParameterAssert(actions);
#if SD_UIKIT
    if (@available(iOS 10.0, tvOS 10.0, *)) {
        UIGraphicsImageDrawingActions uiactions = ^(UIGraphicsImageRendererContext *rendererContext) {
            if (actions) {
                actions(rendererContext.CGContext);
            }
        };
        return [self.uirenderer imageWithActions:uiactions];
    } else {
#endif
        SDGraphicsBeginImageContextWithOptions(self.size, self.format.opaque, self.format.scale);
        CGContextRef context = SDGraphicsGetCurrentContext();
        if (actions) {
            actions(context);
        }
        UIImage *image = SDGraphicsGetImageFromCurrentImageContext();
        SDGraphicsEndImageContext();
        return image;
#if SD_UIKIT
    }
#endif
}

@end
