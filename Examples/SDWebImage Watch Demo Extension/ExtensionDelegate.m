/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "ExtensionDelegate.h"

#import <SDWebImage/SDWebImage.h>
#import <SDWebImageWebPCoder/SDWebImageWebPCoder.h>

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
    if (@available(iOS 14, tvOS 14, macOS 11, watchOS 7, *)) {
        // iOS 14 supports WebP built-in
        [[SDImageCodersManager sharedManager] addCoder:[SDImageAWebPCoder sharedCoder]];
    } else {
        // iOS 13 does not supports WebP, use third-party codec
        [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
    }
    if (@available(iOS 13, tvOS 13, macOS 10.15, watchOS 6, *)) {
        // For HEIC animated image. Animated image is new introduced in iOS 13, but it contains performance issue for now.
        [[SDImageCodersManager sharedManager] addCoder:[SDImageHEICCoder sharedCoder]];
    }
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

@end
