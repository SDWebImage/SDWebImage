/*
 * This file is part of the DMWebImage package.
 * (c) Dailymotion - Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import <UIKit/UIKit.h>

@class DMWebImageDownloadOperation;

@interface DMWebImageView : UIImageView
{
    UIImage *placeHolderImage;  
    DMWebImageDownloadOperation *currentOperation;
}

- (void)setImageWithURL:(NSURL *)url;
- (void)downloadFinishedWithImage:(UIImage *)image;

@end

@interface DMWebImageDownloadOperation : NSOperation
{
    NSURL *url;
    DMWebImageView *delegate;
}

@property (retain) NSURL *url;
@property (assign) DMWebImageView *delegate;

- (id)initWithURL:(NSURL *)url delegate:(DMWebImageView *)delegate;

@end
