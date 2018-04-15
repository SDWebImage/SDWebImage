/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageLoader.h"

@interface SDWebImageLoadersManager : NSObject <SDWebImageLoader>

@property (nonatomic, class, readonly, nonnull) SDWebImageLoadersManager *sharedManager;

/**
 All image loaders in manager. The loaders array is a priority queue, which means the later added loader will have the highest priority
 */
@property (nonatomic, strong, readwrite, nullable) NSArray<id<SDWebImageLoader>>* loaders;

/**
 Add a new image loader to the end of loaders array. Which has the highest priority.
 
 @param loader loader
 */
- (void)addLoader:(nonnull id<SDWebImageLoader>)loader;

/**
 Remove a image loader in the loaders array.
 
 @param loader loader
 */
- (void)removeLoader:(nonnull id<SDWebImageLoader>)loader;

@end
