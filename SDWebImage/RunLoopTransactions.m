//
//  RunLoopTransactions.m
//  SDWebImage
//
//  Created by 刘微 on 16/4/1.
//  Copyright © 2016年 Dailymotion. All rights reserved.
//

#import "RunLoopTransactions.h"


@interface RunLoopTransactions ()

@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, strong) id object;

@end


static NSMutableSet* transactionSet = nil;

static void RunLoopObserverCallBack(CFRunLoopObserverRef observer,
                                    CFRunLoopActivity activity,
                                    void *info) {
    if (transactionSet.count == 0) return;
    NSSet* currentSet = transactionSet;
    transactionSet = [[NSMutableSet alloc] init];
    [currentSet enumerateObjectsUsingBlock:^(RunLoopTransactions* transactions, BOOL* stop) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [transactions.target performSelector:transactions.selector withObject:transactions.object];
#pragma clang diagnostic pop
    }];
}

static void RunLoopTransactionsSetup() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transactionSet = [[NSMutableSet alloc] init];
        CFRunLoopRef runloop = CFRunLoopGetMain();
        CFRunLoopObserverRef observer;
        observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(),
                                           kCFRunLoopBeforeWaiting | kCFRunLoopExit,
                                           true,
                                           0xFFFFFF,
                                           RunLoopObserverCallBack, NULL);
        CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    });
}


@implementation RunLoopTransactions


+ (RunLoopTransactions *)transactionsWithTarget:(id)target
                                       selector:(SEL)selector
                                         object:(id)object {
    if (!target || !selector) {
        return nil;
    }
    RunLoopTransactions* transactions = [[RunLoopTransactions alloc] init];
    transactions.target = target;
    transactions.selector = selector;
    transactions.object = object;
    return transactions;
}

- (void)commit {
    if (!_target || !_selector) {
        return;
    }
    RunLoopTransactionsSetup();
    [transactionSet addObject:self];
}

- (NSUInteger)hash {
    long v1 = (long)((void *)_selector);
    long v2 = (long)_target;
    return v1 ^ v2;
}

- (BOOL)isEqual:(id)object{
    if (self == object) {
        return YES;
    }
    if (![object isMemberOfClass:self.class]){
        return NO;
    }
    RunLoopTransactions* other = object;
    return other.selector == _selector && other.target == _target;
}



@end
