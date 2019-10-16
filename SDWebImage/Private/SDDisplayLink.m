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

#if SD_MAC
static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext);
#endif

#if SD_WATCH
#define kSDDisplayLinkInterval 1.0 / 60
#endif

@interface SDDisplayLink ()

#if SD_MAC
@property (nonatomic, assign) CVDisplayLinkRef displayLink;
#elif SD_IOS || SD_TV
@property (nonatomic, strong) CADisplayLink *displayLink;
#else
@property (nonatomic, strong) NSTimer *displayLink;
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

- (CFTimeInterval)duration {
#if SD_MAC
    CVTimeStamp nowTime;
    CVDisplayLinkGetCurrentTime(_displayLink, &nowTime);
    NSTimeInterval duration = (double)nowTime.videoRefreshPeriod / ((double)nowTime.videoTimeScale * nowTime.rateScalar);
#elif SD_IOS || SD_TV
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSTimeInterval duration = self.displayLink.duration * self.displayLink.frameInterval;
    #pragma clang diagnostic pop
#else
    NSTimeInterval duration = 1.0 / 60;
#endif
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
    // CVDisplayLink does not use runloop
#elif SD_IOS || SD_TV
    [self.displayLink addToRunLoop:runloop forMode:mode];
#else
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
    // CVDisplayLink does not use runloop
#elif SD_IOS || SD_TV
    [self.displayLink removeFromRunLoop:runloop forMode:mode];
#else
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
}

- (void)displayLinkDidRefresh:(id)displayLink {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [_target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
}

@end

#if SD_MAC
static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
    // CVDisplayLink callback is not on main queue
    SDDisplayLink *object = (__bridge SDDisplayLink *)displayLinkContext;
    __weak SDDisplayLink *weakObject = object;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakObject displayLinkDidRefresh:(__bridge id)(displayLink)];
    });
    return kCVReturnSuccess;
}
#endif
