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

#if __IPHONE_OS_VERSION_MIN_REQUIRED != 20000 && __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_5_0
#error SDWebImage doesn't support Deployment Target version < 5.0
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

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#ifndef NS_OPTIONS
#define NS_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
#endif

#if OS_OBJECT_USE_OBJC
    #undef SDDispatchQueueRelease
    #undef SDDispatchQueueSetterSementics
    #define SDDispatchQueueRelease(q)
    #define SDDispatchQueueSetterSementics strong
#else
#undef SDDispatchQueueRelease
#undef SDDispatchQueueSetterSementics
#define SDDispatchQueueRelease(q) (dispatch_release(q))
#define SDDispatchQueueSetterSementics assign
#endif

extern UIImage *SDScaledImageForKey(NSString *key, UIImage *image);

typedef void(^SDWebImageNoParamsBlock)(void);

extern NSString *const SDWebImageErrorDomain;

#define dispatch_main_sync_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_sync(dispatch_get_main_queue(), block);\
    }

#define dispatch_main_async_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }
