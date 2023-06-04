/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

#import "SDImageFramePool.h"
#import "SDInternalMacros.h"
#import "objc/runtime.h"

@interface SDImageFramePool ()

@property (class, readonly) NSMapTable *providerFramePoolMap;

@property (weak) id<SDAnimatedImageProvider> provider;
@property (atomic) NSUInteger registerCount;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, UIImage *> *frameBuffer;
@property (nonatomic, strong) NSOperationQueue *fetchQueue;

@end

// Lock to ensure atomic behavior
SD_LOCK_DECLARE_STATIC(_providerFramePoolMapLock);

@implementation SDImageFramePool

+ (NSMapTable *)providerFramePoolMap {
    static NSMapTable *providerFramePoolMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        providerFramePoolMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality valueOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality];
    });
    return providerFramePoolMap;
}

#pragma mark - Life Cycle
- (instancetype)init {
    self = [super init];
    if (self) {
        _frameBuffer = [NSMutableDictionary dictionary];
        _fetchQueue = [[NSOperationQueue alloc] init];
        _fetchQueue.maxConcurrentOperationCount = 1;
        _fetchQueue.name = @"com.hackemist.SDImageFramePool.fetchQueue";
#if SD_UIKIT
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (void)dealloc {
#if SD_UIKIT
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self removeAllFrames];
}

+ (void)initialize {
    // Lock to ensure atomic behavior
    SD_LOCK_INIT(_providerFramePoolMapLock);
}

+ (instancetype)registerProvider:(id<SDAnimatedImageProvider>)provider {
    // Lock to ensure atomic behavior
    SD_LOCK(_providerFramePoolMapLock);
    SDImageFramePool *framePool = [self.providerFramePoolMap objectForKey:provider];
    if (!framePool) {
        framePool = [[SDImageFramePool alloc] init];
        framePool.provider = provider;
        [self.providerFramePoolMap setObject:framePool forKey:provider];
    }
    framePool.registerCount += 1;
    SD_UNLOCK(_providerFramePoolMapLock);
    return framePool;
}

+ (void)unregisterProvider:(id<SDAnimatedImageProvider>)provider {
    // Lock to ensure atomic behavior
    SD_LOCK(_providerFramePoolMapLock);
    SDImageFramePool *framePool = [self.providerFramePoolMap objectForKey:provider];
    if (!framePool) {
        SD_UNLOCK(_providerFramePoolMapLock);
        return;
    }
    framePool.registerCount -= 1;
    if (framePool.registerCount == 0) {
        [self.providerFramePoolMap removeObjectForKey:provider];
    }
    SD_UNLOCK(_providerFramePoolMapLock);
}

- (void)prefetchFrameAtIndex:(NSUInteger)index {
    @synchronized (self) {
        NSUInteger frameCount = self.frameBuffer.count;
        if (frameCount > self.maxBufferCount) {
            // Remove the frame buffer if need
            // TODO, use LRU or better algorithm to detect which frames to clear
            self.frameBuffer[@(index - 1)] = nil;
            self.frameBuffer[@(index + 1)] = nil;
        }
    }
    
    if (self.fetchQueue.operationCount == 0) {
        // Prefetch next frame in background queue
        id<SDAnimatedImageProvider> animatedProvider = self.provider;
        @weakify(self);
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            @strongify(self);
            if (!self) {
                return;
            }
            UIImage *frame = [animatedProvider animatedImageFrameAtIndex:index];
            
            [self setFrame:frame atIndex:index];
        }];
        [self.fetchQueue addOperation:operation];
    }
}

- (void)setMaxConcurrentCount:(NSUInteger)maxConcurrentCount {
    self.fetchQueue.maxConcurrentOperationCount = maxConcurrentCount;
}

- (NSUInteger)currentFrameCount {
    NSUInteger frameCount = 0;
    @synchronized (self) {
        frameCount = self.frameBuffer.count;
    }
    return frameCount;
}

- (void)setFrame:(UIImage *)frame atIndex:(NSUInteger)index {
    @synchronized (self) {
        self.frameBuffer[@(index)] = frame;
    }
}

- (UIImage *)frameAtIndex:(NSUInteger)index {
    UIImage *frame;
    @synchronized (self) {
        frame = self.frameBuffer[@(index)];
    }
    return frame;
}

- (void)removeFrameAtIndex:(NSUInteger)index {
    @synchronized (self) {
        self.frameBuffer[@(index)] = nil;
    }
}

- (void)removeAllFrames {
    @synchronized (self) {
        [self.frameBuffer removeAllObjects];
    }
}

@end
