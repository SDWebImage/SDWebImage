/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDWebImageFrame.h"

@interface SDWebImageCoderHelper : NSObject

/**
 Return the shared device-dependent RGB color space created with CGColorSpaceCreateDeviceRGB.
 
 @return The device-dependent RGB color space
 */
+ (CGColorSpaceRef _Nonnull)currentDeviceRGB;

/**
 Check whether CGImageRef contains alpha channel.
 
 @param imageRef The CGImageRef
 @return Return YES if CGImageRef contains alpha channel, otherwise return NO
 */
+ (BOOL)containsAlphaForImageRef:(CGImageRef _Nullable)imageRef;

/**
 Return an animated image with frames array.
 For UIKit, this will apply the patch and then create animated UIImage. The patch is because that `+[UIImage animatedImageWithImages:duration:]` just use the averate of duration for each image. So it will not work if different frame has different duration. Therefore we repeat the specify frame for specify times to let it work.
 For AppKit, NSImage does not support animates other than GIF. This will try to encode the frames to GIF format and then create an animated NSImage for rendering.

 @param frames The frames array. If no frames or frames is empty, return nil
 @param properties Image Properties. It contains information like loop count, see `SDWebImageFrameLoopCountKey`
 @return A animated image for rendering on UIImageView(UIKit) or NSImageView(AppKit)
 */
+ (UIImage * _Nullable)animatedImageWithFrames:(NSArray<SDWebImageFrame *> * _Nullable)frames properties:(NSDictionary * _Nullable)properties;

/**
 Return frames array from an animated image.
 For UIKit, this will unapply the patch for the description above and then create frames array. This will also work for normal animated UIImage.
 For AppKit, NSImage does not support animates other than GIF. This will try to decode the GIF imageRep and then create frames array.

 @param animatedImage A animated image. If it's not animated, return nil
 @return The frames array
 */
+ (NSArray<SDWebImageFrame *> * _Nullable)framesFromAnimatedImage:(UIImage * _Nonnull)animatedImage;

#if SD_UIKIT || SD_WATCH
/**
 Convert an EXIF image orientation to an iOS one.

 @param exifOrientation EXIF orientation
 @return iOS orientation
 */
+ (UIImageOrientation)imageOrientationFromEXIFOrientation:(NSInteger)exifOrientation;
/**
 Convert an iOS orientation to an EXIF image orientation.

 @param imageOrientation iOS orientation
 @return EXIF orientation
 */
+ (NSInteger)exifOrientationFromImageOrientation:(UIImageOrientation)imageOrientation;
#endif

@end
