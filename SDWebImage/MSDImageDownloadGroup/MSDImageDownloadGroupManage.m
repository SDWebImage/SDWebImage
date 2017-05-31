//
//  MSDImageDownloadGroupManage.m
//  vb
//
//  Created by 马权 on 3/17/16.
//  Copyright © 2016 maquan. All rights reserved.
//

#import "MSDImageDownloadGroupManage.h"
#import "SDWebImageManager.h"

NSString *const MSDImageDownloadDefaultGroupIdentifier = @"msd.download.group.default";

@interface MSDImageDownloadGroup ()

{
@public
    NSMutableDictionary<NSString *, NSMutableArray<id<SDWebImageOperation>> *> *_downloadOperationsDic;
    NSMutableArray<NSString *> *_downloadOperationKeys;
    NSString *_identifier;
}

@end

@implementation MSDImageDownloadGroup

- (instancetype)init
{
    self = [self initWithGroupIdentifier:MSDImageDownloadDefaultGroupIdentifier];
    if (self) {

    }
    return self;
}

- (instancetype)initWithGroupIdentifier:(NSString *)identifier
{
    self = [super init];
    if (self) {
        _downloadOperationsDic = [@{} mutableCopy];
        _downloadOperationKeys = [@[] mutableCopy];
        _maxConcurrentDownloads = 20;
        _identifier = [identifier copy];
    }
    return self;
}

@end

@implementation MSDImageDownloadGroupManage

{
    NSMutableDictionary<NSString *, MSDImageDownloadGroup *> *_downloadGroupsDic;
}

+ (instancetype)shareInstance
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MSDImageDownloadGroupManage alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _downloadGroupsDic = [@{} mutableCopy];
    }
    return self;
}


//  MARK: Public
- (void)addGroup:(MSDImageDownloadGroup *)group
{
    MSDImageDownloadGroup *downloadGroup = _downloadGroupsDic[group->_identifier];
    if (downloadGroup) {
        return;
    }
    _downloadGroupsDic[group->_identifier] = group;
}

- (void)removeGroupWithIdentifier:(NSString *)identifier
{
    [_downloadGroupsDic removeObjectForKey:identifier];
}

- (void)setImageDownLoadOperation:(id<SDWebImageOperation>)operation toGroup:(NSString *)identifier forKey:(NSString *)key
{
    MSDImageDownloadGroup *downloadGroup = _downloadGroupsDic[identifier];
    if (!downloadGroup) {
        downloadGroup = [[MSDImageDownloadGroup alloc] initWithGroupIdentifier:identifier];
        _downloadGroupsDic[identifier] = downloadGroup;
    }
    
    NSMutableArray<NSString *> *downloadOperationKeys = downloadGroup->_downloadOperationKeys;
    
    if (downloadGroup && downloadOperationKeys) {
        if ([downloadOperationKeys containsObject:key]) {
            [downloadOperationKeys removeObject:key];
            [downloadOperationKeys insertObject:key atIndex:0];
            NSMutableArray<id<SDWebImageOperation>> *operations = downloadGroup->_downloadOperationsDic[key];
            [operations addObject:operation];
        }
        else {
            NSMutableArray<id<SDWebImageOperation>> *operations = [@[operation] mutableCopy];
            downloadGroup->_downloadOperationsDic[key] = operations;
            [downloadOperationKeys insertObject:key atIndex:0];
        }
        if ([downloadOperationKeys count] > downloadGroup.maxConcurrentDownloads) {
            NSString *lastKey = [downloadOperationKeys lastObject];
            NSMutableArray<id<SDWebImageOperation>> *lastOperations = downloadGroup->_downloadOperationsDic[lastKey];
            [lastOperations makeObjectsPerformSelector:@selector(cancel)];
            [downloadGroup->_downloadOperationsDic removeObjectForKey:lastKey];
            [downloadOperationKeys removeLastObject];
        }
    }
    else {
        NSMutableArray<id<SDWebImageOperation>> *operations = [@[operation] mutableCopy];
        
        downloadGroup = [[MSDImageDownloadGroup alloc] initWithGroupIdentifier:identifier];
        _downloadGroupsDic[identifier] = downloadGroup;
        
        downloadGroup->_downloadOperationKeys[0] = identifier;
        downloadGroup->_downloadOperationsDic[identifier] = operations;
    }
}

- (void)removeImageDownLoadOperation:(id<SDWebImageOperation>)operation fromGroup:(NSString *)identifier forKey:(NSString *)key
{
    if (_debug) {
        NSLog(@"groups count = %lu\n", (unsigned long)_downloadGroupsDic.count);
        [_downloadGroupsDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, MSDImageDownloadGroup * _Nonnull obj, BOOL * _Nonnull stop) {
            NSLog(@"group id = %@, key count = %lu\n", obj->_identifier, (unsigned long)obj->_downloadOperationsDic.count);
            [obj->_downloadOperationsDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<id<SDWebImageOperation>> * _Nonnull obj, BOOL * _Nonnull stop) {
                NSLog(@"operation key = %@, operation count = %lu\n", key,  obj.count);
                [obj enumerateObjectsUsingBlock:^(id<SDWebImageOperation>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    NSLog(@"operation = %@", obj);
                }];
            }];
        }];
    }

    MSDImageDownloadGroup *downloadGroup = _downloadGroupsDic[identifier];
    NSMutableArray<id<SDWebImageOperation>> *operations = downloadGroup->_downloadOperationsDic[key];
    [operations removeObject:operation];
    if (operations.count == 0) {
        [downloadGroup->_downloadOperationKeys removeObject:key];
        [downloadGroup->_downloadOperationsDic removeObjectForKey:key];
    }
}

static BOOL _debug = NO;

- (void)debug:(BOOL)debug
{
    _debug = debug;
}

@end
