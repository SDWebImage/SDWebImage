//
//  SDWebImageFrame.m
//  SDWebImage
//
//  Created by lizhuoli on 2017/10/28.
//  Copyright © 2017年 Dailymotion. All rights reserved.
//

#import "SDWebImageFrame.h"

NSString * _Nonnull const SDWebImageFrameLoopCountKey = @"loopCount";

@interface SDWebImageFrame ()

@property (nonatomic, strong, readwrite, nonnull) UIImage *image;
@property (nonatomic, readwrite, assign) NSUInteger duration;
@property (nonatomic, assign, readwrite, nullable) NSDictionary *property;

@end

@implementation SDWebImageFrame

+ (instancetype)frameWithImage:(UIImage *)image duration:(NSUInteger)duration property:(NSDictionary *)property {
    SDWebImageFrame *frame = [[SDWebImageFrame alloc] init];
    frame.image = image;
    frame.duration = duration;
    frame.property = property;
    
    return frame;
}

@end
