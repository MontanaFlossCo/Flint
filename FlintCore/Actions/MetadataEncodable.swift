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
    public private(set) var title: String?
    public private(set) var subtitle: String?

#if canImport(CoreSpotlight)
    /// Set to a thumbnail to show when displaying this activity
    public private(set) var thumbnail: FlintImage?
    /// Set to thumbnail data to show when displaying this activity
    public private(set) var thumbnailData: Data?
    /// Set to URL pointing at local thumbnail data to show when displaying this activity
    public private(set) var thumbnailURL: URL?
#endif

    public private(set) var keywords: Set<String>?

#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
    public private(set) var searchAttributes: CSSearchableItemAttributeSet?
#endif

    public static func build(_ block: (_ builder: MetadataBuilder) -> ()) -> Metadata {
        let builder = MetadataBuilder()
        return builder.build(block)
    }
}

public class MetadataBuilder {
    public private(set) var title: String?
    public private(set) var subtitle: String?

#if canImport(CoreSpotlight)
    /// Set to a thumbnail to show when displaying this activity
    public private(set) var thumbnail: FlintImage?
    /// Set to thumbnail data to show when displaying this activity
    public private(set) var thumbnailData: Data?
    /// Set to URL pointing at local thumbnail data to show when displaying this activity
    public private(set) var thumbnailURL: URL?
#endif

    public private(set) var keywords: Set<String>?

#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
    public private(set) var searchAttributes: CSSearchableItemAttributeSet?
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
