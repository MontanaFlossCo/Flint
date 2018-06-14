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
    public internal(set) var title: String?
    public internal(set) var subtitle: String?

#if canImport(CoreSpotlight)
    /// Set to a thumbnail to show when displaying this activity
    public internal(set) var thumbnail: FlintImage?
    /// Set to thumbnail data to show when displaying this activity
    public internal(set) var thumbnailData: Data?
    /// Set to URL pointing at local thumbnail data to show when displaying this activity
    public internal(set) var thumbnailURL: URL?
#endif

    public internal(set) var keywords: Set<String>?

#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
    public internal(set) var searchAttributes: CSSearchableItemAttributeSet?
#endif

    public static func build(_ block: (_ builder: MetadataBuilder) -> ()) -> Metadata {
        let builder = MetadataBuilder()
        return builder.build(block)
    }
}

public class MetadataBuilder {
    public var title: String? {
        get {
            return metadata.title
        }
        set {
            metadata.title = newValue
        }
    }
    public var subtitle: String? {
        get {
            return metadata.subtitle
        }
        set {
            metadata.subtitle = newValue
        }
    }

#if canImport(CoreSpotlight)
    /// Set to a thumbnail to show when displaying this activity
    public var thumbnail: FlintImage? {
        get {
            return metadata.thumbnail
        }
        set {
            metadata.thumbnail = newValue
        }
    }
    
    /// Set to thumbnail data to show when displaying this activity
    public var thumbnailData: Data? {
        get {
            return metadata.thumbnailData
        }
        set {
            metadata.thumbnailData = newValue
        }
    }
    
    /// Set to URL pointing at local thumbnail data to show when displaying this activity
    public var thumbnailURL: URL? {
        get {
            return metadata.thumbnailURL
        }
        set {
            metadata.thumbnailURL = newValue
        }
    }
#endif

    public var keywords: Set<String>? {
        get {
            return metadata.keywords
        }
        set {
            metadata.keywords = newValue
        }
    }

#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
    public var searchAttributes: CSSearchableItemAttributeSet? {
        get {
            return metadata.searchAttributes
        }
        set {
            metadata.searchAttributes = newValue
        }
    }
#endif
    
    private var metadata = Metadata()
    
    func build(_ block: (_ builder: MetadataBuilder) -> ()) -> Metadata {
        block(self)
        return metadata
    }
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
