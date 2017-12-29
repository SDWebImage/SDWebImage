/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDMockFileManager.h"

@interface SDMockFileManager ()

@end

@implementation SDMockFileManager

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary<NSFileAttributeKey,id> *)attributes error:(NSError * _Nullable __autoreleasing *)error {
    NSError *mockError = [self.mockSelectors objectForKey:NSStringFromSelector(_cmd)];
    if ([mockError isEqual:[NSNull null]]) {
        if (error) {
            *error = nil;
        }
        return NO;
    } else if (mockError) {
        if (error) {
            *error = mockError;
        }
        return NO;
    } else {
        return [super createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
    }
}

@end
