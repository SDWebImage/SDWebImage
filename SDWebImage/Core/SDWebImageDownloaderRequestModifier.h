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

/**
 This is the protocol for downloader request modifier.
 We can use a block to specify the downloader request modifier. But Using protocol can make this extensible, and allow Swift user to use it easily instead of using `@convention(block)` to store a block into context options.
 */
@protocol SDWebImageDownloaderRequestModifier <NSObject>

/// Modify the original URL request and return a new one instead. You can modify the HTTP header, cachePolicy, etc for this URL.
/// @param request The original URL request for image loading
/// @note If return nil, the URL request will be cancelled.
- (nullable NSURLRequest *)modifiedRequestWithRequest:(nonnull NSURLRequest *)request;

@end

/**
 A downloader request modifier class with block.
 */
@interface SDWebImageDownloaderRequestModifier : NSObject <SDWebImageDownloaderRequestModifier>

- (nonnull instancetype)initWithBlock:(nonnull SDWebImageDownloaderRequestModifierBlock)block;
+ (nonnull instancetype)requestModifierWithBlock:(nonnull SDWebImageDownloaderRequestModifierBlock)block;

@end

/**
 A convenient request modifier to provide the HTTP request including HTTP method, headers and body.
 */
@interface SDWebImageDownloaderHTTPRequestModifier : NSObject <SDWebImageDownloaderRequestModifier>

/// Create the request modifier with HTTP Method, Headers and Body
/// @param method HTTP Method, nil means to GET.
/// @param headers HTTP Headers. Case insensitive according to HTTP/1.1(HTTP/2) standard. The headers will overide the same fileds from original request.
/// @param body HTTP Body
/// @note This is for convenience, if you need code to control the logic, use `SDWebImageDownloaderRequestModifier` instead
- (nonnull instancetype)initWithMethod:(nullable NSString *)method headers:(nullable NSDictionary<NSString *, NSString *> *)headers body:(nullable NSData *)body;

/// Create the request modifier with HTTP Method, Headers and Body
/// @param method HTTP Method, nil means to GET.
/// @param headers HTTP Headers. Case insensitive according to HTTP/1.1(HTTP/2) standard. The headers will overide the same fileds from SDWebImageDownloader global configuration.
/// @param body HTTP Body
/// @note This is for convenience, if you need code to control the logic, use `SDWebImageDownloaderRequestModifier` instead
+ (nonnull instancetype)requestModifierWithMethod:(nullable NSString *)method headers:(nullable NSDictionary<NSString *, NSString *> *)headers body:(nullable NSData *)body;

@end
