//
//  SDMemoryNSCache.h
//  SDWebImage
//
//  Created by Haixiao Xu on 2019/6/18.
//  Copyright © 2019 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDMemoryCache.h"


@interface SDMemoryNSCache <KeyType, ObjectType> : NSCache <SDMemoryCache>
@end
