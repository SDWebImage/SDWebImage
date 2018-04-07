/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "NSData+ImageContentType.h"

typedef NSString * SDWebImageCoderOption NS_STRING_ENUM;
typedef NSDictionary<SDWebImageCoderOption, id> SDWebImageCoderOptions;

/**
 A Boolean value indicating whether to decode the first frame only for animated image during decoding. (NSNumber)
 */
FOUNDATION_EXPORT SDWebImageCoderOption _Nonnull const SDWebImageCoderDecodeFirstFrameOnly;
/**
 A CGFloat value which is greater than or equal to 1.0. This value specify the image scale factor for decoding. If not provide, use 1.0. (NSNumber)
 */
FOUNDATION_EXPORT SDWebImageCoderOption _Nonnull const SDWebImageCoderDecodeScaleFactor;
/**
 A double value between 0.0-1.0 indicating the encode compression quality to produce the image data. If not provide, use 1.0. (NSNumber)
 */
FOUNDATION_EXPORT SDWebImageCoderOption _Nonnull const SDWebImageCoderEncodeCompressionQuality;

/**
 This is the image coder protocol to provide custom image decoding/encoding.
 These methods are all required to implement.
 You do not need to specify image scale during decoding because we may scale image later.
 @note Pay attention that these methods are not called from main queue.
 */
@protocol SDWebImageCoder <NSObject>

@required
#pragma mark - Decoding
/**
 Returns YES if this coder can decode some data. Otherwise, the data should be passed to another coder.
 
 @param data The image data so we can look at it
 @return YES if this coder can decode the data, NO otherwise
 */
- (BOOL)canDecodeFromData:(nullable NSData *)data;

/**
 Decode the image data to image.

 @param data The image data to be decoded
 @param options A dictionary containing any decoding options. Pass @{SDWebImageCoderDecodeFirstFrameOnly: @(YES)} to decode the first frame only.
 @return The decoded image from data
 */
- (nullable UIImage *)decodedImageWithData:(nullable NSData *)data
                                   options:(nullable SDWebImageCoderOptions *)options;

#pragma mark - Encoding

/**
 Returns YES if this coder can encode some image. Otherwise, it should be passed to another coder.
 
 @param format The image format
 @return YES if this coder can encode the image, NO otherwise
 */
- (BOOL)canEncodeToFormat:(SDImageFormat)format;

/**
 Encode the image to image data.

 @param image The image to be encoded
 @param format The image format to encode, you should note `SDImageFormatUndefined` format is also  possible
 @param options A dictionary containing any encoding options. Pass @{SDWebImageCoderEncodeCompressionQuality: @(1)} to specify compression quality.
 @return The encoded image data
 */
- (nullable NSData *)encodedDataWithImage:(nullable UIImage *)image
                                   format:(SDImageFormat)format
                                  options:(nullable SDWebImageCoderOptions *)options;

@end


/**
 This is the image coder protocol to provide custom progressive image decoding.
 These methods are all required to implement.
 @note Pay attention that these methods are not called from main queue.
 */
@protocol SDWebImageProgressiveCoder <SDWebImageCoder>

@required
/**
 Returns YES if this coder can incremental decode some data. Otherwise, it should be passed to another coder.
 
 @param data The image data so we can look at it
 @return YES if this coder can decode the data, NO otherwise
 */
- (BOOL)canIncrementalDecodeFromData:(nullable NSData *)data;

/**
 Because incremental decoding need to keep the decoded context, we will alloc a new instance with the same class for each download operation to avoid conflicts
 This init method should not return nil

 @return A new instance to do incremental decoding for the specify image format
 */
- (nonnull instancetype)initIncremental;

/**
 Update the incremental decoding when new image data available

 @param data The image data has been downloaded so far
 @param finished Whether the download has finished
 */
- (void)updateIncrementalData:(nullable NSData *)data finished:(BOOL)finished;

/**
 Incremental decode the current image data to image.

 @param options A dictionary containing any decoding options.
 @return The decoded image from current data
 */
- (nullable UIImage *)incrementalDecodedImageWithOptions:(nullable SDWebImageCoderOptions *)options;

@end

/**
 This is the animated image protocol to provide the basic function for animated image rendering. It's adopted by `SDAnimatedImage` and `SDWebImageAnimatedCoder`
 */
@protocol SDAnimatedImageProvider <NSObject>

@required
/**
 The original animated image data for current image. If current image is not an animated format, return nil.
 We may use this method to grab back the original image data if need, such as NSCoding or compare.
 
 @return The animated image data
 */
- (nullable NSData *)animatedImageData;

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

@end

/**
 This is the animated image coder protocol for custom animated image class like  `SDAnimatedImage`. Through it inherit from `SDWebImageCoder`. We currentlly only use the method `canDecodeFromData:` to detect the proper coder for specify animated image format.
 */
@protocol SDWebImageAnimatedCoder <SDWebImageCoder, SDAnimatedImageProvider>

@required
/**
 Because animated image coder should keep the original data, we will alloc a new instance with the same class for the specify animated image data
 The init method should return nil if it can't decode the specify animated image data to produce any frame.
 After the instance created, we may call methods in `SDAnimatedImage` to produce animated image frame.

 @param data The animated image data to be decode
 @return A new instance to do animated decoding for specify image data
 */
- (nullable instancetype)initWithAnimatedImageData:(nullable NSData *)data;

@end
