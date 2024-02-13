/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDTestCase.h"

const int64_t kAsyncTestTimeout = 5;
const int64_t kMinDelayNanosecond = NSEC_PER_MSEC * 100; // 0.1s
NSString *const kTestJPEGURL = @"https://placehold.co/50x50.jpg";
NSString *const kTestProgressiveJPEGURL = @"https://raw.githubusercontent.com/ibireme/YYImage/master/Demo/YYImageDemo/mew_progressive.jpg";
NSString *const kTestPNGURL = @"https://placehold.co/50x50.png";
NSString *const kTestGIFURL = @"https://media.giphy.com/media/UEsrLdv7ugRTq/giphy.gif";
NSString *const kTestAPNGPURL = @"https://upload.wikimedia.org/wikipedia/commons/1/14/Animated_PNG_example_bouncing_beach_ball.png";

@implementation SDTestCase

- (void)waitForExpectationsWithCommonTimeout {
    [self waitForExpectationsWithCommonTimeoutUsingHandler:nil];
}

- (void)waitForExpectationsWithCommonTimeoutUsingHandler:(XCWaitCompletionHandler)handler {
    [self waitForExpectationsWithTimeout:kAsyncTestTimeout handler:handler];
}

#pragma mark - Helper
- (UIWindow *)window {
    if (!_window) {
#if SD_UIKIT
#if SD_VISION
        CGSize screenSize = CGSizeMake(1280, 720); // https://developer.apple.com/design/human-interface-guidelines/windows#visionOS
        CGRect screenFrame = CGRectMake(0, 0, screenSize.width, screenSize.height);
#else
        UIScreen *mainScreen = [UIScreen mainScreen];
        CGRect screenFrame = mainScreen.bounds;
#endif
        _window = [[UIWindow alloc] initWithFrame:screenFrame];
#else
        _window = [[NSWindow alloc] initWithContentRect:mainScreen.frame styleMask:0 backing:NSBackingStoreBuffered defer:NO screen:mainScreen];
#endif
    }
    return _window;
}

@end
