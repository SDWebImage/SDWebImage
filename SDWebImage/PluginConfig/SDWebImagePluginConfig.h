//
//  SDWebImagePluginConfig.h
//  testVC
//
//  Created by xn on 2021/2/4.
//

#import <Foundation/Foundation.h>
#import "SDWebImagePluginConfigDefine.h"
#import "SDAnimatedImage.h"
#import "UIImageView+SDPluginAnimateView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDWebImagePluginConfig : NSObject

// convince method
+ (UIImage  <SDAnimatedImage> *)newImageSD;
+ (UIImage  <SDAnimatedImage> *)newImageYY;

+ (UIImage <SDAnimatedImage> *)newImageWithConfigType:(SDWebImagePluginConfigType)configType;


+ (UIImageView<SDPluginAnimateView> *)newImageViewSD;
+ (UIImageView<SDPluginAnimateView> *)newImageViewYY;

+ (UIImageView<SDPluginAnimateView> *)newImageViewWithConfig:(SDWebImagePluginConfigType)configType;

@end

NS_ASSUME_NONNULL_END
