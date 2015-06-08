//
//  UIView+Animation.m
//  SDWebImage
//
//  Created by 周龙 on 15/6/8.
//  Copyright (c) 2015年 Dailymotion. All rights reserved.
//

#import "UIView+Animation.h"

@implementation UIView (Animation)

- (void)sd_fadeIn {
    CATransition *transition = [CATransition animation];
    transition.duration = .5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.layer addAnimation:transition forKey:@"fade"];
}

@end
