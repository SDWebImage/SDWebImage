/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"
#import <CoreImage/CoreImage.h>

// Internal header
@interface UIColor (HexString)

@property (nonatomic, copy, readonly, nonnull) NSString *sd_hexString;

@end

@interface SDImageTransformerTests : SDTestCase

@property (nonatomic, strong) UIImage *testImage;

@end

@implementation SDImageTransformerTests

#pragma mark - UIImage+Transform

// UIImage+Transform test is hard to write because it's more about visual effect. Current it's tied to the `TestImage.png`, please keep that image or write new test with new image
- (void)test01UIImageTransformResize {
    CGSize scaleDownSize = CGSizeMake(200, 100);
    UIImage *scaledDownImage = [self.testImage sd_resizedImageWithSize:scaleDownSize scaleMode:SDImageScaleModeFill];
    expect(CGSizeEqualToSize(scaledDownImage.size, scaleDownSize)).beTruthy();
    CGSize scaleUpSize = CGSizeMake(2000, 1000);
    UIImage *scaledUpImage = [self.testImage sd_resizedImageWithSize:scaleUpSize scaleMode:SDImageScaleModeAspectFit];
    expect(CGSizeEqualToSize(scaledUpImage.size, scaleUpSize)).beTruthy();
    // Check image not inversion
    UIColor *topCenterColor = [scaledUpImage sd_colorAtPoint:CGPointMake(1000, 50)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test02UIImageTransformCrop {
    CGRect rect = CGRectMake(50, 10, 200, 200);
    UIImage *croppedImage = [self.testImage sd_croppedImageWithRect:rect];
    expect(CGSizeEqualToSize(croppedImage.size, CGSizeMake(200, 200))).beTruthy();
    UIColor *startColor = [croppedImage sd_colorAtPoint:CGPointZero];
    expect([startColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]).beTruthy();
    // Check image not inversion
    UIColor *topCenterColor = [croppedImage sd_colorAtPoint:CGPointMake(100, 10)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test03UIImageTransformRoundedCorner {
    CGFloat radius = 50;
#if SD_UIKIT
    SDRectCorner corners = UIRectCornerAllCorners;
#else
    SDRectCorner corners = SDRectCornerAllCorners;
#endif
    CGFloat borderWidth = 1;
    UIColor *borderColor = [UIColor blackColor];
    UIImage *roundedCornerImage = [self.testImage sd_roundedCornerImageWithRadius:radius corners:corners borderWidth:borderWidth borderColor:borderColor];
    expect(CGSizeEqualToSize(roundedCornerImage.size, CGSizeMake(300, 300))).beTruthy();
    UIColor *startColor = [roundedCornerImage sd_colorAtPoint:CGPointZero];
    expect([startColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]).beTruthy();
    // Check the left center pixel, should be border :)
    UIColor *checkBorderColor = [roundedCornerImage sd_colorAtPoint:CGPointMake(1, 150)];
    expect([checkBorderColor.sd_hexString isEqualToString:borderColor.sd_hexString]).beTruthy();
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [roundedCornerImage sd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test04UIImageTransformRotate {
    CGFloat angle = M_PI_4;
    UIImage *rotatedImage = [self.testImage sd_rotatedImageWithAngle:angle fitSize:NO];
    // Not fit size and no change
    expect(CGSizeEqualToSize(rotatedImage.size, self.testImage.size)).beTruthy();
    // Fit size, may change size
    rotatedImage = [self.testImage sd_rotatedImageWithAngle:angle fitSize:YES];
    CGSize rotatedSize = CGSizeMake(floor(300 * 1.414), floor(300 * 1.414)); // 45º, square length * sqrt(2)
    expect(CGSizeEqualToSize(rotatedImage.size, rotatedSize)).beTruthy();
    // Check image not inversion
    UIColor *leftCenterColor = [rotatedImage sd_colorAtPoint:CGPointMake(60, 175)];
    expect([leftCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test05UIImageTransformFlip {
    BOOL horizontal = YES;
    BOOL vertical = YES;
    UIImage *flippedImage = [self.testImage sd_flippedImageWithHorizontal:horizontal vertical:vertical];
    expect(CGSizeEqualToSize(flippedImage.size, self.testImage.size)).beTruthy();
    // Test pixel colors method here
    UIColor *checkColor = [flippedImage sd_colorAtPoint:CGPointMake(75, 75)];
    expect(checkColor);
    NSArray<UIColor *> *checkColors = [flippedImage sd_colorsWithRect:CGRectMake(75, 75, 10, 10)]; // Rect are all same color
    expect(checkColors.count).to.equal(10 * 10);
    for (UIColor *color in checkColors) {
        expect([color isEqual:checkColor]).to.beTruthy();
    }
    // Check image not inversion
    UIColor *bottomCenterColor = [flippedImage sd_colorAtPoint:CGPointMake(150, 285)];
    expect([bottomCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test06UIImageTransformTint {
    UIColor *tintColor = [UIColor blackColor];
    UIImage *tintedImage = [self.testImage sd_tintedImageWithColor:tintColor];
    expect(CGSizeEqualToSize(tintedImage.size, self.testImage.size)).beTruthy();
    // Check center color, should keep clear
    UIColor *centerColor = [tintedImage sd_colorAtPoint:CGPointMake(150, 150)];
    expect([centerColor.sd_hexString isEqualToString:[UIColor clearColor].sd_hexString]);
    // Check left color, should be tinted
    UIColor *leftColor = [tintedImage sd_colorAtPoint:CGPointMake(80, 150)];
    expect([leftColor.sd_hexString isEqualToString:tintColor.sd_hexString]);
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [tintedImage sd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor blackColor].sd_hexString]).beTruthy();
}

- (void)test07UIImageTransformBlur {
    CGFloat radius = 50;
    UIImage *blurredImage = [self.testImage sd_blurredImageWithRadius:radius];
    expect(CGSizeEqualToSize(blurredImage.size, self.testImage.size)).beTruthy();
    // Check left color, should be blurred
    UIColor *leftColor = [blurredImage sd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output
    UIColor *expectedColor = [UIColor colorWithRed:0.431373 green:0.101961 blue:0.0901961 alpha:0.729412];
    expect([leftColor.sd_hexString isEqualToString:expectedColor.sd_hexString]);
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [blurredImage sd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.sd_hexString isEqualToString:@"#9a430d06"]).beTruthy();
}

- (void)test08UIImageTransformFilter {
    // Invert color filter
    CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
    UIImage *filteredImage = [self.testImage sd_filteredImageWithFilter:filter];
    expect(CGSizeEqualToSize(filteredImage.size, self.testImage.size)).beTruthy();
    // Check left color, should be inverted
    UIColor *leftColor = [filteredImage sd_colorAtPoint:CGPointMake(80, 150)];
    // Hard-code from the output
    UIColor *expectedColor = [UIColor colorWithRed:0.85098 green:0.992157 blue:0.992157 alpha:1];
    expect([leftColor.sd_hexString isEqualToString:expectedColor.sd_hexString]);
    // Check rounded corner operation not inversion the image
    UIColor *topCenterColor = [filteredImage sd_colorAtPoint:CGPointMake(150, 20)];
    expect([topCenterColor.sd_hexString isEqualToString:[UIColor whiteColor].sd_hexString]).beTruthy();
}

#pragma mark - SDImageTransformer

- (void)test09ImagePipelineTransformer {
    CGSize size = CGSizeMake(100, 100);
    SDImageScaleMode scaleMode = SDImageScaleModeAspectFill;
    CGFloat angle = M_PI_4;
    BOOL fitSize = NO;
    CGFloat radius = 50;
#if SD_UIKIT
    SDRectCorner corners = UIRectCornerAllCorners;
#else
    SDRectCorner corners = SDRectCornerAllCorners;
#endif
    CGFloat borderWidth = 1;
    UIColor *borderCoder = [UIColor blackColor];
    SDImageResizingTransformer *transformer1 = [SDImageResizingTransformer transformerWithSize:size scaleMode:scaleMode];
    SDImageRotationTransformer *transformer2 = [SDImageRotationTransformer transformerWithAngle:angle fitSize:fitSize];
    SDImageRoundCornerTransformer *transformer3 = [SDImageRoundCornerTransformer transformerWithRadius:radius corners:corners borderWidth:borderWidth borderColor:borderCoder];
    SDImagePipelineTransformer *pipelineTransformer = [SDImagePipelineTransformer transformerWithTransformers:@[transformer1, transformer2, transformer3]];
    
    UIImage *transformedImage = [pipelineTransformer transformedImageWithImage:self.testImage forKey:@"Test"];
    expect(CGSizeEqualToSize(transformedImage.size, size)).beTruthy();
}

- (void)test10TransformerKeyForCacheKey {
    NSString *transformerKey = @"SDImageFlippingTransformer(1,0)";
    
    // File path representation test cases
    NSString *key = @"image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"image-SDImageFlippingTransformer(1,0).png");
    
    key = @"image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"image-SDImageFlippingTransformer(1,0)");
    
    key = @".image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@".image-SDImageFlippingTransformer(1,0)");
    
    key = @"image.";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"image.-SDImageFlippingTransformer(1,0)");
    
    key = @"Test/image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"Test/image-SDImageFlippingTransformer(1,0).png");
    
    // URL representation test cases
    key = @"http://foo/image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-SDImageFlippingTransformer(1,0).png");
    
    key = @"http://foo/image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-SDImageFlippingTransformer(1,0)");
    
    key = @"http://foo/.image";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/.image-SDImageFlippingTransformer(1,0)");
    
    key = @"http://foo/image.png?foo=bar#mark";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"http://foo/image-SDImageFlippingTransformer(1,0).png?foo=bar#mark");
    
    key = @"ftp://root:password@foo.com/image.png";
    expect(SDTransformedKeyForKey(key, transformerKey)).equal(@"ftp://root:password@foo.com/image-SDImageFlippingTransformer(1,0).png");
}

#pragma mark - Helper

- (UIImage *)testImage {
    if (!_testImage) {
        _testImage = [[UIImage alloc] initWithContentsOfFile:[self testPNGPath]];
    }
    return _testImage;
}

- (NSString *)testPNGPath {
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    return [testBundle pathForResource:@"TestImage" ofType:@"png"];
}

@end
