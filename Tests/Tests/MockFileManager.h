//
//  MockFileManager.h
//  SDWebImage Tests
//
//  Created by Anton Popovichenko on 11.05.17.
//
//

#import <Foundation/Foundation.h>

@interface MockFileManager : NSFileManager

- (id)initWithSendError:(int)errorNumber;

@end
