/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDDisplayLink.h"
#import "SDWeakProxy.h"
#if SD_MAC
#import <CoreVideo/CoreVideo.h>
#elif SD_IOS || SD_TV
#import <QuartzCore/QuartzCore.h>
#endif
#include <mach/mach_time.h>

#if SD_MAC
static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext);
#endif

#define kSDDisplayLinkInterval 1.0 / 60

@interface SDDisplayLink ()

@property (nonatomic, assign) NSTimeInterval previousFireTime;
@property (nonatomic, assign) NSTimeInterval nextFireTime;

#if SD_MAC
@property (nonatomic, assign) CVDisplayLinkRef displayLink;
@property (nonatomic, assign) CVTimeStamp outputTime;
@property (nonatomic, copy) NSRunLoopMode runloopMode;
#elif SD_IOS || SD_TV
@property (nonatomic, strong) CADisplayLink *displayLink;
#else
@property (nonatomic, strong) NSTimer *displayLink;
@property (nonatomic, strong) NSRunLoop *runloop;
@property (nonatomic, copy) NSRunLoopMode runloopMode;
#endif

@end

@implementation SDDisplayLink

- (void)dealloc {
#if SD_MAC
    if (_displayLink) {
        CVDisplayLinkRelease(_displayLink);
        _displayLink = NULL;
    }
#elif SD_IOS || SD_TV
    [_displayLink invalidate];
    _displayLink = nil;
#else
    [_displayLink invalidate];
    _displayLink = nil;
#endif
}

- (instancetype)initWithTarget:(id)target selector:(SEL)sel {
    self = [super init];
    if (self) {
        _target = target;
        _selector = sel;
#if SD_MAC
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        CVDisplayLinkSetOutputCallback(_displayLink, DisplayLinkCallback, (__bridge void *)self);
#elif SD_IOS || SD_TV
        SDWeakProxy *weakProxy = [SDWeakProxy proxyWithTarget:self];
        _displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(displayLinkDidRefresh:)];
#else
        SDWeakProxy *weakProxy = [SDWeakProxy proxyWithTarget:self];
        _displayLink = [NSTimer timerWithTimeInterval:kSDDisplayLinkInterval target:weakProxy selector:@selector(displayLinkDidRefresh:) userInfo:nil repeats:YES];
#endif
    }
    return self;
}

+ (instancetype)displayLinkWithTarget:(id)target selector:(SEL)sel {
    SDDisplayLink *displayLink = [[SDDisplayLink alloc] initWithTarget:target selector:sel];
    return displayLink;
}

- (NSTimeInterval)duration {
    NSTimeInterval duration = 0;
#if SD_MAC
    CVTimeStamp outputTime = self.outputTime;
    double periodPerSecond = (double)outputTime.videoTimeScale * outputTime.rateScalar;
    if (periodPerSecond > 0) {
        duration = (double)outputTime.videoRefreshPeriod / periodPerSecond;
    }
#elif SD_UIKIT
    // iOS 10+/watchOS use `nextTime`
    if (@available(iOS 10.0, tvOS 10.0, *)) {
        duration = self.nextFireTime - CACurrentMediaTime();
    } else {
        // iOS 9 use `previousTime`
        duration = CACurrentMediaTime() - self.previousFireTime;
    }
#else
    if (self.nextFireTime != 0) {
        // `CFRunLoopTimerGetNextFireDate`: This time could be a date in the past if a run loop has not been able to process the timer since the firing time arrived.
        // Don't rely on this, always calculate based on elapsed time
        duration = CFRunLoopTimerGetNextFireDate((__bridge CFRunLoopTimerRef)self.displayLink) - self.nextFireTime;
    }
#endif
    // When system sleep, the targetTimestamp will mass up, fallback refresh rate
    if (duration < 0) {
#if SD_MAC
        // Supports Pro display 120Hz
        CGDirectDisplayID display = CVDisplayLinkGetCurrentCGDisplay(_displayLink);
        CGDisplayModeRef mode = CGDisplayCopyDisplayMode(display);
        if (mode) {
            double refreshRate = CGDisplayModeGetRefreshRate(mode);
            if (refreshRate > 0) {
                duration = 1.0 / refreshRate;
            } else {
                duration = kSDDisplayLinkInterval;
            }
            CGDisplayModeRelease(mode);
        } else {
            duration = kSDDisplayLinkInterval;
        }
#elif SD_IOS || SD_TV
        // Fallback
        duration = self.displayLink.duration;
#else
        // Watch always 60Hz
        duration = kSDDisplayLinkInterval;
#endif
    }
    return duration;
}

- (BOOL)isRunning {
#if SD_MAC
    return CVDisplayLinkIsRunning(self.displayLink);
#elif SD_IOS || SD_TV
    return !self.displayLink.isPaused;
#else
    return self.displayLink.isValid;
#endif
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode {
    if  (!runloop || !mode) {
        return;
    }
#if SD_MAC
    self.runloopMode = mode;
#elif SD_IOS || SD_TV
    [self.displayLink addToRunLoop:runloop forMode:mode];
#else
    self.runloop = runloop;
    self.runloopMode = mode;
    CFRunLoopMode cfMode;
    if ([mode isEqualToString:NSDefaultRunLoopMode]) {
        cfMode = kCFRunLoopDefaultMode;
    } else if ([mode isEqualToString:NSRunLoopCommonModes]) {
        cfMode = kCFRunLoopCommonModes;
    } else {
        cfMode = (__bridge CFStringRef)mode;
    }
    CFRunLoopAddTimer(runloop.getCFRunLoop, (__bridge CFRunLoopTimerRef)self.displayLink, cfMode);
#endif
}

- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode {
    if  (!runloop || !mode) {
        return;
    }
#if SD_MAC
    self.runloopMode = nil;
#elif SD_IOS || SD_TV
    [self.displayLink removeFromRunLoop:runloop forMode:mode];
#else
    self.runloop = nil;
    self.runloopMode = nil;
    CFRunLoopMode cfMode;
    if ([mode isEqualToString:NSDefaultRunLoopMode]) {
        cfMode = kCFRunLoopDefaultMode;
    } else if ([mode isEqualToString:NSRunLoopCommonModes]) {
        cfMode = kCFRunLoopCommonModes;
    } else {
        cfMode = (__bridge CFStringRef)mode;
    }
    CFRunLoopRemoveTimer(runloop.getCFRunLoop, (__bridge CFRunLoopTimerRef)self.displayLink, cfMode);
#endif
}

- (void)start {
#if SD_MAC
    CVDisplayLinkStart(self.displayLink);
#elif SD_IOS || SD_TV
    self.displayLink.paused = NO;
#else
    if (self.displayLink.isValid) {
        [self.displayLink fire];
    } else {
        SDWeakProxy *weakProxy = [SDWeakProxy proxyWithTarget:self];
        self.displayLink = [NSTimer timerWithTimeInterval:kSDDisplayLinkInterval target:weakProxy selector:@selector(displayLinkDidRefresh:) userInfo:nil repeats:YES];
        [self addToRunLoop:self.runloop forMode:self.runloopMode];
    }
#endif
}

- (void)stop {
#if SD_MAC
    CVDisplayLinkStop(self.displayLink);
#elif SD_IOS || SD_TV
    self.displayLink.paused = YES;
#else
    [self.displayLink invalidate];
#endif
    self.previousFireTime = 0;
    self.nextFireTime = 0;
}

- (void)displayLinkDidRefresh:(id)displayLink {
#if SD_IOS || SD_TV
    if (@available(iOS 10.0, tvOS 10.0, *)) {
        self.nextFireTime = self.displayLink.targetTimestamp;
    } else {
        self.previousFireTime = self.displayLink.timestamp;
    }
#endif
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
#if SD_WATCH
    self.nextFireTime = CFRunLoopTimerGetNextFireDate((__bridge CFRunLoopTimerRef)self.displayLink);
#endif
}

@end

#if SD_MAC
static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
    // CVDisplayLink callback is not on main queue
    SDDisplayLink *object = (__bridge SDDisplayLink *)displayLinkContext;
    // CVDisplayLink does not use runloop, but we can provide similar behavior for modes
    // May use `default` runloop to avoid extra callback when in `eventTracking` (mouse drag, scroll) or `modalPanel` (modal panel)
    NSString *runloopMode = object.runloopMode;
    if (![runloopMode isEqualToString:NSRunLoopCommonModes] && ![runloopMode isEqualToString:NSRunLoop.mainRunLoop.currentMode]) {
        return kCVReturnSuccess;
    }
    CVTimeStamp outputTime = inOutputTime ? *inOutputTime : *inNow;
    __weak SDDisplayLink *weakObject = object;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakObject.outputTime = outputTime;
        [weakObject displayLinkDidRefresh:(__bridge id)(displayLink)];
    });
    return kCVReturnSuccess;
}
#endif
