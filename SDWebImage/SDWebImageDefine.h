/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>

typedef void(^SDWebImageNoParamsBlock)(void);
typedef NSString * SDWebImageContextOption NS_STRING_ENUM;
typedef NSDictionary<SDWebImageContextOption, id> SDWebImageContext;

/**
 A Dispatch group to maintain setImageBlock and completionBlock. This is used for custom setImageBlock advanced usage, such like perform background task but need to guarantee the completion block is called after setImageBlock. (dispatch_group_t)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextSetImageGroup;
/**
 A SDWebImageManager instance to control the image download and cache process using in UIImageView+WebCache category and likes. If not provided, use the shared manager (SDWebImageManager)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextCustomManager;

/**
 A dictionary to add addtional HTTP request headers when downloading the image. (NSDictionary)
 */
FOUNDATION_EXPORT SDWebImageContextOption _Nonnull const SDWebImageContextAddtionalHTTPHeaders;
