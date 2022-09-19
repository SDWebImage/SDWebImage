/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <Foundation/Foundation.h>
#import "SDImageIOAnimatedCoder.h"

// AVFileTypeHEIC/AVFileTypeHEIF is defined in AVFoundation via iOS 11, we use this without import AVFoundation
#define kSDUTTypeHEIC  ((__bridge CFStringRef)@"public.heic")
#define kSDUTTypeHEIF  ((__bridge CFStringRef)@"public.heif")
// HEIC Sequence (Animated Image)
#define kSDUTTypeHEICS ((__bridge CFStringRef)@"public.heics")
// kSDUTTypeWebP seems not defined in public UTI framework, Apple use the hardcode string, we define them :)
#define kSDUTTypeWebP  ((__bridge CFStringRef)@"org.webmproject.webp")

#define kSDUTTypeImage ((__bridge CFStringRef)@"public.image")
#define kSDUTTypeJPEG  ((__bridge CFStringRef)@"public.jpeg")
#define kSDUTTypePNG   ((__bridge CFStringRef)@"public.png")
#define kSDUTTypeTIFF  ((__bridge CFStringRef)@"public.tiff")
#define kSDUTTypeSVG   ((__bridge CFStringRef)@"public.svg-image")
#define kSDUTTypeGIF   ((__bridge CFStringRef)@"com.compuserve.gif")
#define kSDUTTypePDF   ((__bridge CFStringRef)@"com.adobe.pdf")

@interface SDImageIOAnimatedCoder ()

+ (NSTimeInterval)frameDurationAtIndex:(NSUInteger)index source:(nonnull CGImageSourceRef)source;
+ (NSUInteger)imageLoopCountWithSource:(nonnull CGImageSourceRef)source;
+ (nullable UIImage *)createFrameAtIndex:(NSUInteger)index source:(nonnull CGImageSourceRef)source scale:(CGFloat)scale preserveAspectRatio:(BOOL)preserveAspectRatio thumbnailSize:(CGSize)thumbnailSize forceDecode:(BOOL)forceDecode options:(nullable NSDictionary *)options;
+ (BOOL)canEncodeToFormat:(SDImageFormat)format;
+ (BOOL)canDecodeFromFormat:(SDImageFormat)format;

@end
