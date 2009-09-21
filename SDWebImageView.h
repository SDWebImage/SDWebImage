/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import <UIKit/UIKit.h>

@class SDWebImageDownloader;

@interface SDWebImageView : UIImageView
{
    UIImage *placeHolderImage;  
    SDWebImageDownloader *downloader;
}

- (void)setImageWithURL:(NSURL *)url;
- (void)downloadFinishedWithImage:(UIImage *)image;

@end