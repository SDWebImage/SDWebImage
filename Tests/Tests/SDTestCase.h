/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#define EXP_SHORTHAND   // required by Expecta


#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import <SDWebImage/SDWebImage.h>

#if SD_MAC
#define UIWindow NSWindow
#define UIScreen NSScreen
#endif

FOUNDATION_EXPORT const int64_t kAsyncTestTimeout;
FOUNDATION_EXPORT const int64_t kMinDelayNanosecond;
FOUNDATION_EXPORT NSString * _Nonnull const kTestJPEGURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestProgressiveJPEGURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestPNGURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestGIFURL;
FOUNDATION_EXPORT NSString * _Nonnull const kTestAPNGPURL;

@interface SDTestCase : XCTestCase

- (void)waitForExpectationsWithCommonTimeout;
- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(nullable XCWaitCompletionHandler)handler;

@end
