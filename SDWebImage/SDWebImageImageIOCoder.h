/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCoder.h"

/**
 Built in coder that supports PNG, JPEG, TIFF, includes support for progressive decoding.
 
 GIF
 Also supports static GIF (meaning will only handle the 1st frame).
 For a full GIF support, we recommend `FLAnimatedImage` or our less performant `SDWebImageGIFCoder`
 
 HEIC
 This coder also supports HEIC format because ImageIO supports it natively. But it depends on the system capabilities, so it won't work on all devices.
 Hardware works if:  (iOS 11 || macOS 10.13) && (isMac || isIPhoneAndA10FusionChipAbove) && (!Simulator)
 */
@interface SDWebImageImageIOCoder : NSObject <SDWebImageProgressiveCoder>

+ (nonnull instancetype)sharedCoder;

@end
