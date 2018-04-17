/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

typedef NSURLRequest * _Nullable (^SDWebImageDownloaderRequestModifierBlock)(NSURLRequest * _Nonnull request);

// This is the protocol for downloader request modifier. We can use a block to specify the downloader request modifier. But Using protocol can make this extensible, and allow Swift user to use it easily instead of using `@convention(block)` to store a block into context options.
@protocol SDWebImageDownloaderRequestModifier <NSObject>

- (nullable NSURLRequest *)modifiedRequestWithRequest:(nonnull NSURLRequest *)request;

@end

@interface SDWebImageDownloaderRequestModifier : NSObject <SDWebImageDownloaderRequestModifier>

- (nonnull instancetype)initWithBlock:(nonnull SDWebImageDownloaderRequestModifierBlock)block;
+ (nonnull instancetype)requestModifierWithBlock:(nonnull SDWebImageDownloaderRequestModifierBlock)block;

@end
