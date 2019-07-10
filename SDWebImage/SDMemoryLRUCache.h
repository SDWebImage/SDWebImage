//
//  SDMemoryLRUCache.h
//  SDWebImage
//
//  Created by Haixiao Xu on 2019/6/18.
//  Copyright © 2019 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDMemoryCache.h"

@interface SDMemoryLRUCache : NSObject <SDMemoryCache>
@property (assign, nonatomic) NSUInteger totalCostLimit;

@end

