/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDWebImageCompat.h"

typedef void (^SDGraphicsImageDrawingActions)(CGContextRef _Nonnull context);

typedef NS_ENUM(NSInteger, SDGraphicsImageRendererFormatRange) {
    SDGraphicsImageRendererFormatRangeUnspecified = -1,
    SDGraphicsImageRendererFormatRangeAutomatic = 0,
    SDGraphicsImageRendererFormatRangeExtended,
    SDGraphicsImageRendererFormatRangeStandard
};

@interface SDGraphicsImageRendererFormat : NSObject

@property (nonatomic) CGFloat scale;
@property (nonatomic) BOOL opaque;

/**
 For iOS 12+, the value is from system API
 For iOS 10-11, the value is from `prefersExtendedRange` property
 For iOS 9, the value is `.unspecified`
 */
@property (nonatomic) SDGraphicsImageRendererFormatRange preferredRange;

- (nonnull instancetype)init;
+ (nonnull instancetype)preferredFormat;

@end

@interface SDGraphicsImageRenderer : NSObject

- (nonnull instancetype)initWithSize:(CGSize)size;
- (nonnull instancetype)initWithSize:(CGSize)size format:(nonnull SDGraphicsImageRendererFormat *)format;

- (nonnull UIImage *)imageWithActions:(nonnull NS_NOESCAPE SDGraphicsImageDrawingActions)actions;

@end
