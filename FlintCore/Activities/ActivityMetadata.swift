//
//  ActivityMetadata.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
#if canImport(CoreSpotlight) && (os(iOS) || os(macOS))
import CoreSpotlight
#endif

/// Action inputs that have per-instance metadata applicable to `NSUserActivity` can
/// conform to `ActivityMetadataRepresentable` and the metadata they return of this type
/// will be automatically used by the `Activities` feature to register the activity and
/// an implicit Siri Shortcut if so desired.
public struct ActivityMetadata {
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

    public static func build(_ block: (_ builder: ActivityMetadataBuilder) -> ()) -> ActivityMetadata {
        let builder = ActivityMetadataBuilder()
        return builder.build(block)
    }
}
