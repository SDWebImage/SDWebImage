/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
* (c) Fabrice Aneche
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "UIImage+ExtendedData.h"
#import <objc/runtime.h>

@implementation UIImage (ExtendedData)

- (NSData *)sd_extendedData {
    return objc_getAssociatedObject(self, @selector(sd_extendedData));
}

- (void)setSd_extendedData:(NSData *)sd_extendedData {
    objc_setAssociatedObject(self, @selector(sd_extendedData), sd_extendedData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
