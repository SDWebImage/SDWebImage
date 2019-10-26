/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDAnimatedImageView.h"

#if SD_UIKIT || SD_MAC

#import "UIImage+Metadata.h"
#import "NSImage+Compatibility.h"
#import "SDWeakProxy.h"
#import "SDInternalMacros.h"
#import <mach/mach.h>
#import <objc/runtime.h>

#if SD_MAC
#import <CoreVideo/CoreVideo.h>
static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext);
#endif

static NSUInteger SDDeviceTotalMemory() {
    return (NSUInteger)[[NSProcessInfo processInfo] physicalMemory];
}

static NSUInteger SDDeviceFreeMemory() {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t page_size;
    vm_statistics_data_t vm_stat;
    kern_return_t kern;
    
    kern = host_page_size(host_port, &page_size);
    if (kern != KERN_SUCCESS) return 0;
    kern = host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    if (kern != KERN_SUCCESS) return 0;
    return vm_stat.free_count * page_size;
}

@interface SDAnimatedImageView () <CALayerDelegate> {
    NSRunLoopMode _runLoopMode;
    BOOL _initFinished; // Extra flag to mark the `commonInit` is called
}

@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;
@property (nonatomic, assign, readwrite) NSUInteger currentLoopCount;
@property (nonatomic, assign) NSUInteger totalFrameCount;
@property (nonatomic, assign) NSUInteger totalLoopCount;
@property (nonatomic, strong) UIImage<SDAnimatedImage> *animatedImage;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *frameBuffer;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) BOOL bufferMiss;
@property (nonatomic, assign) BOOL shouldAnimate;
@property (nonatomic, assign) BOOL isProgressive;
@property (nonatomic, assign) NSUInteger maxBufferCount;
@property (nonatomic, strong) NSOperationQueue *fetchQueue;
@property (nonatomic, strong) dispatch_semaphore_t lock;
@property (nonatomic, assign) CGFloat animatedImageScale;
#if SD_MAC
@property (nonatomic, assign) CVDisplayLinkRef displayLink;
#else
@property (nonatomic, strong) CADisplayLink *displayLink;
#endif
@property (nonatomic) CALayer *imageViewLayer; // The actual rendering layer.

@end

@implementation SDAnimatedImageView
#if SD_UIKIT
@dynamic animationRepeatCount; // we re-use this property from `UIImageView` super class on iOS.
#endif

#pragma mark - Initializers

#if SD_MAC
+ (instancetype)imageViewWithImage:(NSImage *)image
{
    NSRect frame = NSMakeRect(0, 0, image.size.width, image.size.height);
    SDAnimatedImageView *imageView = [[SDAnimatedImageView alloc] initWithFrame:frame];
    [imageView setImage:image];
    return imageView;
}
#else
// -initWithImage: isn't documented as a designated initializer of UIImageView, but it actually seems to be.
// Using -initWithImage: doesn't call any of the other designated initializers.
- (instancetype)initWithImage:(UIImage *)image
{
    self = [super initWithImage:image];
    if (self) {
        [self commonInit];
    }
    return self;
}

// -initWithImage:highlightedImage: also isn't documented as a designated initializer of UIImageView, but it doesn't call any other designated initializers.
- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    self = [super initWithImage:image highlightedImage:highlightedImage];
    if (self) {
        [self commonInit];
    }
    return self;
}
#endif

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    // Pay attention that UIKit's `initWithImage:` will trigger a `setImage:` during initialization before this `commonInit`.
    // So the properties which rely on this order, should using lazy-evaluation or do extra check in `setImage:`.
    self.shouldCustomLoopCount = NO;
    self.shouldIncrementalLoad = YES;
#if SD_MAC
    self.wantsLayer = YES;
#endif
#if SD_UIKIT
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    // Mark commonInit finished
    _initFinished = YES;
}

- (void)resetAnimatedImage
{
    self.animatedImage = nil;
    self.totalFrameCount = 0;
    self.totalLoopCount = 0;
    // reset current state
    [self resetCurrentFrameIndex];
    self.shouldAnimate = NO;
    self.isProgressive = NO;
    self.maxBufferCount = 0;
    self.animatedImageScale = 1;
    [_fetchQueue cancelAllOperations];
    // clear buffer cache
    [self clearFrameBuffer];
}

- (void)resetProgressiveImage
{
    self.animatedImage = nil;
    self.totalFrameCount = 0;
    self.totalLoopCount = 0;
    // preserve current state
    self.shouldAnimate = NO;
    self.isProgressive = YES;
    self.maxBufferCount = 0;
    self.animatedImageScale = 1;
    // preserve buffer cache
}

- (void)resetCurrentFrameIndex
{
    self.currentFrame = nil;
    self.currentFrameIndex = 0;
    self.currentLoopCount = 0;
    self.currentTime = 0;
    self.bufferMiss = NO;
}

- (void)clearFrameBuffer
{
    SD_LOCK(self.lock);
    [_frameBuffer removeAllObjects];
    SD_UNLOCK(self.lock);
}

#pragma mark - Accessors
#pragma mark Public

- (void)setImage:(UIImage *)image
{
    if (self.image == image) {
        return;
    }
    
    // Check Progressive rendering
    [self updateIsProgressiveWithImage:image];
    
    if (self.isProgressive) {
        // Reset all value, but keep current state
        [self resetProgressiveImage];
    } else {
        // Stop animating
        [self stopAnimating];
        // Reset all value
        [self resetAnimatedImage];
    }
    
    // We need call super method to keep function. This will impliedly call `setNeedsDisplay`. But we have no way to avoid this when using animated image. So we call `setNeedsDisplay` again at the end.
    super.image = image;
    if ([image.class conformsToProtocol:@protocol(SDAnimatedImage)]) {
        NSUInteger animatedImageFrameCount = ((UIImage<SDAnimatedImage> *)image).animatedImageFrameCount;
        // Check the frame count
        if (animatedImageFrameCount <= 1) {
            return;
        }
        // If progressive rendering is disabled but animated image is incremental. Only show poster image
        if (!self.isProgressive && image.sd_isIncremental) {
            return;
        }
        self.animatedImage = (UIImage<SDAnimatedImage> *)image;
        self.totalFrameCount = animatedImageFrameCount;
        // Get the current frame and loop count.
        self.totalLoopCount = self.animatedImage.animatedImageLoopCount;
        // Get the scale
        self.animatedImageScale = image.scale;
        if (!self.isProgressive) {
            self.currentFrame = image;
            SD_LOCK(self.lock);
            self.frameBuffer[@(self.currentFrameIndex)] = self.currentFrame;
            SD_UNLOCK(self.lock);
        }
        
        // Ensure disabled highlighting; it's not supported (see `-setHighlighted:`).
        super.highlighted = NO;
        
        // Calculate max buffer size
        [self calculateMaxBufferCount];
        // Update should animate
        [self updateShouldAnimate];
        if (self.shouldAnimate) {
            [self startAnimating];
        }

        [self.imageViewLayer setNeedsDisplay];
    }
}

#if SD_UIKIT
- (void)setRunLoopMode:(NSRunLoopMode)runLoopMode
{
    if ([_runLoopMode isEqual:runLoopMode]) {
        return;
    }
    if (_displayLink) {
        if (_runLoopMode) {
            [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_runLoopMode];
        }
        if (runLoopMode.length > 0) {
            [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:runLoopMode];
        }
    }
    _runLoopMode = [runLoopMode copy];
}

- (NSRunLoopMode)runLoopMode
{
    if (!_runLoopMode) {
        _runLoopMode = [[self class] defaultRunLoopMode];
    }
    return _runLoopMode;
}
#endif

- (BOOL)shouldIncrementalLoad {
    if (!_initFinished) {
        return YES; // Defaults to YES
    }
    return _initFinished;
}

#pragma mark - Private
- (NSOperationQueue *)fetchQueue
{
    if (!_fetchQueue) {
        _fetchQueue = [[NSOperationQueue alloc] init];
        _fetchQueue.maxConcurrentOperationCount = 1;
    }
    return _fetchQueue;
}

- (NSMutableDictionary<NSNumber *,UIImage *> *)frameBuffer
{
    if (!_frameBuffer) {
        _frameBuffer = [NSMutableDictionary dictionary];
    }
    return _frameBuffer;
}

- (dispatch_semaphore_t)lock {
    if (!_lock) {
        _lock = dispatch_semaphore_create(1);
    }
    return _lock;
}

#if SD_MAC
- (CVDisplayLinkRef)displayLink
{
    if (!_displayLink) {
        CVReturn error = CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
        if (error) {
            return NULL;
        }
        CVDisplayLinkSetOutputCallback(_displayLink, DisplayLinkCallback, (__bridge void *)self);
    }
    return _displayLink;
}
#else
- (CADisplayLink *)displayLink
{
    if (!_displayLink) {
        // It is important to note the use of a weak proxy here to avoid a retain cycle. `-displayLinkWithTarget:selector:`
        // will retain its target until it is invalidated. We use a weak proxy so that the image view will get deallocated
        // independent of the display link's lifetime. Upon image view deallocation, we invalidate the display
        // link which will lead to the deallocation of both the display link and the weak proxy.
        SDWeakProxy *weakProxy = [SDWeakProxy proxyWithTarget:self];
        _displayLink = [CADisplayLink displayLinkWithTarget:weakProxy selector:@selector(displayDidRefresh:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
    }
    return _displayLink;
}
#endif

#pragma mark - Life Cycle

- (void)dealloc
{
    // Removes the display link from all run loop modes.
#if SD_MAC
    if (_displayLink) {
        CVDisplayLinkRelease(_displayLink);
        _displayLink = NULL;
    }
#else
    [_displayLink invalidate];
    _displayLink = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [_fetchQueue cancelAllOperations];
    [_fetchQueue addOperationWithBlock:^{
        NSNumber *currentFrameIndex = @(self.currentFrameIndex);
        SD_LOCK(self.lock);
        NSArray *keys = self.frameBuffer.allKeys;
        // only keep the next frame for later rendering
        for (NSNumber * key in keys) {
            if (![key isEqualToNumber:currentFrameIndex]) {
                [self.frameBuffer removeObjectForKey:key];
            }
        }
        SD_UNLOCK(self.lock);
    }];
}

#pragma mark - UIView Method Overrides
#pragma mark Observing View-Related Changes

#if SD_MAC
- (void)viewDidMoveToSuperview
#else
- (void)didMoveToSuperview
#endif
{
#if SD_MAC
    [super viewDidMoveToSuperview];
#else
    [super didMoveToSuperview];
#endif
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

#if SD_MAC
- (void)viewDidMoveToWindow
#else
- (void)didMoveToWindow
#endif
{
#if SD_MAC
    [super viewDidMoveToWindow];
#else
    [super didMoveToWindow];
#endif
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

#if SD_MAC
- (void)setAlphaValue:(CGFloat)alphaValue
#else
- (void)setAlpha:(CGFloat)alpha
#endif
{
#if SD_MAC
    [super setAlphaValue:alphaValue];
#else
    [super setAlpha:alpha];
#endif
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    
    [self updateShouldAnimate];
    if (self.shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

#pragma mark - UIImageView Method Overrides
#pragma mark Image Data

- (void)startAnimating
{
    if (self.animatedImage) {
#if SD_MAC
        CVDisplayLinkStart(self.displayLink);
#else
        self.displayLink.paused = NO;
#endif
    } else {
#if SD_UIKIT
        [super startAnimating];
#endif
    }
}

- (void)stopAnimating
{
    if (self.animatedImage) {
        [_fetchQueue cancelAllOperations];
        // Using `_displayLink` here because when UIImageView dealloc, it may trigger `[self stopAnimating]`, we already release the display link in SDAnimatedImageView's dealloc method.
#if SD_MAC
        CVDisplayLinkStop(_displayLink);
#else
        _displayLink.paused = YES;
#endif
        if (self.resetFrameIndexWhenStopped) {
            [self resetCurrentFrameIndex];
        }
        if (self.clearBufferWhenStopped) {
            [self clearFrameBuffer];
        }
    } else {
#if SD_UIKIT
        [super stopAnimating];
#endif
    }
}

- (BOOL)isAnimating
{
    BOOL isAnimating = NO;
    if (self.animatedImage) {
#if SD_MAC
        isAnimating = CVDisplayLinkIsRunning(self.displayLink);
#else
        isAnimating = !self.displayLink.isPaused;
#endif
    } else {
#if SD_UIKIT
        isAnimating = [super isAnimating];
#endif
    }
    return isAnimating;
}

#if SD_MAC
- (void)setAnimates:(BOOL)animates
{
    [super setAnimates:animates];
    if (animates) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}
#endif

#pragma mark Highlighted Image Unsupport

- (void)setHighlighted:(BOOL)highlighted
{
    // Highlighted image is unsupported for animated images, but implementing it breaks the image view when embedded in a UICollectionViewCell.
    if (!self.animatedImage) {
        [super setHighlighted:highlighted];
    }
}


#pragma mark - Private Methods
#pragma mark Animation

// Don't repeatedly check our window & superview in `-displayDidRefresh:` for performance reasons.
// Just update our cached value whenever the animated image or visibility (window, superview, hidden, alpha) is changed.
- (void)updateShouldAnimate
{
#if SD_MAC
    BOOL isVisible = self.window && self.superview && ![self isHidden] && self.alphaValue > 0.0;
#else
    BOOL isVisible = self.window && self.superview && ![self isHidden] && self.alpha > 0.0;
#endif
    self.shouldAnimate = self.animatedImage && self.totalFrameCount > 1 && isVisible;
}

// Update progressive status only after `setImage:` call.
- (void)updateIsProgressiveWithImage:(UIImage *)image
{
    self.isProgressive = NO;
    if (!self.shouldIncrementalLoad) {
        // Early return
        return;
    }
    // We must use `image.class conformsToProtocol:` instead of `image conformsToProtocol:` here
    // Because UIKit on macOS, using internal hard-coded override method, which returns NO
    if ([image.class conformsToProtocol:@protocol(SDAnimatedImage)] && image.sd_isIncremental) {
        UIImage *previousImage = self.image;
        if ([previousImage.class conformsToProtocol:@protocol(SDAnimatedImage)] && previousImage.sd_isIncremental) {
            NSData *previousData = [((UIImage<SDAnimatedImage> *)previousImage) animatedImageData];
            NSData *currentData = [((UIImage<SDAnimatedImage> *)image) animatedImageData];
            // Check whether to use progressive rendering or not
            if (!previousData || !currentData) {
                // Early return
                return;
            }
            
            // Warning: normally the `previousData` is same instance as `currentData` because our `SDAnimatedImage` class share the same `coder` instance internally. But there may be a race condition, that later retrived `currentData` is already been updated and it's not the same instance as `previousData`.
            // And for protocol extensible design, we should not assume `SDAnimatedImage` protocol implementations always share same instance. So both of two reasons, we need that `rangeOfData` check.
            if ([currentData isEqualToData:previousData]) {
                // If current data is the same data (or instance) as previous data
                self.isProgressive = YES;
            } else if (currentData.length > previousData.length) {
                // If current data is appended by previous data, use `NSDataSearchAnchored`, search is limited to start of currentData
                NSRange range = [currentData rangeOfData:previousData options:NSDataSearchAnchored range:NSMakeRange(0, previousData.length)];
                if (range.location != NSNotFound) {
                    // Contains hole previous data and they start with the same beginning
                    self.isProgressive = YES;
                }
            }
        } else {
            // Previous image is not progressive, so start progressive rendering
            self.isProgressive = YES;
        }
    }
}

#if SD_MAC
- (void)displayDidRefresh:(CVDisplayLinkRef)displayLink duration:(NSTimeInterval)duration
#else
- (void)displayDidRefresh:(CADisplayLink *)displayLink
#endif
{
    // If for some reason a wild call makes it through when we shouldn't be animating, bail.
    // Early return!
    if (!self.shouldAnimate) {
        return;
    }
    // Calculate refresh duration
#if SD_UIKIT
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSTimeInterval duration = displayLink.duration * displayLink.frameInterval;
#pragma clang diagnostic pop
#endif
    NSUInteger totalFrameCount = self.totalFrameCount;
    NSUInteger currentFrameIndex = self.currentFrameIndex;
    NSUInteger nextFrameIndex = (currentFrameIndex + 1) % totalFrameCount;
    
    // Check if we have the frame buffer firstly to improve performance
    if (!self.bufferMiss) {
        // Then check if timestamp is reached
        self.currentTime += duration;
        NSTimeInterval currentDuration = [self.animatedImage animatedImageDurationAtIndex:currentFrameIndex];
        if (self.currentTime < currentDuration) {
            // Current frame timestamp not reached, return
            return;
        }
        self.currentTime -= currentDuration;
        NSTimeInterval nextDuration = [self.animatedImage animatedImageDurationAtIndex:nextFrameIndex];
        if (self.currentTime > nextDuration) {
            // Do not skip frame
            self.currentTime = nextDuration;
        }
    }
    
    // Update the current frame
    UIImage *currentFrame;
    UIImage *fetchFrame;
    SD_LOCK(self.lock);
    currentFrame = self.frameBuffer[@(currentFrameIndex)];
    fetchFrame = currentFrame ? self.frameBuffer[@(nextFrameIndex)] : nil;
    SD_UNLOCK(self.lock);
    BOOL bufferFull = NO;
    if (currentFrame) {
        SD_LOCK(self.lock);
        // Remove the frame buffer if need
        if (self.frameBuffer.count > self.maxBufferCount) {
            self.frameBuffer[@(currentFrameIndex)] = nil;
        }
        // Check whether we can stop fetch
        if (self.frameBuffer.count == totalFrameCount) {
            bufferFull = YES;
        }
        SD_UNLOCK(self.lock);
        self.currentFrame = currentFrame;
        self.currentFrameIndex = nextFrameIndex;
        self.bufferMiss = NO;
        [self.imageViewLayer setNeedsDisplay];
    } else {
        self.bufferMiss = YES;
    }
    
    // Update the loop count when last frame rendered
    if (nextFrameIndex == 0 && !self.bufferMiss) {
        // Progressive image reach the current last frame index. Keep the state and stop animating. Wait for later restart
        if (self.isProgressive) {
            // Recovery the current frame index and removed frame buffer (See above)
            self.currentFrameIndex = currentFrameIndex;
            SD_LOCK(self.lock);
            self.frameBuffer[@(currentFrameIndex)] = self.currentFrame;
            SD_UNLOCK(self.lock);
            [self stopAnimating];
            return;
        }
        // Update the loop count
        self.currentLoopCount++;
        // if reached the max loop count, stop animating, 0 means loop indefinitely
        NSUInteger maxLoopCount = self.shouldCustomLoopCount ? self.animationRepeatCount : self.totalLoopCount;
        if (maxLoopCount != 0 && (self.currentLoopCount >= maxLoopCount)) {
            [self stopAnimating];
            return;
        }
    }
    
    // Check if we should prefetch next frame or current frame
    NSUInteger fetchFrameIndex;
    if (self.bufferMiss) {
        // When buffer miss, means the decode speed is slower than render speed, we fetch current miss frame
        fetchFrameIndex = currentFrameIndex;
    } else {
        // Or, most cases, the decode speed is faster than render speed, we fetch next frame
        fetchFrameIndex = nextFrameIndex;
    }
    
    if (!fetchFrame && !bufferFull && self.fetchQueue.operationCount == 0) {
        // Prefetch next frame in background queue
        UIImage<SDAnimatedImage> *animatedImage = self.animatedImage;
        @weakify(self);
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            @strongify(self);
            if (!self) {
                return;
            }
            UIImage *frame = [animatedImage animatedImageFrameAtIndex:fetchFrameIndex];

            BOOL isAnimating = NO;
#if SD_MAC
            isAnimating = CVDisplayLinkIsRunning(self.displayLink);
#else
            isAnimating = !self.displayLink.isPaused;
#endif
            if (isAnimating) {
                SD_LOCK(self.lock);
                self.frameBuffer[@(fetchFrameIndex)] = frame;
                SD_UNLOCK(self.lock);
            }
            // Ensure when self dealloc, it dealloced on the main queue (UIKit/AppKit rule)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self class];
            });
        }];
        [self.fetchQueue addOperation:operation];
    }
}

+ (NSString *)defaultRunLoopMode
{
    // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}


#pragma mark Providing the Layer's Content
#pragma mark - CALayerDelegate

- (void)displayLayer:(CALayer *)layer
{
    if (self.currentFrame) {
        layer.contentsScale = self.animatedImageScale;
        layer.contents = (__bridge id)self.currentFrame.CGImage;
    }
}

#if SD_MAC
// NSImageView use a subview. We need this subview's layer for actual rendering.
// Why using this design may because of properties like `imageAlignment` and `imageScaling`, which it's not available for UIImageView.contentMode (it's impossible to align left and keep aspect ratio at the same time)
- (NSView *)imageView {
    NSImageView *imageView = imageView = objc_getAssociatedObject(self, NSSelectorFromString(@"_imageView"));
    if (!imageView) {
        // macOS 10.14
        imageView = objc_getAssociatedObject(self, NSSelectorFromString(@"_imageSubview"));
    }
    return imageView;
}

// on macOS, it's the imageView subview's layer (we use layer-hosting view to let CALayerDelegate works)
- (CALayer *)imageViewLayer {
    NSView *imageView = self.imageView;
    if (!imageView) {
        return nil;
    }
    if (!_imageViewLayer) {
        _imageViewLayer = [CALayer new];
        _imageViewLayer.delegate = self;
        imageView.layer = _imageViewLayer;
        imageView.wantsLayer = YES;
    }
    return _imageViewLayer;
}
#else
// on iOS, it's the imageView itself's layer
- (CALayer *)imageViewLayer {
    return self.layer;
}

#endif


#pragma mark - Util
- (void)calculateMaxBufferCount {
    NSUInteger bytes = CGImageGetBytesPerRow(self.currentFrame.CGImage) * CGImageGetHeight(self.currentFrame.CGImage);
    if (bytes == 0) bytes = 1024;
    
    NSUInteger max = 0;
    if (self.maxBufferSize > 0) {
        max = self.maxBufferSize;
    } else {
        // Calculate based on current memory, these factors are by experience
        NSUInteger total = SDDeviceTotalMemory();
        NSUInteger free = SDDeviceFreeMemory();
        max = MIN(total * 0.2, free * 0.6);
    }
    
    NSUInteger maxBufferCount = (double)max / (double)bytes;
    if (!maxBufferCount) {
        // At least 1 frame
        maxBufferCount = 1;
    }
    
    self.maxBufferCount = maxBufferCount;
}

@end

#if SD_MAC
static CVReturn DisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext) {
    // Calculate refresh duration
    NSTimeInterval duration = (double)inOutputTime->videoRefreshPeriod / ((double)inOutputTime->videoTimeScale * inOutputTime->rateScalar);
    // CVDisplayLink callback is not on main queue
    SDAnimatedImageView *imageView = (__bridge SDAnimatedImageView *)displayLinkContext;
    __weak SDAnimatedImageView *weakImageView = imageView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakImageView displayDidRefresh:displayLink duration:duration];
    });
    return kCVReturnSuccess;
}
#endif

#endif
