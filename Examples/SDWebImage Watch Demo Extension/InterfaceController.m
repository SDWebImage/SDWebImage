/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "InterfaceController.h"
#import <SDWebImage/UIImageView+WebCache.h>


@interface InterfaceController()

@property (weak) IBOutlet WKInterfaceImage *imageInterface;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    NSString *urlString = @"https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png";
    WKInterfaceImage *imageInterface = self.imageInterface;
    [imageInterface sd_setImageWithURL:[NSURL URLWithString:urlString]];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



