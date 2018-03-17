/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <SDWebImage/SDWebImageTransformer.h>

@interface SDWebImageTestTransformer : NSObject <SDWebImageTransformer>

@property (nonatomic, strong, nullable) UIImage *testImage;

@end
