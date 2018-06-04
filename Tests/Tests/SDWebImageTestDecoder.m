/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTestDecoder.h"

@implementation SDWebImageTestDecoder

- (BOOL)canDecodeFromData:(nullable NSData *)data {
    return YES;
}

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    return YES;
}

- (UIImage *)decodedImageWithData:(NSData *)data {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    return image;
}

- (UIImage *)incrementallyDecodedImageWithData:(NSData *)data finished:(BOOL)finished {
    NSString * testImagePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"TestImage" ofType:@"gif"];
    UIImage *image = [UIImage imageWithContentsOfFile:testImagePath];
    return image;
}

- (UIImage *)decompressedImageWithImage:(UIImage *)image
                                   data:(NSData *__autoreleasing  _Nullable *)data
                                options:(nullable NSDictionary<NSString*, NSObject*>*)optionsDict {
    NSString *testString = @"TestDecompress";
    NSData *testData = [testString dataUsingEncoding:NSUTF8StringEncoding];
    *data = testData;
    
    return image;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format {
    NSString *testString = @"TestEncode";
    NSData *data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

@end
