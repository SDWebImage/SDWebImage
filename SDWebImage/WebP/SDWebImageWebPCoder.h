/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifdef SD_WEBP

#import <Foundation/Foundation.h>
#import "SDImageCoder.h"

/**
 Built in coder that supports WebP and animated WebP
 */
@interface SDWebImageWebPCoder : NSObject <SDProgressiveImageCoder, SDAnimatedImageCoder>

@property (nonatomic, class, readonly, nonnull) SDWebImageWebPCoder *sharedCoder;

@end

#endif
