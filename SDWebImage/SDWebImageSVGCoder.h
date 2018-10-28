//
//  SDWebImageSVGCoder.h
//  SDWebImage
//
//  Created by Noah on 2018/10/26.
//

#ifdef SD_SVG

#import <Foundation/Foundation.h>
#import "SDWebImageCoder.h"

/**
 Built in coder that supports SVG
 */
@interface SDWebImageSVGCoder : NSObject <SDWebImageCoder>

+ (nonnull instancetype)sharedCoder;

@end

#endif
