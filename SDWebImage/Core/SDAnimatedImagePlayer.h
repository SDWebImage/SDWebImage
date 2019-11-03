/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"
#import "SDImageCoder.h"

@interface SDAnimatedImagePlayer : NSObject

/// Current playing frame image. This value is KVO Compliance.
@property (nonatomic, readonly, nullable) UIImage *currentFrame;

/// Current frame index, zero based. This value is KVO Compliance.
@property (nonatomic, readonly) NSUInteger currentFrameIndex;

/// Current loop count since its latest animating. This value is KVO Compliance.
@property (nonatomic, readonly) NSUInteger currentLoopCount;

/// Total frame count for niamted image rendering. Defaults is animated image's frame count.
@property (nonatomic, assign) NSUInteger totalFrameCount;

/// Total loop count for animated image rendering. Default is animated image's loop count.
@property (nonatomic, assign) NSUInteger totalLoopCount;

/**
 Provide a max buffer size by bytes. This is used to adjust frame buffer count and can be useful when the decoding cost is expensive (such as Animated WebP software decoding). Default is 0.
 `0` means automatically adjust by calculating current memory usage.
 `1` means without any buffer cache, each of frames will be decoded and then be freed after rendering. (Lowest Memory and Highest CPU)
 `NSUIntegerMax` means cache all the buffer. (Lowest CPU and Highest Memory)
 */
@property (nonatomic, assign) NSUInteger maxBufferSize;

/**
 You can specify a runloop mode to let it rendering.
 Default is NSRunLoopCommonModes on multi-core iOS device, NSDefaultRunLoopMode on single-core iOS device
 */
@property (nonatomic, copy, nonnull) NSRunLoopMode runLoopMode;

- (nullable instancetype)initWithProvider:(nonnull id<SDAnimatedImageProvider>)provider;
+ (nullable instancetype)playerWithProvider:(nonnull id<SDAnimatedImageProvider>)provider;

@property (nonatomic, copy, nullable) void (^animationFrameHandler)(NSUInteger index, UIImage * _Nonnull frame);
@property (nonatomic, copy, nullable) void (^animationLoopHandler)(NSUInteger loopCount);

@property (readonly) BOOL isPlaying;
- (void)startPlaying;
- (void)pausePlaying;
- (void)stopPlaying;

- (void)seekToFrameAtIndex:(NSUInteger)index loopCount:(NSUInteger)loopCount;

- (void)clearFrameBuffer;

@end
