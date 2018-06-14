//
//  ActivityMetadataBuilder.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
import CoreSpotlight
#endif

/// This is a builder for creating Metadata instances without requiring a mutable type or ugly initializer permutation.
///
/// - see: `ActivityMetadata.build` for the function that creates this builder.
public class ActivityMetadataBuilder {
    /// Set to a title representing this item, such as a document file name or title.
    public var title: String? {
        get {
            return metadata.title
        }
        set {
            metadata.title = newValue
        }
    }

    /// Set to a subtitle representing this item, such as a document summary.
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

    /// Set any keywords that apply to this input's activity
    public var keywords: Set<String>? {
        get {
            return metadata.keywords
        }
        set {
            metadata.keywords = newValue
        }
    }

#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
    /// Set to any specific searchAttributes you wish to define.
    /// - note: `subtitle` is used to set `contentDescription`, so you only need to use this to define other
    /// Spotlight attributes such as `contentCreationDate` or `kind`.
    public var searchAttributes: CSSearchableItemAttributeSet? {
        get {
            return metadata.searchAttributes
        }
        set {
            metadata.searchAttributes = newValue
        }
    }
#endif
    
    private var metadata = ActivityMetadata()
    
    /// Called internally to execute the builder
    func build(_ block: (_ builder: ActivityMetadataBuilder) -> ()) -> ActivityMetadata {
        block(self)
        return metadata
    }
}
