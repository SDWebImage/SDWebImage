/*
 * This file is part of the SDWebImageCore package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Florent Vilmart
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <SDWebImageCore/SDWebImageCompat.h>

#if SD_UIKIT
#import <UIKit/UIKit.h>
#endif

//! Project version number for WebImageCore.
FOUNDATION_EXPORT double WebImageCoreVersionNumber;

//! Project version string for WebImageCore.
FOUNDATION_EXPORT const unsigned char WebImageCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WebImageCore/PublicHeader.h>

#import <SDWebImageCore/SDWebImageManager.h>
#import <SDWebImageCore/SDImageCacheConfig.h>
#import <SDWebImageCore/SDImageCache.h>
#import <SDWebImageCore/UIView+WebCache.h>
#import <SDWebImageCore/UIImageView+WebCache.h>
#import <SDWebImageCore/UIImageView+HighlightedWebCache.h>
#import <SDWebImageCore/SDWebImageDownloaderOperation.h>
#import <SDWebImageCore/UIButton+WebCache.h>
#import <SDWebImageCore/SDWebImagePrefetcher.h>
#import <SDWebImageCore/UIView+WebCacheOperation.h>
#import <SDWebImageCore/UIImage+MultiFormat.h>
#import <SDWebImageCore/SDWebImageOperation.h>
#import <SDWebImageCore/SDWebImageDownloader.h>

#import <SDWebImageCore/SDWebImageCodersManager.h>
#import <SDWebImageCore/SDWebImageCoder.h>
#import <SDWebImageCore/SDWebImageGIFCoder.h>
#import <SDWebImageCore/SDWebImageImageIOCoder.h>
#import <SDWebImageCore/SDWebImageFrame.h>
#import <SDWebImageCore/SDWebImageCoderHelper.h>
#import <SDWebImageCore/UIImage+GIF.h>
#import <SDWebImageCore/UIImage+ForceDecode.h>
#import <SDWebImageCore/NSData+ImageContentType.h>

#if SD_MAC
    #import <SDWebImageCore/NSImage+WebCache.h>
#endif
