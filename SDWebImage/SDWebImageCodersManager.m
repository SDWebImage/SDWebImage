/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCodersManager.h"
#import "SDWebImageImageIOCoder.h"
#import "SDWebImageGIFCoder.h"
#ifdef SD_WEBP
#import "SDWebImageWebPCoder.h"
#endif
#import "NSImage+Additions.h"
#import "UIImage+WebCache.h"

@interface SDWebImageCodersManager ()

@property (strong, nonatomic, nonnull) NSMutableArray<SDWebImageCoder>* mutableCoders;
@property (strong, nonatomic, nullable) dispatch_queue_t mutableCodersAccessQueue;

@end

@implementation SDWebImageCodersManager

+ (nonnull instancetype)sharedManager {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // initialize with default coders
        _mutableCoders = [@[[SDWebImageImageIOCoder sharedCoder], [SDWebImageGIFCoder sharedCoder]] mutableCopy];
#ifdef SD_WEBP
        [_mutableCoders addObject:[SDWebImageWebPCoder sharedCoder]];
#endif
        _mutableCodersAccessQueue = dispatch_queue_create("com.hackemist.SDWebImageCodersManager", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

#pragma mark - Coder IO operations

- (void)addCoder:(nonnull id<SDWebImageCoder>)coder {
    if ([coder conformsToProtocol:@protocol(SDWebImageCoder)]) {
        dispatch_barrier_sync(self.mutableCodersAccessQueue, ^{
            [self.mutableCoders addObject:coder];
        });
    }
}

- (void)removeCoder:(nonnull id<SDWebImageCoder>)coder {
    dispatch_barrier_sync(self.mutableCodersAccessQueue, ^{
        [self.mutableCoders removeObject:coder];
    });
}

- (NSArray<id<SDWebImageCoder>> *)coders {
    __block NSArray<id<SDWebImageCoder>> *sortedCoders = nil;
    dispatch_sync(self.mutableCodersAccessQueue, ^{
        sortedCoders = (NSArray<id<SDWebImageCoder>> *)[[[self.mutableCoders copy] reverseObjectEnumerator] allObjects];
    });
    return sortedCoders;
}

- (void)setCoders:(NSArray<id<SDWebImageCoder>> *)coders {
    dispatch_barrier_sync(self.mutableCodersAccessQueue, ^{
        self.mutableCoders = [coders mutableCopy];
    });
}

#pragma mark - SDWebImageCoder
- (BOOL)canDecodeFromData:(NSData *)data {
    for (id<SDWebImageCoder> coder in self.coders) {
        if ([coder canDecodeFromData:data]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    for (id<SDWebImageCoder> coder in self.coders) {
        if ([coder canEncodeToFormat:format]) {
            return YES;
        }
    }
    return NO;
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable SDWebImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    BOOL decodeFirstFrame = [[options valueForKey:SDWebImageCoderDecodeFirstFrameOnly] boolValue];
    UIImage *image;
    for (id<SDWebImageCoder> coder in self.coders) {
        if ([coder canDecodeFromData:data]) {
            image = [coder decodedImageWithData:data options:options];
            break;
        }
    }
    if (decodeFirstFrame && image.images.count > 0) {
        image = image.images.firstObject;
    }
    
    return image;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(nullable SDWebImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    for (id<SDWebImageCoder> coder in self.coders) {
        if ([coder canEncodeToFormat:format]) {
            return [coder encodedDataWithImage:image format:format options:nil];
        }
    }
    return nil;
}

@end
