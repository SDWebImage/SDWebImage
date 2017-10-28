/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

/**
 A NSUInteger value represent the loop count of an animated image. 0 means infinite looping (NSNumber)
 */
FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageFrameLoopCountKey;

@interface SDWebImageFrame : NSObject

/**
 The image of current frame. You should not set an animated image.
 */
@property (nonatomic, strong, readonly, nonnull) UIImage *image;
/**
 The duration of current frame to be displayed. The number is milliseconds but not seconds to avoid losing precision. You should not set this to zero.
 */
@property (nonatomic, readonly, assign) NSUInteger duration;
/**
 The property of current frame. You can provide extra information here for current frame decoding/encoding such as scale, rotation, tag, etc.
 */
@property (nonatomic, assign, readonly, nullable) NSDictionary *property;

/**
 Create a frame instance with specify image, duration and optional property

 @param image current frame's image
 @param duration current frame's duration
 @param property current frame's property
 @return frame instance
 */
+ (instancetype _Nonnull)frameWithImage:(UIImage * _Nonnull)image duration:(NSUInteger)duration property:(NSDictionary * _Nullable)property;

@end
