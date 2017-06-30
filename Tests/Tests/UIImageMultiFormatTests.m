/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>

#import <SDWebImage/UIImage+MultiFormat.h>


@interface UIImageMultiFormatTests : XCTestCase

@end


@implementation UIImageMultiFormatTests

- (void)test01ImageOrientationFromImageDataWithInvalidData {
    // sync download image
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(sd_imageOrientationFromImageData:);
#pragma clang diagnostic pop
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    UIImageOrientation orientation = (UIImageOrientation)[[UIImage class] performSelector:selector withObject:nil];
#pragma clang diagnostic pop
    expect(orientation).to.equal(UIImageOrientationUp);
}

- (void)test02AnimatedWebPImageArrayWithEqualSizeAndScale {
    NSURL *webpURL = [NSURL URLWithString:@"https://isparta.github.io/compare-webp/image/gif_webp/webp/2.webp"];
    NSData *data = [NSData dataWithContentsOfURL:webpURL];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    SEL selector = @selector(sd_imageWithWebPData:);
#pragma clang diagnostic pop
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    UIImage *animatedImage = [[UIImage class] performSelector:selector withObject:data];
#pragma clang diagnostic pop
    CGSize imageSize = animatedImage.size;
    CGFloat imageScale = animatedImage.scale;
    [animatedImage.images enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
        CGSize size = image.size;
        CGFloat scale = image.scale;
        expect(imageSize.width).to.equal(size.width);
        expect(imageSize.height).to.equal(size.height);
        expect(imageScale).to.equal(scale);
    }];
}

@end
