//
//  SDWebImageLocalAssetOperation.m
//  SDWebImage
//
//  Created by Don Holly on 10/7/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import "SDWebImageManager.h"
#import "SDWebImageLocalAssetOperation.h"
#import "SDWebImageDecoder.h"
#import "UIImage+MultiFormat.h"
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>

//static ALAssetsLibrary *_localAssetsLibrary;
static NSMutableDictionary *_localAssetURLToAssetCache;

@interface SDWebImageLocalAssetOperation ()

@property (copy, nonatomic) SDWebImageDownloaderCompletedBlock completedBlock;
@property (copy, nonatomic) void (^cancelBlock)();

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

@end

@implementation SDWebImageLocalAssetOperation
{
    ALAssetsLibrary *_localAssetsLibrary;
    BOOL _retrievingImage;
}

- (id)initWithLocalAssetURL:(NSURL *)localAssetURL options:(SDWebImageDownloaderOptions)options completed:(SDWebImageDownloaderCompletedBlock)completedBlock cancelled:(void (^)())cancelBlock
{
    
    if ((self = [super init])) {
        _localAssetURL = localAssetURL;
        _options = options;
        _completedBlock = [completedBlock copy];
        _cancelBlock = [cancelBlock copy];
        _executing = NO;
        _finished = NO;
        _retrievingImage = NO;
    }
    
    return self;
}

- (void)start
{
    if (self.isCancelled)
    {
        self.finished = YES;
        [self reset];
        return;
    }
    
    self.executing = YES;
  
    if (!_localAssetsLibrary)
    {
        _localAssetsLibrary = [[ALAssetsLibrary alloc] init];
        _localAssetURLToAssetCache = [NSMutableDictionary dictionary];
    }
    
    if (_localAssetsLibrary)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStartNotification object:self];
        
        _retrievingImage = YES;
        UIImage *image = [self localAssetWithURL:self.localAssetURL options:self.options];
        _retrievingImage = NO;
        
        if (image)
        {
            [self completeWithImage:image];
        }
        else
        {
            if (self.completedBlock)
            {
                self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"ALAsset not found for given URL."}], YES);
            }
            self.completionBlock = nil;
            [self done];
        }
        
    }
    else
    {
        if (self.completedBlock)
        {
            self.completedBlock(nil, nil, [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"ALAssetsLibrary was not initialized."}], YES);
        }
    }
}

- (NSString *)keyForLocalAssetURL
{
    NSString *key = self.localAssetURL.absoluteString;
    
    if (self.options & SDWebImageLocalAssetSizeThumnailSquare)
    {
        key = [key stringByAppendingString:@"thumb_square"];
    }
    else if (self.options & SDWebImageLocalAssetSizeFullscreenAspect)
    {
        key = [key stringByAppendingString:@"fullscreen_aspect"];
    }
    else if (self.options & SDWebImageLocalAssetSizeOriginal)
    {
        key = [key stringByAppendingString:@"original"];
    }
    else
    {
        key = [key stringByAppendingString:@"thumb_aspect"];
    }
    
    return key;
}

- (void)completeWithImage:(UIImage *)image
{
    CFRunLoopStop(CFRunLoopGetCurrent());
    [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:nil];
    
    image = SDScaledImageForKey([self keyForLocalAssetURL], image);
    
    SDWebImageDownloaderCompletedBlock completionBlock = self.completedBlock;
    
    if (!image.images) // Do not force decod animated GIFs
    {
        image = [UIImage decodedImageWithImage:image];
    }
    
    if (CGSizeEqualToSize(image.size, CGSizeZero))
    {
        if (completionBlock)
        {
            completionBlock(nil, nil, [NSError errorWithDomain:@"SDWebImageErrorDomain" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Local asset has 0 pixels"}], YES);
        }
    }
    else
    {
        if (completionBlock)
        {
            completionBlock(image, nil, nil, YES);
        }
    }
    self.completionBlock = nil;
    [self done];
}

- (void)cancel
{
    if (self.isFinished) return;
    [super cancel];
    if (self.cancelBlock) self.cancelBlock();
    
    if (_retrievingImage)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:SDWebImageDownloadStopNotification object:self];
        
        // As we cancelled the connection, its callback won't be called and thus won't
        // maintain the isFinished and isExecuting flags.
        if (self.isExecuting) self.executing = NO;
        if (!self.isFinished) self.finished = YES;
    }
    
    [self reset];
}

- (void)done
{
    self.finished = YES;
    self.executing = NO;
    [self reset];
}

- (void)reset
{
    self.cancelBlock = nil;
    self.completedBlock = nil;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isConcurrent
{
    return NO;
}

- (UIImage *)localAssetWithURL:(NSURL*)url options:(SDWebImageOptions)options
{
    __block UIImage *returnImage;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    
    dispatch_async(queue, ^
    {
       [_localAssetsLibrary assetForURL:url resultBlock:^(ALAsset *asset)
        {
            @autoreleasepool
            {
                if (asset)
                {
                    ALAssetRepresentation *assetRepresentation = asset.defaultRepresentation;
                    
                    if (options & SDWebImageLocalAssetSizeThumnailSquare)
                    {
                        returnImage = [UIImage imageWithCGImage:asset.thumbnail];
                    }
                    else if (options & SDWebImageLocalAssetSizeFullscreenAspect)
                    {
                        returnImage = [UIImage imageWithCGImage:assetRepresentation.fullScreenImage];
                    }
                    else if (options & SDWebImageLocalAssetSizeOriginal)
                    {
                        returnImage = [UIImage imageWithCGImage:assetRepresentation.fullResolutionImage];
                    }
                    else
                    {
                        returnImage = [UIImage imageWithCGImage:asset.aspectRatioThumbnail];
                    }
                }
            }
            dispatch_semaphore_signal(sema);
        }
        failureBlock:^(NSError *error)
        {
            NSLog(@"Error getting image: %@", error);
            dispatch_semaphore_signal(sema);
        }];
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    return returnImage;
}

@end
