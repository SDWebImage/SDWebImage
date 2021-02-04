//
//  SDWebImagePluginConfig.m
//  testVC
//
//  Created by xn on 2021/2/4.
//

#import "SDWebImagePluginConfig.h"
#import <SDWebImage/SDWebImage.h>

@implementation SDWebImagePluginConfig

+ (NSString *)getImageClassWithConfigType:(SDWebImagePluginConfigType)configType {
    NSDictionary *dict = @{
        @(SDWebImagePluginConfigTypeSD) : @"SDAnimatedImage",
        @(SDWebImagePluginConfigTypeYY) : @"YYImage"
    };
    return [dict objectForKey:@(configType)];
}

+ (NSString *)getImageViewClassWithConfigType:(SDWebImagePluginConfigType)configType {
    NSDictionary *dict = @{
        @(SDWebImagePluginConfigTypeSD) : @"SDAnimatedImageView",
        @(SDWebImagePluginConfigTypeYY) : @"YYAnimatedImageView"
    };
    return [dict objectForKey:@(configType)];
}

//————————————————————————————————

+ (UIImage  <SDAnimatedImage> *)newImageSD {
    return [self newImageWithConfigType:SDWebImagePluginConfigTypeSD];
}
+ (UIImage  <SDAnimatedImage> *)newImageYY {
    return [self newImageWithConfigType:SDWebImagePluginConfigTypeYY];
}

+ (UIImage <SDAnimatedImage> *)newImageWithConfigType:(SDWebImagePluginConfigType)configType;
{
    NSString *classString = [self getImageClassWithConfigType:configType];
    if (classString.length <=0) {
       return [SDAnimatedImage new];
    }
    
    Class cls = NSClassFromString(classString);
    if (!cls) {
        return [SDAnimatedImage new];
    }
    
    return [cls new];
}

+ (UIImageView<SDPluginAnimateView> *)newImageViewWithConfig:(SDWebImagePluginConfigType)configType;
{
    NSString *classString = [self getImageViewClassWithConfigType:configType];
    if (classString.length <=0) {
       return [SDAnimatedImageView new];
    }
    
    Class cls = NSClassFromString(classString);
    if (!cls) {
        return [SDAnimatedImageView new];
    }
    
    return [cls new];
}

+ (UIImageView<SDPluginAnimateView> *)newImageViewSD;
{
    return [self newImageWithConfigType:SDWebImagePluginConfigTypeSD];
}

+ (UIImageView<SDPluginAnimateView> *)newImageViewYY;
{
    return [self newImageViewWithConfig:SDWebImagePluginConfigTypeYY];
}

@end
