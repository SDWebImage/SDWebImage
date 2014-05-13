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

@interface SDWebImageDownloaderOperation : NSOperation <SDWebImageOperation>

///---------------------------------
/// @name URL Connection Information
///---------------------------------

/**
 The request used by the operation's connection.
 */
@property (strong, nonatomic, readonly) NSURLRequest *request;

///----------------------------------
/// @name URL Credentials Information
///----------------------------------

/**
 Whether the URL connection should consult the credential storage for authenticating the connection. `YES` by default.
 
 This is the value that is returned in the `NSURLConnectionDelegate` method `-connectionShouldUseCredentialStorage:`.
 */
@property (nonatomic, assign) BOOL shouldUseCredentialStorage;

/**
 The credential used for authentication challenges in `-connection:didReceiveAuthenticationChallenge:`.
 
 This will be overridden by any shared credentials that exist for the username or password of the request URL, if present.
 */
@property (nonatomic, strong) NSURLCredential *credential;

///------------------------------------
/// @name Request Operation Information
///------------------------------------

/**
 The SDWebImageDownloaderOptions for the receiver.
 */
@property (assign, nonatomic, readonly) SDWebImageDownloaderOptions options;

///----------------------------------------------------------
/// @name Initializing a SDWebImageDownloaderOperation Object
///----------------------------------------------------------

/**
 Initializes and returns a newly allocated operation object with a url connection configured with the specified url request.
 
 @param request The request object to be used by the operation connection.
 */
- (id)initWithRequest:(NSURLRequest *)request
              options:(SDWebImageDownloaderOptions)options
             progress:(SDWebImageDownloaderProgressBlock)progressBlock
            completed:(SDWebImageDownloaderCompletedBlock)completedBlock
            cancelled:(void (^)())cancelBlock;

@end
