/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDImageCoder.h"

FOUNDATION_EXPORT SDImageCoderOption _Nonnull const SDImageCoderWebImageAnimatedFormat;
FOUNDATION_EXPORT SDImageCoderOption _Nonnull const SDImageCoderWebImageAnimatedDefaultLoopCount;
FOUNDATION_EXTERN SDImageCoderOption _Nonnull const SDImageCoderWebImageAnimatedPropertyDictionary;
FOUNDATION_EXTERN SDImageCoderOption _Nonnull const SDImageCoderWebImageAnimatedPropertyLoopCount;
FOUNDATION_EXTERN SDImageCoderOption _Nonnull const SDImageCoderWebAnimatedPropertyUnclampedDelayTime;
FOUNDATION_EXTERN SDImageCoderOption _Nonnull const SDImageCoderWebAnimatedPropertyDelayTime;

@interface SDImageAnimatedCoder : NSObject <SDProgressiveImageCoder, SDAnimatedImageCoder>

- (nonnull instancetype)initWithOptions:(nullable SDImageCoderOptions *)options;

@end
