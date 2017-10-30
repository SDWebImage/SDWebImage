//
//  SDWebImage.m
//  SDWebImage iOS static
//
//  Created by Kenny Ackerson on 10/30/17.
//  Copyright © 2017 Dailymotion. All rights reserved.
//

#import "SDWebPImage.h"

@implementation SDWebPImage

- (nonnull instancetype)initWithImages:(nonnull NSArray <UIImage *> *)images durations:(nonnull NSArray <NSNumber *> *)durations loopCount:(NSInteger)loopCount {
    NSParameterAssert(images);
    NSParameterAssert(durations);
    NSParameterAssert(loopCount);
    self = [super init];

    if (self) {
        _images = images;
        _durations = durations;
        _loopCount = loopCount;
    }

    return self;
}
@end
