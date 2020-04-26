/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Matt Galloway
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import <SDWebImage/SDImageLoader.h>

// A really naive implementation of custom image loader using `NSURLSession`
@interface SDWebImageTestLoader : NSObject <SDImageLoader>

@property (nonatomic, class, readonly, nonnull) SDWebImageTestLoader *sharedLoader;

@end
