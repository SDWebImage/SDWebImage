/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */ 

#import "UIImageView+WebCache.h"
#import "UIImageViewHelper.h"

@implementation UIImageView (WebCache)

- (void)setImageWithURL:(NSURL *)url
{
    UIImageViewHelper *helper = nil;

    if ([self.subviews count] > 0)
    {
        helper = [self.subviews objectAtIndex:0];
    }

    if (helper == nil)
    {
        helper = [[[UIImageViewHelper alloc] initWithDelegate:self] autorelease];
        [self addSubview:helper];
    }

    // Remove in progress downloader from queue
    [helper cancel];
    
    // Save the placeholder image in order to re-apply it when view is reused
    if (helper.placeHolderImage == nil)
    {
        helper.placeHolderImage = self.image;
    }
    else
    {
        self.image = helper.placeHolderImage;
    }
    
    UIImage *cachedImage = [helper imageWithURL:url];
    
    if (cachedImage)
    {
        self.image = cachedImage;
    }
    else
    {
        [helper downloadWithURL:url];
    }
}

@end