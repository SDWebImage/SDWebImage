//
//  DMWebImageView.h
//  Dailymotion
//
//  Created by Olivier Poitrey on 18/09/09.
//  Copyright 2009 Dailymotion. All rights reserved.
//

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