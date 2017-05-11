//
//  MockFileManager.m
//  SDWebImage Tests
//
//  Created by Anton Popovichenko on 11.05.17.
//
//

#import "MockFileManager.h"

@implementation MockFileManager {
    int _errorNumber;
}

- (id)initWithSendError:(int)errorNumber {
    self = [super init];
    if (self) {
        _errorNumber = errorNumber;
    }
    
    return self;
}

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary<NSString *,id> *)attr {
    errno = _errorNumber;
    return !_errorNumber;
}

@end
