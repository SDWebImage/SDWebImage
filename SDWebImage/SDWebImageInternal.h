/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Fabrice Aneche
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#ifndef SDWebImageInternal_h
#define SDWebImageInternal_h

/**
 A Dispatch group to maintain setImageBlock and completionBlock. This key should be used only internally and may be changed in the future. (dispatch_group_t)
 */
FOUNDATION_EXPORT NSString * _Nonnull const SDWebImageInternalSetImageGroupKey;

/**
 Global lock when accessing shared NSURLCache to avoid thread-safe problem

 @return A lock to used when accessing shared NSURLCache
 */
FOUNDATION_EXPORT dispatch_semaphore_t _Nonnull const SDWebImageDownloadSharedCacheLock(void);


#endif /* SDWebImageInternal_h */
