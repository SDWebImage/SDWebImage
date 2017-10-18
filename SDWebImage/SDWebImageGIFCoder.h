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
 Built in coder using ImageIO that supports GIF encoding/decoding
 @note `SDWebImageIOCoder` supports GIF but only as static (will use the 1st frame).
 @note Use `SDWebImageGIFCoder` for fully animated GIFs - less performant than `FLAnimatedImage`
 @note The recommended approach for animated GIFs is using `FLAnimatedImage`
 */
@interface SDWebImageGIFCoder : NSObject <SDWebImageCoder>

+ (nonnull instancetype)sharedCoder;

@end
