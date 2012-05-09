/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * Created by james <https://github.com/mystcolor> on 9/28/11.
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <Foundation/Foundation.h>
#import "SDWebImageCompat.h"

@protocol SDWebImageDecoderDelegate;

@interface SDWebImageDecoder : NSObject
{
    NSOperationQueue *imageDecodingQueue;
}

+ (SDWebImageDecoder *)sharedImageDecoder;
- (void)decodeImage:(UIImage *)image withDelegate:(id <SDWebImageDecoderDelegate>)delegate userInfo:(NSDictionary *)info;

@end

@protocol SDWebImageDecoderDelegate <NSObject>

- (void)imageDecoder:(SDWebImageDecoder *)decoder didFinishDecodingImage:(UIImage *)image userInfo:(NSDictionary *)userInfo;

@end

@interface UIImage (ForceDecode)

+ (UIImage *)decodedImageWithImage:(UIImage *)image;

@end