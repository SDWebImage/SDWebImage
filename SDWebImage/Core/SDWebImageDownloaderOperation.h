/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageDownloader.h"
#import "SDWebImageOperation.h"

/**
 Describes a downloader operation. If one wants to use a custom downloader op, it needs to inherit from `NSOperation` and conform to this protocol
 For the description about these methods, see `SDWebImageDownloaderOperation`
 @note If your custom operation class does not use `NSURLSession` at all, do not implement the optional methods and session delegate methods.
 */
@protocol SDWebImageDownloaderOperation <NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@required
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                                options:(SDWebImageDownloaderOptions)options;

- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                                options:(SDWebImageDownloaderOptions)options
                                context:(nullable SDWebImageContext *)context;

- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock;

- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock
                        decodeOptions:(nullable SDImageCoderOptions *)decodeOptions;

- (BOOL)cancel:(nullable id)token;

@property (strong, nonatomic, readonly, nullable) NSURLRequest *request;
@property (strong, nonatomic, readonly, nullable) NSURLResponse *response;

@optional
@property (strong, nonatomic, readonly, nullable) NSURLSessionTask *dataTask;
@property (strong, nonatomic, readonly, nullable) NSURLSessionTaskMetrics *metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

// These operation-level config was inherited from downloader. See `SDWebImageDownloaderConfig` for documentation.
@property (strong, nonatomic, nullable) NSURLCredential *credential;
@property (assign, nonatomic) double minimumProgressInterval;
@property (copy, nonatomic, nullable) NSIndexSet *acceptableStatusCodes;
@property (copy, nonatomic, nullable) NSSet<NSString *> *acceptableContentTypes;

@end


/**
 The download operation class for SDWebImageDownloader.
 */
@interface SDWebImageDownloaderOperation : NSOperation <SDWebImageDownloaderOperation>

/**
 * The request used by the operation's task.
 */
@property (strong, nonatomic, readonly, nullable) NSURLRequest *request;

/**
 * The response returned by the operation's task.
 */
@property (strong, nonatomic, readonly, nullable) NSURLResponse *response;

/**
 * The operation's task
 */
@property (strong, nonatomic, readonly, nullable) NSURLSessionTask *dataTask;

/**
 * The collected metrics from `-URLSession:task:didFinishCollectingMetrics:`.
 * This can be used to collect the network metrics like download duration, DNS lookup duration, SSL handshake duration, etc. See Apple's documentation: https://developer.apple.com/documentation/foundation/urlsessiontaskmetrics
 */
@property (strong, nonatomic, readonly, nullable) NSURLSessionTaskMetrics *metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

/**
 * The credential used for authentication challenges in `-URLSession:task:didReceiveChallenge:completionHandler:`.
 *
 * This will be overridden by any shared credentials that exist for the username or password of the request URL, if present.
 */
@property (strong, nonatomic, nullable) NSURLCredential *credential;

/**
 * The minimum interval about progress percent during network downloading. Which means the next progress callback and current progress callback's progress percent difference should be larger or equal to this value. However, the final finish download progress callback does not get effected.
 * The value should be 0.0-1.0.
 * @note If you're using progressive decoding feature, this will also effect the image refresh rate.
 * @note This value may enhance the performance if you don't want progress callback too frequently.
 * Defaults to 0, which means each time we receive the new data from URLSession, we callback the progressBlock immediately.
 */
@property (assign, nonatomic) double minimumProgressInterval;

/**
 * Set the acceptable HTTP Response status code. The status code which beyond the range will mark the download operation failed.
 * For example, if we config [200, 400) but server response is 503, the download will fail with error code `SDWebImageErrorInvalidDownloadStatusCode`.
 * Defaults to [200,400). Nil means no validation at all.
 */
@property (copy, nonatomic, nullable) NSIndexSet *acceptableStatusCodes;

/**
 * Set the acceptable HTTP Response content type. The content type beyond the set will mark the download operation failed.
 * For example, if we config ["image/png"] but server response is "application/json", the download will fail with error code `SDWebImageErrorInvalidDownloadContentType`.
 * Normally you don't need this for image format detection because we use image's data file signature magic bytes: https://en.wikipedia.org/wiki/List_of_file_signatures
 * Defaults to nil. Nil means no validation at all.
 */
@property (copy, nonatomic, nullable) NSSet<NSString *> *acceptableContentTypes;

/**
 * The options for the receiver.
 */
@property (assign, nonatomic, readonly) SDWebImageDownloaderOptions options;

/**
 * The context for the receiver.
 */
@property (copy, nonatomic, readonly, nullable) SDWebImageContext *context;

/**
 *  Initializes a `SDWebImageDownloaderOperation` object
 *
 *  @see SDWebImageDownloaderOperation
 *
 *  @param request        the URL request
 *  @param session        the URL session in which this operation will run
 *  @param options        downloader options
 *
 *  @return the initialized instance
 */
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                                options:(SDWebImageDownloaderOptions)options;

/**
 *  Initializes a `SDWebImageDownloaderOperation` object
 *
 *  @see SDWebImageDownloaderOperation
 *
 *  @param request        the URL request
 *  @param session        the URL session in which this operation will run
 *  @param options        downloader options
 *  @param context        A context contains different options to perform specify changes or processes, see `SDWebImageContextOption`. This hold the extra objects which `options` enum can not hold.
 *
 *  @return the initialized instance
 */
- (nonnull instancetype)initWithRequest:(nullable NSURLRequest *)request
                              inSession:(nullable NSURLSession *)session
                                options:(SDWebImageDownloaderOptions)options
                                context:(nullable SDWebImageContext *)context NS_DESIGNATED_INITIALIZER;

/**
 *  Adds handlers for progress and completion. Returns a token that can be passed to -cancel: to cancel this set of
 *  callbacks.
 *
 *  @param progressBlock  the block executed when a new chunk of data arrives.
 *                        @note the progress block is executed on a background queue
 *  @param completedBlock the block executed when the download is done.
 *                        @note the completed block is executed on the main queue for success. If errors are found, there is a chance the block will be executed on a background queue
 *
 *  @return the token to use to cancel this set of handlers
 */
- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock;

/**
 *  Adds handlers for progress and completion, and optional decode options (which need another image other than the initial one). Returns a token that can be passed to -cancel: to cancel this set of
 *  callbacks.
 *
 *  @param progressBlock  the block executed when a new chunk of data arrives.
 *                        @note the progress block is executed on a background queue
 *  @param completedBlock the block executed when the download is done.
 *                        @note the completed block is executed on the main queue for success. If errors are found, there is a chance the block will be executed on a background queue
 *  @param decodeOptions The optional decode options, used when in thumbnail decoding for current completion block callback. For example, request <url1, {thumbnail: 100x100}> and then <url1, {thumbnail: 200x200}>, we may callback these two completion block with different size.
 *  @return the token to use to cancel this set of handlers
 */
- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock
                        decodeOptions:(nullable SDImageCoderOptions *)decodeOptions;

/**
 *  Cancels a set of callbacks. Once all callbacks are canceled, the operation is cancelled.
 *
 *  @param token the token representing a set of callbacks to cancel
 *
 *  @return YES if the operation was stopped because this was the last token to be canceled. NO otherwise.
 */
- (BOOL)cancel:(nullable id)token;

@end
