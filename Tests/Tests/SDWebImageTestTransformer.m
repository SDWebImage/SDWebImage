/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTestTransformer.h"

@implementation SDWebImageTestTransformer

- (NSString *)transformerKey {
    return @"SDWebImageTestTransformer";
}

- (UIImage *)transformedImageWithImage:(UIImage *)image forKey:(NSString *)key {
    return self.testImage;
}

@end
