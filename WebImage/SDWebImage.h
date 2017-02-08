/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Florent Vilmart
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <SDWebImage/SDWebImageCompat.h>

#if SD_UIKIT
#import <UIKit/UIKit.h>
#endif

//! Project version number for WebImage.
FOUNDATION_EXPORT double WebImageVersionNumber;

//! Project version string for WebImage.
FOUNDATION_EXPORT const unsigned char WebImageVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WebImage/PublicHeader.h>

#import <SDWebImage/SDWebImageManager.h>
#import <SDWebImage/SDImageCacheConfig.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIView+WebCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIImageView+HighlightedWebCache.h>
#import <SDWebImage/SDWebImageDownloaderOperation.h>
#import <SDWebImage/UIButton+WebCache.h>
#import <SDWebImage/SDWebImagePrefetcher.h>
#import <SDWebImage/UIView+WebCacheOperation.h>
#import <SDWebImage/UIImage+MultiFormat.h>
#import <SDWebImage/SDWebImageOperation.h>
#import <SDWebImage/SDWebImageDownloader.h>
#if SD_MAC || SD_UIKIT
#import <SDWebImage/MKAnnotationView+WebCache.h>
#endif
#import <SDWebImage/SDWebImageDecoder.h>
#import <SDWebImage/UIImage+WebP.h>
#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/NSData+ImageContentType.h>
#if SD_MAC
#import <SDWebImage/NSImage+WebCache.h>
#endif
#if SD_UIKIT
#import <SDWebImage/FLAnimatedImageView+WebCache.h>
#endif
