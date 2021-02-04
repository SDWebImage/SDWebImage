/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <SDWebImage/SDWebImageCompat.h>

#if SD_UIKIT || SD_MAC
#import <SDWebImage/SDImageCache.h>

#if SD_UIKIT
typedef UIViewAnimationOptions SDWebImageAnimationOptions;
#else
typedef NS_OPTIONS(NSUInteger, SDWebImageAnimationOptions) {
    SDWebImageAnimationOptionAllowsImplicitAnimation   = 1 << 0, // specify `allowsImplicitAnimation` for the `NSAnimationContext`
    
    SDWebImageAnimationOptionCurveEaseInOut            = 0 << 16, // default
    SDWebImageAnimationOptionCurveEaseIn               = 1 << 16,
    SDWebImageAnimationOptionCurveEaseOut              = 2 << 16,
    SDWebImageAnimationOptionCurveLinear               = 3 << 16,
    
    SDWebImageAnimationOptionTransitionNone            = 0 << 20, // default
    SDWebImageAnimationOptionTransitionFlipFromLeft    = 1 << 20,
    SDWebImageAnimationOptionTransitionFlipFromRight   = 2 << 20,
    SDWebImageAnimationOptionTransitionCurlUp          = 3 << 20,
    SDWebImageAnimationOptionTransitionCurlDown        = 4 << 20,
    SDWebImageAnimationOptionTransitionCrossDissolve   = 5 << 20,
    SDWebImageAnimationOptionTransitionFlipFromTop     = 6 << 20,
    SDWebImageAnimationOptionTransitionFlipFromBottom  = 7 << 20,
};
#endif

typedef void (^SDWebImageTransitionPreparesBlock)(__kindof UIView * _Nonnull view, UIImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL);
typedef void (^SDWebImageTransitionAnimationsBlock)(__kindof UIView * _Nonnull view, UIImage * _Nullable image);
typedef void (^SDWebImageTransitionCompletionBlock)(BOOL finished);

/**
 This class is used to provide a transition animation after the view category load image finished. Use this on `sd_imageTransition` in UIView+WebCache.h
 for UIKit(iOS & tvOS), we use `+[UIView transitionWithView:duration:options:animations:completion]` for transition animation.
 for AppKit(macOS), we use `+[NSAnimationContext runAnimationGroup:completionHandler:]` for transition animation. You can call `+[NSAnimationContext currentContext]` to grab the context during animations block.
 @note These transition are provided for basic usage. If you need complicated animation, consider to directly use Core Animation or use `SDWebImageAvoidAutoSetImage` and implement your own after image load finished.
 */
@interface SDWebImageTransition : NSObject

/**
 By default, we set the image to the view at the beginning of the animations. You can disable this and provide custom set image process
 */
@property (nonatomic, assign) BOOL avoidAutoSetImage;
/**
 The duration of the transition animation, measured in seconds. Defaults to 0.5.
 */
@property (nonatomic, assign) NSTimeInterval duration;
/**
 The timing function used for all animations within this transition animation (macOS).
 */
@property (nonatomic, strong, nullable) CAMediaTimingFunction *timingFunction API_UNAVAILABLE(ios, tvos, watchos) API_DEPRECATED("Use SDWebImageAnimationOptions instead, or grab NSAnimationContext.currentContext and modify the timingFunction", macos(10.10, 10.10));
/**
 A mask of options indicating how you want to perform the animations.
 */
@property (nonatomic, assign) SDWebImageAnimationOptions animationOptions;
/**
 A block object to be executed before the animation sequence starts.
 */
@property (nonatomic, copy, nullable) SDWebImageTransitionPreparesBlock prepares;
/**
 A block object that contains the changes you want to make to the specified view.
 */
@property (nonatomic, copy, nullable) SDWebImageTransitionAnimationsBlock animations;
/**
 A block object to be executed when the animation sequence ends.
 */
@property (nonatomic, copy, nullable) SDWebImageTransitionCompletionBlock completion;

@end

/**
 Convenience way to create transition. Remember to specify the duration if needed.
 for UIKit, these transition just use the correspond `animationOptions`. By default we enable `UIViewAnimationOptionAllowUserInteraction` to allow user interaction during transition.
 for AppKit, these transition use Core Animation in `animations`. So your view must be layer-backed. Set `wantsLayer = YES` before you apply it.
 */
@interface SDWebImageTransition (Conveniences)

/// Fade-in transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *fadeTransition;
/// Flip from left transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromLeftTransition;
/// Flip from right transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromRightTransition;
/// Flip from top transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromTopTransition;
/// Flip from bottom transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *flipFromBottomTransition;
/// Curl up transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *curlUpTransition;
/// Curl down transition.
@property (nonatomic, class, nonnull, readonly) SDWebImageTransition *curlDownTransition;

/// Fade-in transition with duration.
/// @param duration transition duration, use ease-in-out
+ (nonnull instancetype)fadeTransitionWithDuration:(NSTimeInterval)duration NS_SWIFT_NAME(fade(duration:));

/// Flip from left  transition with duration.
/// @param duration transition duration, use ease-in-out
+ (nonnull instancetype)flipFromLeftTransitionWithDuration:(NSTimeInterval)duration NS_SWIFT_NAME(flipFromLeft(duration:));

/// Flip from right transition with duration.
/// @param duration transition duration, use ease-in-out
+ (nonnull instancetype)flipFromRightTransitionWithDuration:(NSTimeInterval)duration NS_SWIFT_NAME(flipFromRight(duration:));

/// Flip from top transition with duration.
/// @param duration transition duration, use ease-in-out
+ (nonnull instancetype)flipFromTopTransitionWithDuration:(NSTimeInterval)duration NS_SWIFT_NAME(flipFromTop(duration:));

/// Flip from bottom transition with duration.
/// @param duration transition duration, use ease-in-out
+ (nonnull instancetype)flipFromBottomTransitionWithDuration:(NSTimeInterval)duration NS_SWIFT_NAME(flipFromBottom(duration:));

///  Curl up transition with duration.
/// @param duration transition duration, use ease-in-out
+ (nonnull instancetype)curlUpTransitionWithDuration:(NSTimeInterval)duration NS_SWIFT_NAME(curlUp(duration:));

/// Curl down transition with duration.
/// @param duration transition duration, use ease-in-out
+ (nonnull instancetype)curlDownTransitionWithDuration:(NSTimeInterval)duration NS_SWIFT_NAME(curlDown(duration:));

@end

#endif
