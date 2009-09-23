/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import <UIKit/UIKit.h>
#import "SDWebImageDownloader.h"

@interface UIImageViewHelper : UIView
{
    UIImageView *delegate;
    SDWebImageDownloader *downloader;
    UIImage *placeHolderImage;
}

@property (nonatomic, retain) UIImage *placeHolderImage;

- (id)initWithDelegate:(UIImageView *)aDelegate;
- (UIImage *)imageWithURL:(NSURL *)url;
- (void)downloadWithURL:(NSURL *)url;
- (void)cancel;

@end
