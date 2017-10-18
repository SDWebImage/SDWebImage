/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDMockFileManager.h"

@interface SDMockFileManager ()

@property (nonatomic, assign) int errorNumber;

@end

@implementation SDMockFileManager

- (id)initWithError:(int)errorNumber {
    self = [super init];
    if (self) {
        _errorNumber = errorNumber;
    }
    
    return self;
}

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary<NSString *,id> *)attr {
    errno = self.errorNumber;
    return (self.errorNumber == 0);
}

@end
