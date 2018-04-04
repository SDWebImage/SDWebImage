/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTestDownloadOperation.h"

@implementation SDWebImageTestDownloadOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

- (void)start {
    self.finished = NO;
    self.executing = YES;
    // Do nothing but keep running
}

- (void)cancel {
    if (self.isFinished) return;
    [super cancel];
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(SDWebImageDownloaderOptions)options {
    return [self initWithRequest:request inSession:session options:options context:nil];
}

- (instancetype)initWithRequest:(NSURLRequest *)request inSession:(NSURLSession *)session options:(SDWebImageDownloaderOptions)options context:(SDWebImageContext *)context {
    self = [super init];
    if (self) {
        self.request = request;
    }
    return self;
}

- (nullable id)addHandlersForProgress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                            completed:(nullable SDWebImageDownloaderCompletedBlock)completedBlock {
    return NSStringFromClass([self class]);
}

- (BOOL)cancel:(id)token {
    [self cancel];
    return YES;
}

@end
