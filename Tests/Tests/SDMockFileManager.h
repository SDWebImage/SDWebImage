/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>

// This is a mock class to provide custom error for methods
@interface SDMockFileManager : NSFileManager

@property (nonatomic, strong, readonly, nullable) NSError *lastError;

@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSError *> *mockSelectors; // used to specify mocked selectors which will return NO with specify error instead of normal process. If you specify a NSNull, will use nil instead.

@end
