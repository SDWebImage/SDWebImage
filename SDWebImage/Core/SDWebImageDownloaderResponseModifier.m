/*
* This file is part of the SDWebImage package.
* (c) Olivier Poitrey <rs@dailymotion.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/


#import "SDWebImageDownloaderResponseModifier.h"

@interface SDWebImageDownloaderResponseModifier ()

@property (nonatomic, copy, nonnull) SDWebImageDownloaderResponseModifierBlock block;

@end

@implementation SDWebImageDownloaderResponseModifier

- (instancetype)initWithBlock:(SDWebImageDownloaderResponseModifierBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

+ (instancetype)responseModifierWithBlock:(SDWebImageDownloaderResponseModifierBlock)block {
    SDWebImageDownloaderResponseModifier *responseModifier = [[SDWebImageDownloaderResponseModifier alloc] initWithBlock:block];
    return responseModifier;
}

- (nullable NSURLResponse *)modifiedResponseWithResponse:(nonnull NSURLResponse *)response {
    if (!self.block) {
        return nil;
    }
    return self.block(response);
}

@end

@interface SDWebImageDownloaderHTTPResponseModifier ()

@property (nonatomic, copy, nullable) NSString *version;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic, copy, nullable) NSDictionary<NSString *,NSString *> *headers;

@end

@implementation SDWebImageDownloaderHTTPResponseModifier

- (instancetype)initWithHeaders:(NSDictionary<NSString *,NSString *> *)headers {
    return [self initWithVersion:nil statusCode:200 headers:headers];
}

- (instancetype)initWithVersion:(NSString *)version statusCode:(NSInteger)statusCode headers:(NSDictionary<NSString *,NSString *> *)headers {
    self = [super init];
    if (self) {
        _version = [version copy];
        _statusCode = statusCode;
        _headers = [headers copy];
    }
    return self;
}

- (NSURLResponse *)modifiedResponseWithResponse:(NSURLResponse *)response {
    if (![response isKindOfClass:NSHTTPURLResponse.class]) {
        return response;
    }
    NSMutableDictionary *mutableHeaders = [((NSHTTPURLResponse *)response).allHeaderFields mutableCopy];
    for (NSString *header in self.headers) {
        NSString *value = self.headers[header];
        mutableHeaders[header] = value;
    }
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:response.URL statusCode:self.statusCode HTTPVersion:self.version ?: @"HTTP/1.1" headerFields:[mutableHeaders copy]];
    return httpResponse;
}

@end
