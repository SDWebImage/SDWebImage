/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDImageIOAnimatedCoder.h"

/**
 This coder is used for Google WebP and Animated WebP(AWebP) image format.
 Image/IO provide the WebP support in iOS 14/macOS 11/tvOS 14/watchOS 7+.
 @note If you need to support lower firmware version for WebP, you can have a try at https://github.com/SDWebImage/SDWebImageWebPCoder
 */
@interface SDImageAWebPCoder : SDImageIOAnimatedCoder <SDProgressiveImageCoder, SDAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) SDImageAWebPCoder *sharedCoder;

@end
