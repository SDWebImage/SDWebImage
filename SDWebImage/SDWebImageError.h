/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Jamie Pinkham
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

FOUNDATION_EXPORT NSErrorDomain const _Nonnull SDWebImageErrorDomain;

typedef NS_ERROR_ENUM(SDWebImageErrorDomain, SDWebImageError) {
    SDWebImageErrorInvalidURL = 1000, // The URL is invalid, such as nil URL or corrupted URL
    SDWebImageErrorBadImageData = 1001, // The image data can not be decoded to image, or the image data is empty
    SDWebImageErrorInvalidDownloadOperation = 2000, // The image download operation is invalid, such as nil operation or unexpected error occur when operation initialized
};
