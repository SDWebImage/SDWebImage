/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTransformer.h"
#if SD_UIKIT || SD_MAC
#import <CoreImage/CoreImage.h>
#endif

@interface UIColor (Additions)

@property (nonatomic, copy, readonly, nonnull) NSString *sd_hexString;

@end

@implementation UIColor (Additions)

- (NSString *)sd_hexString {
    CGFloat red, green, blue, alpha;
#if SD_UIKIT
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        [self getWhite:&red alpha:&alpha];
        green = red;
        blue = red;
    }
#else
    @try {
        [self getRed:&red green:&green blue:&blue alpha:&alpha];
    }
    @catch (NSException *exception) {
        [self getWhite:&red alpha:&alpha];
        green = red;
        blue = red;
    }
#endif
    
    red = roundf(red * 255.f);
    green = roundf(green * 255.f);
    blue = roundf(blue * 255.f);
    alpha = roundf(alpha * 255.f);
    
    uint hex = ((uint)alpha << 24) | ((uint)red << 16) | ((uint)green << 8) | ((uint)blue);
    
    return [NSString stringWithFormat:@"0x%08x", hex];
}

@end

NSString * const SDWebImageTransformerKeySeparator = @"-";

@interface SDWebImagePipelineTransformer ()

@property (nonatomic, copy, readwrite, nonnull) NSArray<id<SDWebImageTransformer>> *transformers;
@property (nonatomic, copy, readwrite) NSString *transformerKey;

@end

@implementation SDWebImagePipelineTransformer

- (instancetype)initWithTransformers:(NSArray<id<SDWebImageTransformer>> *)transformers {
    self = [super init];
    if (self) {
        _transformers = [transformers copy];
        _transformerKey = [[self class] cacheKeyForTransformers:transformers];
    }
    return self;
}

+ (NSString *)cacheKeyForTransformers:(NSArray<id<SDWebImageTransformer>> *)transformers {
    if (transformers.count == 0) {
        return @"";
    }
    NSMutableArray<NSString *> *cacheKeys = [NSMutableArray arrayWithCapacity:transformers.count];
    [transformers enumerateObjectsUsingBlock:^(id<SDWebImageTransformer>  _Nonnull transformer, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *cacheKey = transformer.transformerKey;
        [cacheKeys addObject:cacheKey];
    }];
    
    return [cacheKeys componentsJoinedByString:SDWebImageTransformerKeySeparator];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    UIImage *transformedImage = image;
    for (id<SDWebImageTransformer> transformer in self.transformers) {
        transformedImage = [transformer transformedImageWithImage:transformedImage forKey:key];
    }
    return transformedImage;
}

- (void)addTransformer:(id<SDWebImageTransformer>)transformer {
    if (!transformer) {
        return;
    }
    self.transformers = [self.transformers arrayByAddingObject:transformer];
}

- (void)removeTransformer:(id<SDWebImageTransformer>)transformer {
    if (!transformer) {
        return;
    }
    NSMutableArray<id<SDWebImageTransformer>> *transformers = [self.transformers mutableCopy];
    [transformers removeObject:transformer];
    self.transformers = [transformers copy];
}

@end

@implementation SDWebImageRoundCornerTransformer

- (instancetype)initWithRadius:(CGFloat)cornerRadius corners:(SDRectCorner)corners borderWidth:(CGFloat)borderWidth borderColor:(nullable UIColor *)borderColor {
    self = [super init];
    if (self) {
        _cornerRadius = cornerRadius;
        _corners = corners;
        _borderWidth = borderWidth;
        _borderColor = borderColor;
    }
    return self;
}

- (NSString *)transformerKey {
    return [NSString stringWithFormat:@"SDWebImageRoundCornerTransformer(%f,%lu,%f,%@)", self.cornerRadius, (unsigned long)self.corners, self.borderWidth, self.borderColor.sd_hexString];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_roundedCornerImageWithRadius:self.cornerRadius corners:self.corners borderWidth:self.borderWidth borderColor:self.borderColor];
}

@end

@implementation SDWebImageResizingTransformer

- (instancetype)initWithSize:(CGSize)size scaleMode:(SDImageScaleMode)scaleMode {
    self = [super init];
    if (self) {
        _size = size;
        _scaleMode = scaleMode;
    }
    return self;
}

- (NSString *)transformerKey {
    CGSize size = self.size;
    return [NSString stringWithFormat:@"SDWebImageResizingTransformer({%f,%f},%lu)", size.width, size.height, (unsigned long)self.scaleMode];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_resizedImageWithSize:self.size scaleMode:self.scaleMode];
}

@end

@implementation SDWebImageCroppingTransformer

- (instancetype)initWithRect:(CGRect)rect {
    self = [super init];
    if (self) {
        _rect = rect;
    }
    return self;
}

- (NSString *)transformerKey {
    CGRect rect = self.rect;
    return [NSString stringWithFormat:@"SDWebImageCroppingTransformer({%f,%f,%f,%f})", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_croppedImageWithRect:self.rect];
}

@end

@implementation SDWebImageFlippingTransformer

- (instancetype)initWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical {
    self = [super init];
    if (self) {
        _horizontal = horizontal;
        _vertical = vertical;
    }
    return self;
}

- (NSString *)transformerKey {
    return [NSString stringWithFormat:@"SDWebImageFlippingTransformer(%d,%d)", self.horizontal, self.vertical];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_flippedImageWithHorizontal:self.horizontal vertical:self.vertical];
}

@end

@implementation SDWebImageRotationTransformer

- (instancetype)initWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize {
    self = [super init];
    if (self) {
        _angle = angle;
        _fitSize = fitSize;
    }
    return self;
}

- (NSString *)transformerKey {
    return [NSString stringWithFormat:@"SDWebImageRotationTransformer(%f,%d)", self.angle, self.fitSize];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_rotatedImageWithAngle:self.angle fitSize:self.fitSize];
}

@end

#pragma mark - Image Blending

@implementation SDWebImageTintTransformer

- (instancetype)initWithColor:(UIColor *)tintColor {
    self = [super init];
    if (self) {
        _tintColor = tintColor;
    }
    return self;
}

- (NSString *)transformerKey {
    return [NSString stringWithFormat:@"SDWebImageTintTransformer(%@)", self.tintColor.sd_hexString];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_tintedImageWithColor:self.tintColor];
}

@end

#pragma mark - Image Effect

@implementation SDWebImageBlurTransformer

- (instancetype)initWithRadius:(CGFloat)blurRadius {
    self = [super init];
    if (self) {
        _blurRadius = blurRadius;
    }
    return self;
}

- (NSString *)transformerKey {
    return [NSString stringWithFormat:@"SDWebImageBlurTransformer(%f)", self.blurRadius];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_blurredImageWithRadius:self.blurRadius];
}

@end

#if SD_UIKIT || SD_MAC
@implementation SDWebImageFilterTransformer

- (instancetype)initWithFilter:(CIFilter *)filter {
    self = [super init];
    if (self) {
        _filter = filter;
    }
    return self;
}

- (NSString *)transformerKey {
    return [NSString stringWithFormat:@"SDWebImageFilterTransformer(%@)", self.filter.name];
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    if (!image) {
        return nil;
    }
    return [image sd_filteredImageWithFilter:self.filter];
}

@end
#endif
