//
//  SDWebImageLocalAssetOperation.h
//  SDWebImage
//
//  Created by Don Holly on 10/7/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDWebImageDownloader.h"
#import "SDWebImageOperation.h"

@interface SDWebImageLocalAssetOperation : NSOperation <SDWebImageOperation>

@property (strong, nonatomic, readonly) NSURL *localAssetURL;
@property (assign, nonatomic, readonly) SDWebImageDownloaderOptions options;

- (id)initWithLocalAssetURL:(NSURL *)localAssetURL
                    options:(SDWebImageDownloaderOptions)options
                  completed:(SDWebImageDownloaderCompletedBlock)completedBlock
                  cancelled:(void (^)())cancelBlock;

@end
