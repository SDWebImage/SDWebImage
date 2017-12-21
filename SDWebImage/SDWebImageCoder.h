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
#import "SDAnimatedImage.h"

typedef NSString * SDWebImageCoderOption NS_STRING_ENUM;
typedef NSDictionary<SDWebImageCoderOption, id> SDWebImageCoderOptions;

/**
 A Boolean value indicating whether to decode the first frame only for animated image during decoding. (NSNumber)
 */
FOUNDATION_EXPORT SDWebImageCoderOption _Nonnull const SDWebImageCoderDecodeFirstFrameOnly;
/**
 A double value between 0.0-1.0 indicating the encode quality to produce the image data. If not provide, use 1.0. (NSNumber)
 */
FOUNDATION_EXPORT SDWebImageCoderOption _Nonnull const SDWebImageCoderEncodeQuality;

/**
 This is the image coder protocol to provide custom image decoding/encoding.
 These methods are all required to implement.
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
 @param optionsDict A dictionary containing any decoding options. Pass {SDWebImageCoderDecodeFirstFrameOnlyKey: @(YES)} to decode the first frame only.
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
- (BOOL)canIncrementallyDecodeFromData:(nullable NSData *)data;

/**
 Because incremental decoding need to keep the decoded context, we will alloc a new instance with the same class for each download operation to avoid conflicts
 This init method should not return nil

 @return A new instance to do incremental decoding for the specify image format
 */
- (nonnull instancetype)initIncrementally;

/**
 Incremental decode the image data to image.
 
 @param data The image data has been downloaded so far
 @param finished Whether the download has finished
 @return The decoded image from data
 */
- (nullable UIImage *)incrementallyDecodedImageWithData:(nullable NSData *)data finished:(BOOL)finished;

@end

@protocol SDWebImageAnimatedCoder <SDWebImageCoder, SDAnimatedImage>

@required
/**
 Because animated image coder should keep the original data, we will alloc a new instance with the same class for the specify animated image data
 The init method should return nil if it can't decode the specify animated image data

 @param data The animated image data to be decode
 @return A new instance to do animated decoding for specify image data
 */
- (nullable instancetype)initWithAnimatedImageData:(nullable NSData *)data;

/**
 Return the current animated image data. This is used for image instance archive or image information retrieval
 You can return back the desired data(may be not the same instance provide for init method, but have the equal data)

 @return The animated image data
 */
- (nullable NSData *)animatedImageData;

@end
