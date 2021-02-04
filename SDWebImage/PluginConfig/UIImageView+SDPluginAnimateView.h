//
//  UIImageView+SDPluginAnimateView.h
//  testVC
//
//  Created by xn on 2021/2/4.
//

#import <UIKit/UIKit.h>

@protocol SDPluginAnimateView <NSObject>

@end

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (SDPluginAnimateView) <SDPluginAnimateView>

@end



NS_ASSUME_NONNULL_END
