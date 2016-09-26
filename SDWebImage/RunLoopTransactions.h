//
//  RunLoopTransactions.h
//  SDWebImage
//
//  Created by 刘微 on 16/4/1.
//  Copyright © 2016年 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RunLoopTransactions : NSObject

/**
 *  To add a transaction to NSSet,only when the mainrunloop into idle state to perform
 */
+ (RunLoopTransactions *)transactionsWithTarget:(id)target
                                       selector:(SEL)selector
                                         object:(id)object;


- (void)commit;


@end
