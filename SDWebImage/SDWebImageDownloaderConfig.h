/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

typedef NS_ENUM(NSInteger, SDWebImageDownloaderExecutionOrder) {
    /**
     * Default value. All download operations will execute in queue style (first-in-first-out).
     */
    SDWebImageDownloaderFIFOExecutionOrder,
    
    /**
     * All download operations will execute in stack style (last-in-first-out).
     */
    SDWebImageDownloaderLIFOExecutionOrder
};

@interface SDWebImageDownloaderConfig : NSObject <NSCopying>

/**
 Gets/Sets the default downloader config.
 */
@property (nonatomic, class, nonnull) SDWebImageDownloaderConfig *defaultDownloaderConfig;

/**
 * Decompressing images that are downloaded and cached can improve performance but can consume lot of memory.
 * Defaults to YES. Set this to NO if you are experiencing a crash due to excessive memory consumption.
 */
@property (nonatomic, assign) BOOL shouldDecompressImages;

/**
 *  The maximum number of concurrent downloads
 */
@property (nonatomic, assign) NSInteger maxConcurrentDownloads;

/**
 *  The timeout value (in seconds) for the download operation. Default: 15.0.
 */
@property (nonatomic, assign) NSTimeInterval downloadTimeout;

/**
 * The custom session configuration in use by NSURLSession.
 */
@property (nonatomic, strong, nonnull) NSURLSessionConfiguration *sessionConfiguration;

/**
 * Gets/Sets a subclass of `SDWebImageDownloaderOperation` as the default
 * `NSOperation` to be used each time SDWebImage constructs a request
 * operation to download an image.
 *
 * @note Passing `NSOperation<SDWebImageDownloaderOperation>` to set as default. Passing `nil` will revert to `SDWebImageDownloaderOperation`.
 */
@property (nonatomic, assign, nullable) Class operationClass;

/**
 * Changes download operations execution order. Default value is `SDWebImageDownloaderFIFOExecutionOrder`.
 */
@property (nonatomic, assign) SDWebImageDownloaderExecutionOrder executionOrder;

/**
 *  Set the default URL credential to be set for request operations.
 */
@property (nonatomic, strong, nullable) NSURLCredential *urlCredential;

/**
 * Set username
 */
@property (nonatomic, copy, nullable) NSString *username;

/**
 * Set password
 */
@property (nonatomic, copy, nullable) NSString *password;

@end
