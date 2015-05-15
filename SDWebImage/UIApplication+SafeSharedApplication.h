//
//  UIApplication+SafeSharedApplication.h
//  SDWebImage
//
//  Created by Yusef Napora on 5/15/15.
//  Copyright (c) 2015 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (SafeSharedApplication)
+ (UIApplication *) sdw_sharedApplication;
@end
