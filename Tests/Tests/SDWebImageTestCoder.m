/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTestCoder.h"

@implementation SDWebImageTestCoder

- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return YES;
}

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return YES;
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    return image;
}

- (instancetype)initIncrementalWithOptions:(nullable SDImageCoderOptions *)options
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)updateIncrementalData:(NSData *)data finished:(BOOL)finished {
    return;
}

- (UIImage *)incrementalDecodedImageWithOptions:(SDImageCoderOptions *)options {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [[UIImage alloc] initWithContentsOfFile:testImagePath];
    return image;
}

- (BOOL)canIncrementalDecodeFromData:(NSData *)data {
    return YES;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(nullable SDImageCoderOptions *)options {
    NSString *testString = @"TestEncode";
    NSData *data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

@end
