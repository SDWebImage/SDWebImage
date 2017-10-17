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
 Built in coder that supports GIF
 */
@interface SDWebImageGIFCoder : NSObject <SDWebImageCoder>

+ (nonnull instancetype)sharedCoder;

@end
