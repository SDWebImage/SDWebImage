//
//  SDAnimatedImageBufferPool.h
//  SDWebImage
//
//  Created by 李卓立 on 2021/5/23.
//  Copyright © 2021 Dailymotion. All rights reserved.
//

#import "SDWebImageCompat.h"
#import "SDImageCoder.h"

/// Buffer Pool is used to track all animated image frame buffer. A buffer can be shared only when `(image data, decoding options, index)` are all equal.
/// @note: The current tracking use weak reference to avoid effect buffer's lifecycle.
@interface SDAnimatedImageBufferPool : NSObject

/// Query buffer from buffer pool.
/// @param provider The buffer provider
/// @param index The frame index
+ (nullable UIImage *)bufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index;

/// Store buffer into buffer pool.
/// @param buffer The frame buffer
/// @param provider The buffer provider
/// @param index The frame index
+ (void)setBuffer:(nullable UIImage *)buffer forProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index;

/// Remove the buffer from buffer pool.
/// @param provider The buffer provider
/// @param index The frame index
+ (void)removeBufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider index:(NSUInteger)index;

/// Clear buffer from buffer pool.
/// @param provider The buffer provider
+ (void)clearBufferForProvider:(nonnull id<SDAnimatedImageProvider>)provider;

@end
