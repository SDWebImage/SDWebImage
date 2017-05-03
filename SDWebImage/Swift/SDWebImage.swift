/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Chester Liu <https://github.com/skyline75489>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import Foundation

#if os(macOS)
    import AppKit
    public typealias SDImageType = NSImage
    public typealias SDColorType = NSColor
    public typealias SDImageViewType = NSImageView
#else
    import UIKit
    public typealias SDImageType = UIImage
    public typealias SDColorType = UIColor
#if !os(watchOS)
    public typealias SDImageViewType = UIImageView
#endif
#endif

#if !os(watchOS)
extension SDImageViewType {

    @nonobjc public func sd_setImage(with url: URL?, placeholderImage: SDImageType? = nil, options: SDWebImageOptions = .init(rawValue: 0), progress: SDWebImageDownloaderProgressBlock? = nil, completed: SDExternalCompletionBlock? = nil) {
        __sd_setImage(with: url, placeholderImage: placeholderImage, options: options, progress: progress, completed: completed)
    }

    #if os(iOS) || os(tvOS)
    @nonobjc public func sd_setHighlightedImage(url: URL?, options: SDWebImageOptions = .init(rawValue: 0), progress: SDWebImageDownloaderProgressBlock? = nil, completed: SDExternalCompletionBlock? = nil) {
        __sd_setHighlightedImage(with: url, options: options, progress: progress, completed: completed)
    }
    #endif
}
#endif
