/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */


#import <Foundation/Foundation.h>
#import "SDMemoryCache.h"

@interface SDMemoryLRUCache <KeyType, ObjectType>: NSObject <SDMemoryCache>

@property (nonatomic, strong, nonnull, readonly) SDImageCacheConfig *config;

@end

