//
//  UIView+WebCacheOperation.h
//  SDWebImage
//
//  Created by Whirlwind on 14-5-22.
//  Copyright (c) 2014年 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDWebImageManager.h"

@interface UIView (WebCacheOperation)

- (void)setImageLoadOperation:(id)operation forKey:(NSString *)Key;

- (void)cancelImageLoadOperationWithKey:(NSString *)key;

- (void)removeImageLoadOperationWithKey:(NSString *)key;

@end
