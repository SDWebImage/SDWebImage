/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageTestLoader.h"
#import <KVOController/KVOController.h>

@interface NSURLSessionTask (SDWebImageOperation) <SDWebImageOperation>

@end

@implementation SDWebImageTestLoader

+ (SDWebImageTestLoader *)sharedLoader {
    static dispatch_once_t onceToken;
    static SDWebImageTestLoader *loader;
    dispatch_once(&onceToken, ^{
        loader = [[SDWebImageTestLoader alloc] init];
    });
    return loader;
}

- (BOOL)canRequestImageForURL:(NSURL *)url {
    return [self canRequestImageForURL:url options:0 context:nil];
}

- (BOOL)canRequestImageForURL:(NSURL *)url options:(SDWebImageOptions)options context:(SDWebImageContext *)context {
    return YES;
}

- (id<SDWebImageOperation>)requestImageWithURL:(NSURL *)url options:(SDWebImageOptions)options context:(SDWebImageContext *)context progress:(SDImageLoaderProgressBlock)progressBlock completed:(SDImageLoaderCompletedBlock)completedBlock {
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                UIImage *image = SDImageLoaderDecodeImageData(data, url, options, context);
                if (completedBlock) {
                    completedBlock(image, data, nil, YES);
                }
            });
        } else {
            if (completedBlock) {
                completedBlock(nil, nil, error, YES);
            }
        }
    }];
    [self.KVOController observe:task keyPath:NSStringFromSelector(@selector(countOfBytesReceived)) options:NSKeyValueObservingOptionNew block:^(id  _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
        NSURLSessionTask *sessionTask = object;
        NSInteger receivedSize = sessionTask.countOfBytesReceived;
        NSInteger expectedSize = sessionTask.countOfBytesExpectedToReceive;
        if (progressBlock) {
            progressBlock(receivedSize, expectedSize, url);
        }
    }];
    [task resume];
    
    return task;
}

- (BOOL)shouldBlockFailedURLWithURL:(NSURL *)url error:(NSError *)error {
    return [self shouldBlockFailedURLWithURL:url error:error options:0 context:nil];
}

- (BOOL)shouldBlockFailedURLWithURL:(NSURL *)url error:(NSError *)error options:(SDWebImageOptions)options context:(SDWebImageContext *)context {
    return NO;
}

@end
