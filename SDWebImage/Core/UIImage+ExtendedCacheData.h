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

@interface UIImage (ExtendedCacheData)

/**
 Read and Write the extended object and bind it to the image. Which can hold some extra metadata like Image's scale factor, URL rich link, date, etc.
 The extended object should conforms to NSCoding, which we use `NSKeyedArchiver` and `NSKeyedUnarchiver` to archive it to data, and write to disk cache.
 @note The disk cache preserve both of the data and extended data with the same cache key. For manual query, use the `SDDiskCache` protocol method `extendedDataForKey:` instead.
 */
@property (nonatomic, strong, nullable) id<NSCoding> sd_extendedObject;

@end
