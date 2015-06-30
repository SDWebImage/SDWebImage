//
//  NSObject+MultiDownload.m
//  SDWebImage
//
//  Created by guodi.ggd on 6/30/15.
//
//

#import "NSObject+MultiDownload.h"
#import <objc/runtime.h>

static char sd_objectMultiDownloadKey;

@implementation NSObject (MultiDownload)
- (id)sd_tag {
    return objc_getAssociatedObject(self, &sd_objectMultiDownloadKey);
}

- (void)sd_setTag:(id)tag {
    if (tag) {
        objc_setAssociatedObject(self, &sd_objectMultiDownloadKey, tag, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        objc_setAssociatedObject(self, &sd_objectMultiDownloadKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}
@end
