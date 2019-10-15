/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/


#import "SDWebImageDownloaderResponseModifier.h"

@interface SDWebImageDownloaderResponseModifier ()

@property (nonatomic, copy, nonnull) SDWebImageDownloaderResponseModifierBlock responseBlock;
@property (nonatomic, copy, nonnull) SDWebImageDownloaderResponseModifierDataBlock dataBlock;

@end

@implementation SDWebImageDownloaderResponseModifier

- (instancetype)initWithResponseBlock:(SDWebImageDownloaderResponseModifierBlock)responseBlock dataBlock:(SDWebImageDownloaderResponseModifierDataBlock)dataBlock {
    self = [super init];
    if (self) {
        self.responseBlock = responseBlock;
        self.dataBlock = dataBlock;
    }
    return self;
}

+ (instancetype)responseModifierWithResponseBlock:(SDWebImageDownloaderResponseModifierBlock)responseBlock dataBlock:(SDWebImageDownloaderResponseModifierDataBlock)dataBlock {
    SDWebImageDownloaderResponseModifier *responseModifier = [[SDWebImageDownloaderResponseModifier alloc] initWithResponseBlock:responseBlock dataBlock:dataBlock];
    return responseModifier;
}

- (nullable NSData *)modifiedDataWithData:(nonnull NSData *)data response:(nullable NSURLResponse *)response {
    if (!self.dataBlock) {
        return nil;
    }
    return self.dataBlock(data, response);
}

- (nullable NSURLResponse *)modifiedResponseWithResponse:(nonnull NSURLResponse *)response {
    if (!self.responseBlock) {
        return nil;
    }
    return self.responseBlock(response);
}

@end


@implementation SDWebImageDownloaderResponseModifier (Conveniences)

+ (SDWebImageDownloaderResponseModifier *)base64ResponseModifier {
    static SDWebImageDownloaderResponseModifier *responseModifier;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        responseModifier = [SDWebImageDownloaderResponseModifier responseModifierWithResponseBlock:^NSURLResponse * _Nullable(NSURLResponse * _Nonnull response) {
            return response;
        } dataBlock:^NSData * _Nullable(NSData * _Nonnull data, NSURLResponse * _Nullable response) {
            return [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters];
        }];
    });
    return responseModifier;
}

@end
