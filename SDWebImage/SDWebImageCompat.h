/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Jamie Pinkham
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <TargetConditionals.h>

#ifdef __OBJC_GC__
#error SDWebImage does not support Objective-C Garbage Collection
#endif

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0
#error SDWebImage doesn't support Deployement Target version < 5.0
#endif

#if !TARGET_OS_IPHONE
#import <AppKit/AppKit.h>
#ifndef UIImage
#define UIImage NSImage
#endif
#ifndef UIImageView
#define UIImageView NSImageView
#endif
#else
#import <UIKit/UIKit.h>
#endif

// @see https://github.com/ccgus/fmdb/commit/aef763eeb64e6fa654e7d121f1df4c16a98d9f4f
#define SDDispatchQueueRelease(q) (dispatch_release(q))
#if TARGET_OS_IPHONE
    #if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
        #undef SDDispatchQueueRelease
        #define SDDispatchQueueRelease(q)
        #undef SDDispatchQueueSetterSementics
        #define SDDispatchQueueSetterSementics strong
    #endif
#else
    #if MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
        #undef SDDispatchQueueRelease
        #define SDDispatchQueueRelease(q)
        #undef SDDispatchQueueSetterSementics
        #define SDDispatchQueueSetterSementics strong
    #endif
#endif

#if OS_OBJECT_USE_OBJC
    #define SDDispatchQueueSetterSementics strong
#else
    #define SDDispatchQueueSetterSementics assign
#endif

extern UIImage *SDScaledImageForPath(NSString *path, NSObject *imageOrData);
