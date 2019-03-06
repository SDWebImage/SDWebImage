/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDAsyncBlockOperation.h"

@interface SDAsyncBlockOperation ()

@property (nonatomic, assign) BOOL isExecuting;
@property (nonatomic, assign) BOOL isFinished;
@property (nonatomic, copy, nonnull) SDAsyncBlock executionBlock;

@end

@implementation SDAsyncBlockOperation

- (nonnull instancetype)initWithBlock:(nonnull SDAsyncBlock)block {
    self = [super init];
    if (self) {
        self.executionBlock = block;
    }
    return self;
}

+ (nonnull instancetype)blockOperationWithBlock:(nonnull SDAsyncBlock)block {
    SDAsyncBlockOperation *operation = [[SDAsyncBlockOperation alloc] initWithBlock:block];
    return operation;
}

- (void)start {
    [self willChangeValueForKey:@"isExecuting"];
    self.isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    if (self.executionBlock) {
        self.executionBlock(self);
    } else {
        [self complete];
    }
}

- (void)complete {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.isExecuting = NO;
    self.isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

@end
