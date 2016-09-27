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

- (void)testImageOrientationFromImageDataWithInvalidData {
    // sync download image
    SEL selector = @selector(sd_imageOrientationFromImageData:);
    
    UIImageOrientation orientation = [[UIImage class] performSelector:selector withObject:nil];
    expect(orientation).to.equal(UIImageOrientationUp);
}

@end
