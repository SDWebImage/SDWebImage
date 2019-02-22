/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCodersManager.h"
#import "SDImageIOCoder.h"
#import "SDImageGIFCoder.h"
#import "SDImageAPNGCoder.h"

@interface SDImageCodersManager ()

@property (nonatomic, strong, nonnull) dispatch_semaphore_t codersLock;

@end

@implementation SDImageCodersManager

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
        NSMutableArray<id<SDImageCoder>> *mutableCoders = [@[[SDImageIOCoder sharedCoder], [SDImageGIFCoder sharedCoder], [SDImageAPNGCoder sharedCoder]] mutableCopy];
        _coders = [mutableCoders copy];
        _codersLock = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Coder IO operations

- (void)addCoder:(nonnull id<SDImageCoder>)coder {
    if (![coder conformsToProtocol:@protocol(SDImageCoder)]) {
        return;
    }
    SD_LOCK(self.codersLock);
    NSMutableArray<id<SDImageCoder>> *mutableCoders = [self.coders mutableCopy];
    if (!mutableCoders) {
        mutableCoders = [NSMutableArray array];
    }
    [mutableCoders addObject:coder];
    self.coders = [mutableCoders copy];
    SD_UNLOCK(self.codersLock);
}

- (void)removeCoder:(nonnull id<SDImageCoder>)coder {
    if (![coder conformsToProtocol:@protocol(SDImageCoder)]) {
        return;
    }
    SD_LOCK(self.codersLock);
    NSMutableArray<id<SDImageCoder>> *mutableCoders = [self.coders mutableCopy];
    [mutableCoders removeObject:coder];
    self.coders = [mutableCoders copy];
    SD_UNLOCK(self.codersLock);
}

#pragma mark - SDImageCoder
- (BOOL)canDecodeFromData:(NSData *)data {
    SD_LOCK(self.codersLock);
    NSArray<id<SDImageCoder>> *coders = self.coders;
    SD_UNLOCK(self.codersLock);
    for (id<SDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canDecodeFromData:data]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canEncodeToFormat:(SDImageFormat)format {
    SD_LOCK(self.codersLock);
    NSArray<id<SDImageCoder>> *coders = self.coders;
    SD_UNLOCK(self.codersLock);
    for (id<SDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return YES;
        }
    }
    return NO;
}

- (UIImage *)decodedImageWithData:(NSData *)data options:(nullable SDImageCoderOptions *)options {
    if (!data) {
        return nil;
    }
    UIImage *image;
    SD_LOCK(self.codersLock);
    NSArray<id<SDImageCoder>> *coders = self.coders;
    SD_UNLOCK(self.codersLock);
    for (id<SDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canDecodeFromData:data]) {
            image = [coder decodedImageWithData:data options:options];
            break;
        }
    }
    
    return image;
}

- (NSData *)encodedDataWithImage:(UIImage *)image format:(SDImageFormat)format options:(nullable SDImageCoderOptions *)options {
    if (!image) {
        return nil;
    }
    SD_LOCK(self.codersLock);
    NSArray<id<SDImageCoder>> *coders = self.coders;
    SD_UNLOCK(self.codersLock);
    for (id<SDImageCoder> coder in coders.reverseObjectEnumerator) {
        if ([coder canEncodeToFormat:format]) {
            return [coder encodedDataWithImage:image format:format options:options];
        }
    }
    return nil;
}

@end
