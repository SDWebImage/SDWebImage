//
//  SDWebImage.h
//  SDWebImage iOS static
//
//  Created by Kenny Ackerson on 10/30/17.
//  Copyright © 2017 Dailymotion. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SDWebPImage : NSObject

- (nonnull instancetype)initWithImages:(nonnull NSArray <UIImage *> *)images durations:(nonnull NSArray <NSNumber *> *)durations loopCount:(NSInteger)loopCount;

@property (nonatomic, nonnull, readonly) NSArray <UIImage *> *images;

@property (nonatomic, nonnull, readonly) NSArray <NSNumber *> *durations;

@property (nonatomic, readonly) NSInteger loopCount;

@end
