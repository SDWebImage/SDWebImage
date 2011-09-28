//
//  SDWebImageDecoder.m
//  jiepai
//
//  Created by james on 9/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SDWebImageDecoder.h"

#define DECOMPRESSED_IMAGE_KEY @"decompressedImage"
#define DECODE_INFO_KEY @"decodeInfo"

#define IMAGE_KEY @"image"
#define DELEGATE_KEY @"delegate"
#define USER_INFO_KEY @"userInfo"

@implementation SDWebImageDecoder
static SDWebImageDecoder *sharedInstance;

- (void)notifyDelegateOnMainThreadWithInfo:(NSDictionary *)dict {
    [dict retain];
    NSDictionary *decodeInfo                = [dict objectForKey:DECODE_INFO_KEY];
    UIImage      *decodedImage              = [dict objectForKey:DECOMPRESSED_IMAGE_KEY];

    id <SDWebImageDecoderDelegate> delegate = [decodeInfo objectForKey:DELEGATE_KEY];
    NSDictionary *userInfo                  = [decodeInfo objectForKey:USER_INFO_KEY];

    [delegate imageDecoder:self didFinishDecodingImage:decodedImage userInfo:userInfo];
    [dict release];
}

- (void)decodeImageWithInfo:(NSDictionary *)decodeInfo {
    UIImage *image = [decodeInfo objectForKey:IMAGE_KEY];
    
    CGImageRef imageRef = image.CGImage;
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 CGImageGetWidth(imageRef),
                                                 CGImageGetHeight(imageRef),
                                                 CGImageGetBitsPerComponent(imageRef),
                                                 CGImageGetBytesPerRow(imageRef),
                                                 CGImageGetColorSpace(imageRef),
                                                 kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    
    CGRect rect = (CGRect){CGPointZero, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef)};
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef decompressedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *decompressedImage = [[UIImage alloc] initWithCGImage:decompressedImageRef];
    CGImageRelease(decompressedImageRef);
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          decompressedImage, DECOMPRESSED_IMAGE_KEY,
                          decodeInfo, DECODE_INFO_KEY, nil];
    [decompressedImage release];

    [self performSelectorOnMainThread:@selector(notifyDelegateOnMainThreadWithInfo:) withObject:dict waitUntilDone:NO];
}

#pragma mark Life Cycle

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        imageDecodingQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (void)decodeImage:(UIImage *)image withDelegate:(id<SDWebImageDecoderDelegate>)delegate userInfo:(NSDictionary *)info {
    NSDictionary *decodeInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                image, IMAGE_KEY,
                                delegate, DELEGATE_KEY,
                                info, USER_INFO_KEY, nil];

    NSOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(decodeImageWithInfo:) object:decodeInfo];
    [imageDecodingQueue addOperation:operation];
    NSLog(@"%d", [imageDecodingQueue operationCount]);
    [operation release];
}

- (void)dealloc {
    [imageDecodingQueue release], imageDecodingQueue = nil;
    [super dealloc];
}

#pragma mark Class

+ (SDWebImageDecoder *)sharedImageDecoder {
    if ( ! sharedInstance) {
        sharedInstance = [[SDWebImageDecoder alloc] init];
    }
    return sharedInstance;
}

@end
