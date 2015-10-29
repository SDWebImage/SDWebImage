//
//  WebImage.h
//  WebImage
//
//  Created by Florent Vilmart on 2015-03-14.
//  Copyright (c) 2015 Dailymotion. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for WebImage.
FOUNDATION_EXPORT double WebImageVersionNumber;

//! Project version string for WebImage.
FOUNDATION_EXPORT const unsigned char WebImageVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <WebImage/PublicHeader.h>

#import <WebImage/SDWebImageManager.h>
#import <WebImage/SDImageCache.h>
#import <WebImage/UIImageView+WebCache.h>
#import <WebImage/SDWebImageCompat.h>
#import <WebImage/UIImageView+HighlightedWebCache.h>
#import <WebImage/SDWebImageDownloaderOperation.h>
#import <WebImage/UIButton+WebCache.h>
#import <WebImage/SDWebImagePrefetcher.h>
#import <WebImage/UIView+WebCacheOperation.h>
#import <WebImage/UIImage+MultiFormat.h>
#import <WebImage/SDWebImageOperation.h>
#import <WebImage/SDWebImageDownloader.h>
#if !TARGET_OS_TV
#import <WebImage/MKAnnotationView+WebCache.h>
#endif
#import <WebImage/SDWebImageDecoder.h>
#import <WebImage/UIImage+WebP.h>
#import <WebImage/UIImage+GIF.h>
#import <WebImage/NSData+ImageContentType.h>
