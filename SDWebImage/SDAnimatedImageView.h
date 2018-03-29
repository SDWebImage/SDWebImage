/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

#if SD_UIKIT || SD_MAC

#import "SDAnimatedImage.h"

/**
 A drop-in replacement for UIImageView/NSImageView, you can use this for animated image rendering.
 Call `setImage:` with `UIImage(NSImage)` which conform to `SDAnimatedImage` protocol will start animated image rendering. Call with normal UIImage(NSImage) will back to normal UIImageView(NSImageView) rendering
 For UIKit: use `-startAnimating`, `-stopAnimating` to control animating
 For AppKit: use `-setAnimates:` to control animating. This view is layer-backed.
 */
@interface SDAnimatedImageView : UIImageView

/**
 Current display frame image
 */
@property (nonatomic, strong, readonly, nullable) UIImage *currentFrame;
/**
 Current frame index, zero based
 */
@property (nonatomic, assign, readonly) NSUInteger currentFrameIndex;
/**
 Current loop count since its latest animating
 */
@property (nonatomic, assign, readonly) NSUInteger currentLoopCount;
/**
 YES to choose `animationRepeatCount` property instead of image's loop count for animation loop count. Default is NO.
 */
@property (nonatomic, assign) BOOL shouldCustomLoopCount;
/**
 Total loop count for animated image rendering. Default is animated image's loop count.
 If you need to set custom loop count, set `shouldCustomLoopCount` to YES and change this value.
 This class override UIImageView's `animationRepeatCount` property on iOS, use this property as well.
 */
@property (nonatomic, assign) NSInteger animationRepeatCount;
/**
 Returns a Boolean value indicating whether the animation is running.
 This class override UIImageView's `animating` property on iOS, use this property as well.
 */
@property (nonatomic, readonly, getter=isAnimating) BOOL animating;
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
 This value has no use on macOS
 */
@property (nonatomic, copy, nonnull) NSString *runLoopMode;

@end

#endif
