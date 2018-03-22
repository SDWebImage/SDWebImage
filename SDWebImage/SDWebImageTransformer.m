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

// Separator for different transformerKey, for example, `image.png` |> flip(YES,NO) |> rotate(pi/4,YES) => 'image-SDWebImageFlippingTransformer(1,0)-SDWebImageRotationTransformer(0.78539816339,1).png'
static NSString * const SDWebImageTransformerKeySeparator = @"-";

NSString * _Nullable SDTransformedKeyForKey(NSString * _Nullable key, NSString * _Nonnull transformerKey) {
    if (!key || !transformerKey) {
        return nil;
    }
    return [[key stringByAppendingString:SDWebImageTransformerKeySeparator] stringByAppendingString:transformerKey];
}

@interface UIColor (HexString)

/**
 Convenience way to get hex string from color. The output should always be 32-bit RGBA hex string like `#00000000`.
 */
@property (nonatomic, copy, readonly, nonnull) NSString *sd_hexString;

@end

@implementation UIColor (HexString)

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
    
    return [NSString stringWithFormat:@"#%08x", hex];
}

@end

@interface SDWebImagePipelineTransformer ()

@property (nonatomic, copy, readwrite, nonnull) NSArray<id<SDWebImageTransformer>> *transformers;
@property (nonatomic, copy, readwrite) NSString *transformerKey;

@end

@implementation SDWebImagePipelineTransformer

+ (instancetype)transformerWithTransformers:(NSArray<id<SDWebImageTransformer>> *)transformers {
    SDWebImagePipelineTransformer *transformer = [SDWebImagePipelineTransformer new];
    transformer.transformers = transformers;
    transformer.transformerKey = [[self class] cacheKeyForTransformers:transformers];
    
    return transformer;
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

@end

@interface SDWebImageRoundCornerTransformer ()

@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) SDRectCorner corners;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, strong, nullable) UIColor *borderColor;

@end

@implementation SDWebImageRoundCornerTransformer

+ (instancetype)transformerWithRadius:(CGFloat)cornerRadius corners:(SDRectCorner)corners borderWidth:(CGFloat)borderWidth borderColor:(UIColor *)borderColor {
    SDWebImageRoundCornerTransformer *transformer = [SDWebImageRoundCornerTransformer new];
    transformer.cornerRadius = cornerRadius;
    transformer.corners = corners;
    transformer.borderWidth = borderWidth;
    transformer.borderColor = borderColor;
    
    return transformer;
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

@interface SDWebImageResizingTransformer ()

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) SDImageScaleMode scaleMode;

@end

@implementation SDWebImageResizingTransformer

+ (instancetype)transformerWithSize:(CGSize)size scaleMode:(SDImageScaleMode)scaleMode {
    SDWebImageResizingTransformer *transformer = [SDWebImageResizingTransformer new];
    transformer.size = size;
    transformer.scaleMode = scaleMode;
    
    return transformer;
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

@interface SDWebImageCroppingTransformer ()

@property (nonatomic, assign) CGRect rect;

@end

@implementation SDWebImageCroppingTransformer

+ (instancetype)transformerWithRect:(CGRect)rect {
    SDWebImageCroppingTransformer *transformer = [SDWebImageCroppingTransformer new];
    transformer.rect = rect;
    
    return transformer;
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

@interface SDWebImageFlippingTransformer ()

@property (nonatomic, assign) BOOL horizontal;
@property (nonatomic, assign) BOOL vertical;

@end

@implementation SDWebImageFlippingTransformer

+ (instancetype)transformerWithHorizontal:(BOOL)horizontal vertical:(BOOL)vertical {
    SDWebImageFlippingTransformer *transformer = [SDWebImageFlippingTransformer new];
    transformer.horizontal = horizontal;
    transformer.vertical = vertical;
    
    return transformer;
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

@interface SDWebImageRotationTransformer ()

@property (nonatomic, assign) CGFloat angle;
@property (nonatomic, assign) BOOL fitSize;

@end

@implementation SDWebImageRotationTransformer

+ (instancetype)transformerWithAngle:(CGFloat)angle fitSize:(BOOL)fitSize {
    SDWebImageRotationTransformer *transformer = [SDWebImageRotationTransformer new];
    transformer.angle = angle;
    transformer.fitSize = fitSize;
    
    return transformer;
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

@interface SDWebImageTintTransformer ()

@property (nonatomic, strong, nonnull) UIColor *tintColor;

@end

@implementation SDWebImageTintTransformer

+ (instancetype)transformerWithColor:(UIColor *)tintColor {
    SDWebImageTintTransformer *transformer = [SDWebImageTintTransformer new];
    transformer.tintColor = tintColor;
    
    return transformer;
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

@interface SDWebImageBlurTransformer ()

@property (nonatomic, assign) CGFloat blurRadius;

@end

@implementation SDWebImageBlurTransformer

+ (instancetype)transformerWithRadius:(CGFloat)blurRadius {
    SDWebImageBlurTransformer *transformer = [SDWebImageBlurTransformer new];
    transformer.blurRadius = blurRadius;
    
    return transformer;
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
@interface SDWebImageFilterTransformer ()

@property (nonatomic, strong, nonnull) CIFilter *filter;

@end

@implementation SDWebImageFilterTransformer

+ (instancetype)transformerWithFilter:(CIFilter *)filter {
    SDWebImageFilterTransformer *transformer = [SDWebImageFilterTransformer new];
    transformer.filter = filter;
    
    return transformer;
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
