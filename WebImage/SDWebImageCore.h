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

//! Project version number for WebImageCore.
FOUNDATION_EXPORT double WebImageCoreVersionNumber;

//! Project version string for WebImageCore.
FOUNDATION_EXPORT const unsigned char WebImageCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WebImageCore/PublicHeader.h>

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

#import <SDWebImage/SDWebImageCodersManager.h>
#import <SDWebImage/SDWebImageCoder.h>
#import <SDWebImage/SDWebImageGIFCoder.h>
#import <SDWebImage/SDWebImageImageIOCoder.h>
#import <SDWebImage/UIImage+GIF.h>
#import <SDWebImage/UIImage+ForceDecode.h>
#import <SDWebImage/NSData+ImageContentType.h>

#if SD_MAC
    #import <SDWebImage/NSImage+WebCache.h>
#endif
