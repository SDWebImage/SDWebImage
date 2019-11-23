/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
* (c) Fabrice Aneche
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

@interface UIImage (ExtendedData)

/**
 Read and Write the extended data and bind it to the image. Which can hold some extra metadata like Image's scale factor, URL rich link, date, etc.
 The extended data will be write to disk cache as well as the image data. The disk cache preserve both of the data and extended data with the same cache key.
 */
@property (nonatomic, strong, nullable) NSData *sd_extendedData;

@end
