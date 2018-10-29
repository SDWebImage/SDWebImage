//
//  SVGKImageView+WebCache.m
//  SDWebImage
//
//  Created by Noah on 2018/10/29.
//

#ifdef SD_SVG

#import "SVGKImageView+WebCache.h"
#import "objc/runtime.h"
#import "UIView+WebCache.h"
#import "UIImage+MultiFormat.h"

@implementation UIImage (SVGKImage)

- (SVGKImage *)sd_SVGKImage {
    return objc_getAssociatedObject(self, @selector(sd_SVGKImage));
}

- (void)setSd_SVGKImage:(SVGKImage *)sd_SVGKImage {
    objc_setAssociatedObject(self, @selector(sd_SVGKImage), sd_SVGKImage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation SVGKImageView (WebCache)

- (void)sd_setImageWithURL:(nullable NSURL *)url {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:nil];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:nil options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:0 progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url placeholderImage:(nullable UIImage *)placeholder options:(SDWebImageOptions)options completed:(nullable SDExternalCompletionBlock)completedBlock {
    [self sd_setImageWithURL:url placeholderImage:placeholder options:options progress:nil completed:completedBlock];
}

- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                  progress:(nullable SDWebImageDownloaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock {
    __weak typeof(self)weakSelf = self;
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                        operationKey:nil
                       setImageBlock:^(UIImage *image, NSData *imageData) {
                           __strong typeof(weakSelf)strongSelf = weakSelf;
                           if (!strongSelf) {
                               return;
                           }
                           // Step 1. Check memory cache (associate object)
                           SVGKImage *associatedSvgImage = image.sd_SVGKImage;
                           if (associatedSvgImage) {
                               // Asscociated SVG image exist
                               strongSelf.image = associatedSvgImage;
                               return;
                           }
                           // Step 2. Check if original compressed image data is "SVG"
                           BOOL isSVG = (image.sd_imageFormat == SDImageFormatSVG || [NSData sd_imageFormatForImageData:imageData] == SDImageFormatSVG);
                           if (!isSVG) {
                               strongSelf.image = nil;
                               return;
                           }
                           // Step 3. Check if data exist or query disk cache
                           if (!imageData) {
                               NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:url];
                               imageData = [[SDImageCache sharedImageCache] diskImageDataForKey:key];
                           }
                           // Step 4. Create SVGKImage
                           SVGKImage *svgImage = [SVGKImage imageWithData:imageData];
                           // Step 5. Set SVG image
                           strongSelf.image = svgImage;
                       }
                            progress:progressBlock
                           completed:completedBlock];
}

@end

#endif
