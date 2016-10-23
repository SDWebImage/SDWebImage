/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Laurin Brandner
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"
#import <ImageIO/ImageIO.h>

@interface UIImage (GIF)

/**
 *  Compatibility method - creates an static UIImage from an NSData, it will only contain the 1st frame image
 */
+ (UIImage *)sd_staticGIFImageWithData:(NSData *)data;

/**
 *  Compatibility method - creates an static UIImage from a CGImageSourceRef, it will only contain the 1st frame image
 */
+ (UIImage *)sd_staticGIFImageWithCGImageSource:(CGImageSourceRef)imageSource;

/**
 *  Checks if an UIImage instance is a GIF. Will use the `images` array
 */
- (BOOL)isGIF;

@end
