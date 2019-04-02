/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "InterfaceController.h"
#import <SDWebImage/SDWebImage.h>
#import <SDWebImageWebPCoder/SDImageWebPCoder.h>


@interface InterfaceController()

@property (weak) IBOutlet WKInterfaceImage *imageInterface;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    [[SDImageCodersManager sharedManager] addCoder:[SDImageWebPCoder sharedCoder]];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    NSString *urlString = @"http://apng.onevcat.com/assets/elephant.png";
    WKInterfaceImage *imageInterface = self.imageInterface;
    [imageInterface sd_setImageWithURL:[NSURL URLWithString:urlString] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        // `WKInterfaceImage` unlike `UIImageView`. Even the image is animated image, you should explicitly call `startAnimating` to play animation.
        [imageInterface startAnimating];
    }];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



