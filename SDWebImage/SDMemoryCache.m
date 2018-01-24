/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDMemoryCache.h"

@implementation SDMemoryCache

- (NSUInteger)costLimit {
    return self.totalCostLimit;
}

- (void)setCostLimit:(NSUInteger)costLimit {
    self.totalCostLimit = costLimit;
}

@end
