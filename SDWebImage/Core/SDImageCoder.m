/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDImageCoder.h"

SDImageCoderOption const SDImageCoderDecodeFirstFrameOnly = @"decodeFirstFrameOnly";
SDImageCoderOption const SDImageCoderDecodeScaleFactor = @"decodeScaleFactor";
SDImageCoderOption const SDImageCoderDecodePreserveAspectRatio = @"decodePreserveAspectRatio";
SDImageCoderOption const SDImageCoderDecodeThumbnailPixelSize = @"decodeThumbnailPixelSize";

SDImageCoderOption const SDImageCoderEncodeFirstFrameOnly = @"encodeFirstFrameOnly";
SDImageCoderOption const SDImageCoderEncodeCompressionQuality = @"encodeCompressionQuality";
SDImageCoderOption const SDImageCoderEncodeBackgroundColor = @"encodeBackgroundColor";
SDImageCoderOption const SDImageCoderEncodeMaxPixelSize = @"encodeMaxPixelSize";
SDImageCoderOption const SDImageCoderEncodeMaxFileSize = @"encodeMaxFileSize";
SDImageCoderOption const SDImageCoderEncodeEmbedThumbnail = @"encodeEmbedThumbnail";

SDImageCoderOption const SDImageCoderWebImageContext = @"webImageContext";

SDImageFrameOption const SDImageFrameDecodeThumbnailPixelSize = SDImageCoderDecodeThumbnailPixelSize;
SDImageFrameOption const SDImageFrameDecodeScaleFactor = SDImageCoderDecodeScaleFactor;
SDImageFrameOption const SDImageFrameDecodePreserveAspectRatio = SDImageCoderDecodePreserveAspectRatio;

