/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDAnimatedImage.h"
#import "NSImage+Additions.h"
#import "UIImage+WebCache.h"
#import "SDWebImageCoder.h"
#import "SDWebImageCodersManager.h"

static CGFloat SDImageScaleFromPath(NSString *string) {
    if (string.length == 0 || [string hasSuffix:@"/"]) return 1;
    NSString *name = string.stringByDeletingPathExtension;
    __block CGFloat scale = 1;
    
    NSRegularExpression *pattern = [NSRegularExpression regularExpressionWithPattern:@"@[0-9]+\\.?[0-9]*x$" options:NSRegularExpressionAnchorsMatchLines error:nil];
    [pattern enumerateMatchesInString:name options:kNilOptions range:NSMakeRange(0, name.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        if (result.range.location >= 3) {
            scale = [string substringWithRange:NSMakeRange(result.range.location + 1, result.range.length - 2)].doubleValue;
        }
    }];
    
    return scale;
}

@interface SDAnimatedImage ()

@property (nonatomic, strong) id<SDWebImageAnimatedCoder> coder;
@property (nonatomic, assign, readwrite) NSUInteger animatedImageLoopCount;
@property (nonatomic, assign, readwrite) NSUInteger animatedImageFrameCount;
@property (nonatomic, assign, readwrite) SDImageFormat animatedImageFormat;
@property (nonatomic, assign) BOOL animatedImageLoopCountCheck;
@property (nonatomic, assign) BOOL animatedImageFrameCountChecked;

#if SD_MAC
@property (nonatomic, assign) CGFloat scale;
#endif

@end

@implementation SDAnimatedImage

#pragma mark - UIImage override method
+ (instancetype)imageWithContentsOfFile:(NSString *)path {
    return [[self alloc] initWithContentsOfFile:path];
}

+ (instancetype)imageWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

+ (instancetype)imageWithData:(NSData *)data scale:(CGFloat)scale {
    return [[self alloc] initWithData:data scale:scale];
}

- (instancetype)initWithContentsOfFile:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithData:data scale:SDImageScaleFromPath(path)];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data scale:1];
}

- (instancetype)initWithData:(NSData *)data scale:(CGFloat)scale {
    if (!data || data.length == 0) {
        return nil;
    }
    if (scale <= 0) {
#if SD_WATCH
        scale = [WKInterfaceDevice currentDevice].screenScale;
#elif SD_UIKIT
        scale = [UIScreen mainScreen].scale;
#endif
    }
    for (id<SDWebImageCoder>coder in [SDWebImageCodersManager sharedInstance].coders) {
        if ([coder conformsToProtocol:@protocol(SDWebImageAnimatedCoder)]) {
            if ([coder canDecodeFromData:data]) {
                id<SDWebImageAnimatedCoder> animatedCoder = [[[coder class] alloc] initWithAnimatedImageData:data];
                if (!animatedCoder) {
                    // check next coder
                    continue;
                } else {
                    self.coder = animatedCoder;
                    break;
                }
            }
        }
    }
    if (!self.coder) {
        return nil;
    }
    UIImage *image = [self.coder animatedImageFrameAtIndex:0];
    if (!image) {
        return nil;
    }
#if SD_MAC
    self = [super initWithCGImage:image.CGImage size:NSZeroSize];
#else
    self = [super initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
#endif
    if (!self) {
        return nil;
    }
    SDImageFormat format = [NSData sd_imageFormatForImageData:data];
    self.animatedImageFormat = format;
    return self;
}

#pragma mark - NSSecureCoding
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    NSNumber *scale = [aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(scale))];
    NSData *animatedImageData = [aDecoder decodeObjectOfClass:[NSData class] forKey:NSStringFromSelector(@selector(animatedImageData))];
    if (animatedImageData) {
        return [self initWithData:animatedImageData scale:scale.doubleValue];
    } else {
        return [super initWithCoder:aDecoder];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    if (self.animatedImageData) {
        [aCoder encodeObject:self.animatedImageData forKey:NSStringFromSelector(@selector(animatedImageData))];
        [aCoder encodeObject:@(self.scale) forKey:NSStringFromSelector(@selector(scale))];
    } else {
        [super encodeWithCoder:aCoder];
    }
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark - SDAnimatedImage
- (NSUInteger)animatedImageLoopCount {
    if (!self.animatedImageLoopCountCheck) {
        self.animatedImageLoopCountCheck = YES;
        _animatedImageLoopCount = [self.coder animatedImageLoopCount];
    }
    return _animatedImageLoopCount;
}

- (NSUInteger)animatedImageFrameCount {
    if (!self.animatedImageFrameCountChecked) {
        self.animatedImageFrameCountChecked = YES;
        _animatedImageFrameCount = [self.coder animatedImageFrameCount];
    }
    return _animatedImageFrameCount;
}

- (UIImage *)animatedImageFrameAtIndex:(NSUInteger)index {
    return [self.coder animatedImageFrameAtIndex:index];
}

- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index { 
    return [self.coder animatedImageDurationAtIndex:index];
}

- (NSData *)animatedImageData {
    return self.coder.animatedImageData;
}

@end
