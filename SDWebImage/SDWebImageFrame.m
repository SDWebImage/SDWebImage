/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

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
