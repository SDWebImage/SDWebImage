/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

typedef NSURLResponse * _Nullable (^SDWebImageDownloaderResponseModifierBlock)(NSURLResponse * _Nonnull response);
typedef NSData * _Nullable (^SDWebImageDownloaderResponseModifierDataBlock)(NSData * _Nonnull data, NSURLResponse * _Nullable response);

/**
 This is the protocol for downloader response modifier.
 We can use a block to specify the downloader response modifier. But Using protocol can make this extensible, and allow Swift user to use it easily instead of using `@convention(block)` to store a block into context options.
 */
@protocol SDWebImageDownloaderResponseModifier <NSObject>

- (nullable NSData *)modifiedDataWithData:(nonnull NSData *)data response:(nullable NSURLResponse *)response;
- (nullable NSURLResponse *)modifiedResponseWithResponse:(nonnull NSURLResponse *)response;

@end

/**
 A downloader response modifier class with block.
 */
@interface SDWebImageDownloaderResponseModifier : NSObject <SDWebImageDownloaderResponseModifier>

- (nonnull instancetype)initWithResponseBlock:(nonnull SDWebImageDownloaderResponseModifierBlock)responseBlock dataBlock:(nonnull SDWebImageDownloaderResponseModifierDataBlock)dataBlock;
+ (nonnull instancetype)responseModifierWithResponseBlock:(nonnull SDWebImageDownloaderResponseModifierBlock)responseBlock dataBlock:(nonnull SDWebImageDownloaderResponseModifierDataBlock)dataBlock;

@end


/// Convenience way to create response modifier for common data encryption.
@interface SDWebImageDownloaderResponseModifier (Conveniences)

/// Base64 Encoded image data
@property (class, readonly, nonnull) SDWebImageDownloaderResponseModifier *base64ResponseModifier;

@end
