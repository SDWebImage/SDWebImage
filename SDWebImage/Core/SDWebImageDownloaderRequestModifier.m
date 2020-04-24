/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderRequestModifier.h"

@interface SDWebImageDownloaderRequestModifier ()

@property (nonatomic, copy, nonnull) SDWebImageDownloaderRequestModifierBlock block;

@end

@implementation SDWebImageDownloaderRequestModifier

- (instancetype)initWithBlock:(SDWebImageDownloaderRequestModifierBlock)block {
    self = [super init];
    if (self) {
        self.block = block;
    }
    return self;
}

+ (instancetype)requestModifierWithBlock:(SDWebImageDownloaderRequestModifierBlock)block {
    SDWebImageDownloaderRequestModifier *requestModifier = [[SDWebImageDownloaderRequestModifier alloc] initWithBlock:block];
    return requestModifier;
}

- (NSURLRequest *)modifiedRequestWithRequest:(NSURLRequest *)request {
    if (!self.block) {
        return nil;
    }
    return self.block(request);
}

@end

@interface SDWebImageDownloaderHTTPRequestModifier ()

@property (nonatomic, copy, nullable) NSString *method;
@property (nonatomic, copy, nullable) NSDictionary<NSString *,NSString *> *headers;
@property (nonatomic, copy, nullable) NSData *body;

@end

@implementation SDWebImageDownloaderHTTPRequestModifier

- (instancetype)initWithHeaders:(NSDictionary<NSString *,NSString *> *)headers {
    return [self initWithMethod:nil headers:headers body:nil];
}

- (instancetype)initWithMethod:(NSString *)method headers:(NSDictionary<NSString *,NSString *> *)headers body:(NSData *)body {
    self = [super init];
    if (self) {
        _method = [method copy];
        _headers = [headers copy];
        _body = [body copy];
    }
    return self;
}

- (NSURLRequest *)modifiedRequestWithRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    mutableRequest.HTTPMethod = self.method;
    mutableRequest.HTTPBody = self.body;
    for (NSString *header in self.headers) {
        NSString *value = self.headers[header];
        [mutableRequest setValue:value forHTTPHeaderField:header];
    }
    return [mutableRequest copy];
}

@end
