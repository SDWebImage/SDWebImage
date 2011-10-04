//
//  SDWebImageDecoder.h
//  jiepai
//
//  Created by james on 9/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SDWebImageDecoderDelegate;

@interface SDWebImageDecoder : NSObject {
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