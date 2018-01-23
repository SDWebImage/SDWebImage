/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import "NSData+ImageContentType.h"

@protocol SDAnimatedImage <NSObject>

@required
/**
 Total animated frame count.
 It the frame count is less than 1, then the methods below will be ignored.

 @return Total animated frame count.
 */
- (NSUInteger)animatedImageFrameCount;
/**
 Animation loop count, 0 means infinite looping.

 @return Animation loop count
 */
- (NSUInteger)animatedImageLoopCount;
/**
 Returns the frame image from a specified index.
 @note The index maybe randomly if one image was set to different imageViews, keep it re-entrant. (It's not recommend to store the images into array because it's memory consuming)

 @param index Frame index (zero based).
 @return Frame's image
 */
- (nullable UIImage *)animatedImageFrameAtIndex:(NSUInteger)index;
/**
 Returns the frames's duration from a specified index.
 @note The index maybe randomly if one image was set to different imageViews, keep it re-entrant. (It's recommend to store the durations into array because it's not memory-consuming)

 @param index Frame index (zero based).
 @return Frame's duration
 */
- (NSTimeInterval)animatedImageDurationAtIndex:(NSUInteger)index;

@optional
/**
 Preload all frame image to memory. Then directly return the frame for index without decoding.
 This method may be called on background thread.
 
 @note If the image is shared by lots of imageViews, preload all frames will reduce the CPU cost because the decoder may not need to keep re-entrant for randomly index access.
 */
- (void)preloadAllFrames;

@end

@interface SDAnimatedImage : UIImage <SDAnimatedImage>

// This class override these methods from UIImage(NSImage), and it supports NSSecureCoding.
// You should use these methods to create a new animated image. Use other methods will just call super instead.
+ (nullable instancetype)imageWithContentsOfFile:(nonnull NSString *)path;
+ (nullable instancetype)imageWithData:(nonnull NSData *)data;
+ (nullable instancetype)imageWithData:(nonnull NSData *)data scale:(CGFloat)scale;
- (nullable instancetype)initWithContentsOfFile:(nonnull NSString *)path;
- (nullable instancetype)initWithData:(nonnull NSData *)data;
- (nullable instancetype)initWithData:(nonnull NSData *)data scale:(CGFloat)scale;

/**
 Current animated image format
 */
@property (nonatomic, assign, readonly) SDImageFormat animatedImageFormat;
/**
 Current animated image data, you can use this instead of CGImage to create another instance
 */
@property (nonatomic, copy, readonly, nullable) NSData *animatedImageData;

/**
 Preload all frame image to memory. Then directly return the frame for index without decoding.
 The preloaded animated image frames will be removed when receiving memory warning.
 
 @note If the image is shared by lots of imageViews, preload all frames will reduce the CPU cost because the decoder may not need to keep re-entrant for randomly index access.
 @note Once preload the frames into memory, there is no huge differenec on performance between UIImage's `animatedImageWithImages:duration:` for UIKit. But UIImage's animation have some issue such like blanking or frame resetting. It's recommend to use only if need.
 */
- (void)preloadAllFrames;

@end
