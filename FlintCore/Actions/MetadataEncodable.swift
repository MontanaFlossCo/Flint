//
//  MetadataEncodable.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
import CoreSpotlight
#endif

public struct Metadata {
    public let title: String?
    public let subtitle: String?

#if canImport(CoreSpotlight)
#if canImport(Cocoa)
    /// Set to a thumbnail to show when displaying this activity
    public let thumbnail: NSImage?
#elseif canImport(UIKit)
    /// Set to a thumbnail to show when displaying this activity
    public let thumbnail: UIImage?
#endif
    /// Set to thumbnail data to show when displaying this activity
    public let thumbnailData: Data?
    /// Set to URL pointing at local thumbnail data to show when displaying this activity
    public let thumbnailURL: URL?
#endif

    public let keywords: Set<String>?

#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
    public let searchAttributes: CSSearchableItemAttributeSet?
#endif
}

/// Allow inputs to provide information for user-facing activities and shortcuts
///
/// * title
/// * subtitle
/// * thumbnail
/// * keywords
/// * custom attributes
/// * addedDate etc.
public protocol MetadataRepresentable {
    var metadata: Metadata { get }
}
