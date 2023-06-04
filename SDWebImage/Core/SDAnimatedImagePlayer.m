/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDAnimatedImagePlayer.h"
#import "NSImage+Compatibility.h"
#import "SDDisplayLink.h"
#import "SDDeviceHelper.h"
#import "SDImageFramePool.h"
#import "SDInternalMacros.h"

@interface SDAnimatedImagePlayer () {
    NSRunLoopMode _runLoopMode;
}

@property (nonatomic, strong) SDImageFramePool *framePool;

@property (nonatomic, strong, readwrite) UIImage *currentFrame;
@property (nonatomic, assign, readwrite) NSUInteger currentFrameIndex;
@property (nonatomic, assign, readwrite) NSUInteger currentLoopCount;
@property (nonatomic, strong) id<SDAnimatedImageProvider> animatedProvider;
@property (nonatomic, assign) NSUInteger currentFrameBytes;
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, assign) BOOL bufferMiss;
@property (nonatomic, assign) BOOL needsDisplayWhenImageBecomesAvailable;
@property (nonatomic, assign) BOOL shouldReverse;
@property (nonatomic, strong) SDDisplayLink *displayLink;

@end

@implementation SDAnimatedImagePlayer

- (instancetype)initWithProvider:(id<SDAnimatedImageProvider>)provider {
    self = [super init];
    if (self) {
        NSUInteger animatedImageFrameCount = provider.animatedImageFrameCount;
        // Check the frame count
        if (animatedImageFrameCount <= 1) {
            return nil;
        }
        self.totalFrameCount = animatedImageFrameCount;
        // Get the current frame and loop count.
        self.totalLoopCount = provider.animatedImageLoopCount;
        self.animatedProvider = provider;
        self.playbackRate = 1.0;
        self.framePool = [SDImageFramePool registerProvider:provider];
    }
    return self;
}

+ (instancetype)playerWithProvider:(id<SDAnimatedImageProvider>)provider {
    SDAnimatedImagePlayer *player = [[SDAnimatedImagePlayer alloc] initWithProvider:provider];
    return player;
}

- (void)dealloc {
    // Dereference the frame pool, when zero the frame pool for provider will dealloc
    [SDImageFramePool unregisterProvider:self.animatedProvider];
}

#pragma mark - Private

- (SDDisplayLink *)displayLink {
    if (!_displayLink) {
        _displayLink = [SDDisplayLink displayLinkWithTarget:self selector:@selector(displayDidRefresh:)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.runLoopMode];
        [_displayLink stop];
    }
    return _displayLink;
}

- (void)setRunLoopMode:(NSRunLoopMode)runLoopMode {
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

- (NSRunLoopMode)runLoopMode {
    if (!_runLoopMode) {
        _runLoopMode = [[self class] defaultRunLoopMode];
    }
    return _runLoopMode;
}

#pragma mark - State Control

- (void)setupCurrentFrame {
    if (self.currentFrameIndex != 0) {
        return;
    }
    if (self.playbackMode == SDAnimatedImagePlaybackModeReverse ||
               self.playbackMode == SDAnimatedImagePlaybackModeReversedBounce) {
        self.currentFrameIndex = self.totalFrameCount - 1;
    }
    
    if (!self.currentFrame && [self.animatedProvider isKindOfClass:[UIImage class]]) {
        UIImage *image = (UIImage *)self.animatedProvider;
        // Cache the poster image if available, but should not callback to avoid caller thread issues
        #if SD_MAC
        UIImage *posterFrame = [[NSImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:kCGImagePropertyOrientationUp];
        #else
        UIImage *posterFrame = [[UIImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:image.imageOrientation];
        #endif
        if (posterFrame) {
            // Calculate max buffer size
            [self calculateMaxBufferCountWithFrame:posterFrame];
            // HACK: The first frame should not check duration and immediately display
            self.needsDisplayWhenImageBecomesAvailable = YES;
            [self.framePool setFrame:posterFrame atIndex:self.currentFrameIndex];
        }
    }
    
}

- (void)resetCurrentFrameStatus {
    // These should not trigger KVO, user don't need to receive an `index == 0, image == nil` callback.
    _currentFrame = nil;
    _currentFrameIndex = 0;
    _currentLoopCount = 0;
    _currentTime = 0;
    _bufferMiss = NO;
    _needsDisplayWhenImageBecomesAvailable = NO;
}

- (void)clearFrameBuffer {
    [self.framePool removeAllFrames];
}

#pragma mark - Animation Control
- (void)startPlaying {
    [self.displayLink start];
    // Setup frame
    [self setupCurrentFrame];
}

- (void)stopPlaying {
    // Using `_displayLink` here because when UIImageView dealloc, it may trigger `[self stopAnimating]`, we already release the display link in SDAnimatedImageView's dealloc method.
    [_displayLink stop];
    // We need to reset the frame status, but not trigger any handle. This can ensure next time's playing status correct.
    [self resetCurrentFrameStatus];
}

- (void)pausePlaying {
    [_displayLink stop];
}

- (BOOL)isPlaying {
    return _displayLink.isRunning;
}

- (void)seekToFrameAtIndex:(NSUInteger)index loopCount:(NSUInteger)loopCount {
    if (index >= self.totalFrameCount) {
        return;
    }
    self.currentFrameIndex = index;
    self.currentLoopCount = loopCount;
    self.currentFrame = [self.animatedProvider animatedImageFrameAtIndex:index];
    [self handleFrameChange];
}

#pragma mark - Core Render
- (void)displayDidRefresh:(SDDisplayLink *)displayLink {
    // If for some reason a wild call makes it through when we shouldn't be animating, bail.
    // Early return!
    if (!self.isPlaying) {
        return;
    }
    
    NSUInteger totalFrameCount = self.totalFrameCount;
    if (totalFrameCount <= 1) {
        // Total frame count less than 1, wrong configuration and stop animating
        [self stopPlaying];
        return;
    }
    
    NSTimeInterval playbackRate = self.playbackRate;
    if (playbackRate <= 0) {
        // Does not support <= 0 play rate
        [self stopPlaying];
        return;
    }
    
    // Calculate refresh duration
    NSTimeInterval duration = self.displayLink.duration;
    
    NSUInteger currentFrameIndex = self.currentFrameIndex;
    NSUInteger nextFrameIndex = (currentFrameIndex + 1) % totalFrameCount;
    
    if (self.playbackMode == SDAnimatedImagePlaybackModeReverse) {
        nextFrameIndex = currentFrameIndex == 0 ? (totalFrameCount - 1) : (currentFrameIndex - 1) % totalFrameCount;
        
    } else if (self.playbackMode == SDAnimatedImagePlaybackModeBounce ||
               self.playbackMode == SDAnimatedImagePlaybackModeReversedBounce) {
        if (currentFrameIndex == 0) {
            self.shouldReverse = NO;
        } else if (currentFrameIndex == totalFrameCount - 1) {
            self.shouldReverse = YES;
        }
        nextFrameIndex = self.shouldReverse ? (currentFrameIndex - 1) : (currentFrameIndex + 1);
        nextFrameIndex %= totalFrameCount;
    }
    
    
    // Check if we need to display new frame firstly
    if (self.needsDisplayWhenImageBecomesAvailable) {
        UIImage *currentFrame = [self.framePool frameAtIndex:currentFrameIndex];
        
        // Update the current frame
        if (currentFrame) {
            // Update the current frame immediately
            self.currentFrame = currentFrame;
            [self handleFrameChange];
            
            self.bufferMiss = NO;
            self.needsDisplayWhenImageBecomesAvailable = NO;
        }
        else {
            self.bufferMiss = YES;
        }
    }
    
    // Check if we have the frame buffer
    if (!self.bufferMiss) {
        // Then check if timestamp is reached
        self.currentTime += duration;
        NSTimeInterval currentDuration = [self.animatedProvider animatedImageDurationAtIndex:currentFrameIndex];
        currentDuration = currentDuration / playbackRate;
        if (self.currentTime < currentDuration) {
            // Current frame timestamp not reached, prefetch frame in advance.
            [self prefetchFrameAtIndex:currentFrameIndex
                             nextIndex:nextFrameIndex];
            return;
        }
        
        // Otherwise, we should be ready to display next frame
        self.needsDisplayWhenImageBecomesAvailable = YES;
        self.currentFrameIndex = nextFrameIndex;
        self.currentTime -= currentDuration;
        NSTimeInterval nextDuration = [self.animatedProvider animatedImageDurationAtIndex:nextFrameIndex];
        nextDuration = nextDuration / playbackRate;
        if (self.currentTime > nextDuration) {
            // Do not skip frame
            self.currentTime = nextDuration;
        }
        
        // Update the loop count when last frame rendered
        if (nextFrameIndex == 0) {
            // Update the loop count
            self.currentLoopCount++;
            [self handleLoopChange];
            
            // if reached the max loop count, stop animating, 0 means loop indefinitely
            NSUInteger maxLoopCount = self.totalLoopCount;
            if (maxLoopCount != 0 && (self.currentLoopCount >= maxLoopCount)) {
                [self stopPlaying];
                return;
            }
        }
    }
    
    // Since we support handler, check animating state again
    if (!self.isPlaying) {
        return;
    }
    
    [self prefetchFrameAtIndex:currentFrameIndex
                     nextIndex:nextFrameIndex];
}

// Check if we should prefetch next frame or current frame
// When buffer miss, means the decode speed is slower than render speed, we fetch current miss frame
// Or, most cases, the decode speed is faster than render speed, we fetch next frame
- (void)prefetchFrameAtIndex:(NSUInteger)currentIndex
                   nextIndex:(NSUInteger)nextIndex {
    NSUInteger fetchFrameIndex = currentIndex;
    UIImage *fetchFrame = nil;
    if (!self.bufferMiss) {
        fetchFrameIndex = nextIndex;
        fetchFrame = [self.framePool frameAtIndex:nextIndex];
    }
    BOOL bufferFull = NO;
    if (self.framePool.currentFrameCount == self.totalFrameCount) {
        bufferFull = YES;
    }
    if (!fetchFrame && !bufferFull) {
        // Calculate max buffer size
        [self calculateMaxBufferCountWithFrame:self.currentFrame];
        // Prefetch next frame
        [self.framePool prefetchFrameAtIndex:fetchFrameIndex];
    }
}

- (void)handleFrameChange {
    if (self.animationFrameHandler) {
        self.animationFrameHandler(self.currentFrameIndex, self.currentFrame);
    }
}

- (void)handleLoopChange {
    if (self.animationLoopHandler) {
        self.animationLoopHandler(self.currentLoopCount);
    }
}

#pragma mark - Util
- (void)calculateMaxBufferCountWithFrame:(nonnull UIImage *)frame {
    NSUInteger bytes = self.currentFrameBytes;
    if (bytes == 0) {
        bytes = CGImageGetBytesPerRow(frame.CGImage) * CGImageGetHeight(frame.CGImage);
        if (bytes == 0) {
            bytes = 1024;
        } else {
            // Cache since most animated image each frame bytes is the same
            self.currentFrameBytes = bytes;
        }
    }
    
    NSUInteger max = 0;
    if (self.maxBufferSize > 0) {
        max = self.maxBufferSize;
    } else {
        // Calculate based on current memory, these factors are by experience
        NSUInteger total = [SDDeviceHelper totalMemory];
        NSUInteger free = [SDDeviceHelper freeMemory];
        max = MIN(total * 0.2, free * 0.6);
    }
    
    NSUInteger maxBufferCount = (double)max / (double)bytes;
    if (!maxBufferCount) {
        // At least 1 frame
        maxBufferCount = 1;
    }
    
    self.framePool.maxBufferCount = maxBufferCount;
}

+ (NSString *)defaultRunLoopMode {
    // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
    return [NSProcessInfo processInfo].activeProcessorCount > 1 ? NSRunLoopCommonModes : NSDefaultRunLoopMode;
}

@end
