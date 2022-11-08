/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageDownloaderConfig.h"
#import "SDWebImageDownloaderOperation.h"

static SDWebImageDownloaderConfig * _defaultDownloaderConfig;

@implementation SDWebImageDownloaderConfig

+ (SDWebImageDownloaderConfig *)defaultDownloaderConfig {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultDownloaderConfig = [SDWebImageDownloaderConfig new];
    });
    return _defaultDownloaderConfig;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _maxConcurrentDownloads = 6;
        _downloadTimeout = 15.0;
        _executionOrder = SDWebImageDownloaderFIFOExecutionOrder;
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    SDWebImageDownloaderConfig *config = [[[self class] allocWithZone:zone] init];
    config.maxConcurrentDownloads = self.maxConcurrentDownloads;
    config.downloadTimeout = self.downloadTimeout;
    config.minimumProgressInterval = self.minimumProgressInterval;
    config.sessionConfiguration = [self.sessionConfiguration copyWithZone:zone];
    config.operationClass = self.operationClass;
    config.executionOrder = self.executionOrder;
    config.urlCredential = self.urlCredential;
    config.username = self.username;
    config.password = self.password;
    config.acceptableStatusCodes = self.acceptableStatusCodes;
    config.acceptableContentTypes = self.acceptableContentTypes;
    
    return config;
}

- (void)setOperationClass:(Class)operationClass {
    if (operationClass) {
        NSAssert([operationClass isSubclassOfClass:[NSOperation class]] && [operationClass conformsToProtocol:@protocol(SDWebImageDownloaderOperation)], @"Custom downloader operation class must subclass NSOperation and conform to `SDWebImageDownloaderOperation` protocol");
    }
    _operationClass = operationClass;
}


@end
