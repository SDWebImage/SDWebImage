/*
 * This file is part of the DMWebImage package.
 * (c) Dailymotion - Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import <UIKit/UIKit.h>

@class DMWebImageDownloader;

@interface DMWebImageView : UIImageView
{
    UIImage *placeHolderImage;  
    DMWebImageDownloader *downloader;
}

- (void)setImageWithURL:(NSURL *)url;
- (void)downloadFinishedWithImage:(UIImage *)image;

@end