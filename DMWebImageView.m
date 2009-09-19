//
//  DMWebImageView.m
//  Dailymotion
//
//  Created by Olivier Poitrey on 18/09/09.
//  Copyright 2009 Dailymotion. All rights reserved.
//

#import "DMWebImageView.h"
#import "DMImageCache.h"

static NSOperationQueue *downloadQueue;
static NSOperationQueue *cacheInQueue;

@implementation DMWebImageView

- (void)dealloc
{
    [placeHolderImage release];
    [currentOperation release];
    [super dealloc];
}

#pragma mark RemoteImageView

- (void)setImageWithURL:(NSURL *)url
{
    if (currentOperation != nil)
    {
        [currentOperation cancel]; // remove from queue
        [currentOperation release];
        currentOperation = nil;
    }

    // Save the placeholder image in order to re-apply it when view is reused
    if (placeHolderImage == nil)
    {
        placeHolderImage = [self.image retain];
    }
    else
    {
        self.image = placeHolderImage;
    }

    UIImage *cachedImage = [[DMImageCache sharedImageCache] imageFromKey:[url absoluteString]];

    if (cachedImage)
    {
        self.image = cachedImage;
    }
    else
    {
        if (downloadQueue == nil)
        {
            downloadQueue = [[NSOperationQueue alloc] init];
            [downloadQueue setMaxConcurrentOperationCount:8];
        }
        
        currentOperation = [[DMWebImageDownloadOperation alloc] initWithURL:url delegate:self];
        [downloadQueue addOperation:currentOperation];
    }
}

- (void)downloadFinishedWithImage:(UIImage *)anImage
{
    self.image = anImage;
    [currentOperation release];
    currentOperation = nil;
}

@end

@implementation DMWebImageDownloadOperation

@synthesize url, delegate;

- (void)dealloc
{
    [url release];
    [super dealloc];
}


- (id)initWithURL:(NSURL *)anUrl delegate:(DMWebImageView *)aDelegate
{
    if (self = [super init])
    {
        self.url = anUrl;
        self.delegate = aDelegate;
    }

    return self;
}

- (void)main 
{
    if (self.isCancelled)
    {
        return;
    }
    
    NSData *data = [[NSData alloc] initWithContentsOfURL:url];
    UIImage *image = [[UIImage alloc] initWithData:data];
    [data release];
    
    if (!self.isCancelled)
    {
        [delegate performSelectorOnMainThread:@selector(downloadFinishedWithImage:) withObject:image waitUntilDone:YES];
    }

    if (cacheInQueue == nil)
    {
        cacheInQueue = [[NSOperationQueue alloc] init];
        [cacheInQueue setMaxConcurrentOperationCount:2];
    }

    NSString *cacheKey = [url absoluteString];

    DMImageCache *imageCache = [DMImageCache sharedImageCache];

    // Store image in memory cache NOW, no need to wait for the cache-in operation queue completion
    [imageCache storeImage:image forKey:cacheKey toDisk:NO];

    // Perform the cache-in in another operation queue in order to not block a download operation slot
    NSInvocation *cacheInInvocation = [NSInvocation invocationWithMethodSignature:[[imageCache class] instanceMethodSignatureForSelector:@selector(storeImage:forKey:)]];
    [cacheInInvocation setTarget:imageCache];
    [cacheInInvocation setSelector:@selector(storeImage:forKey:)];
    [cacheInInvocation setArgument:&image atIndex:2];
    [cacheInInvocation setArgument:&cacheKey atIndex:3];
    [cacheInInvocation retainArguments];
    NSInvocationOperation *cacheInOperation = [[NSInvocationOperation alloc] initWithInvocation:cacheInInvocation];
    [cacheInQueue addOperation:cacheInOperation];
    [cacheInOperation release];
    
    [image release];
}

@end