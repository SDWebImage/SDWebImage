/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageLoader.h"

@interface SDImageLoadersManager : NSObject <SDImageLoader>

@property (nonatomic, class, readonly, nonnull) SDImageLoadersManager *sharedManager;

/**
 All image loaders in manager. The loaders array is a priority queue, which means the later added loader will have the highest priority
 */
@property (nonatomic, copy, readwrite, nullable) NSArray<id<SDImageLoader>>* loaders;

/**
 Add a new image loader to the end of loaders array. Which has the highest priority.
 
 @param loader loader
 */
- (void)addLoader:(nonnull id<SDImageLoader>)loader;

/**
 Remove a image loader in the loaders array.
 
 @param loader loader
 */
- (void)removeLoader:(nonnull id<SDImageLoader>)loader;

@end
