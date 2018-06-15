//
//  ActivityMetadataRepresentable.swift
//  FlintCore
//
//  Created by Marc Palmer on 14/06/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A protocol for Action input types to conform to, to supply metadata for `NSUserActivity` when used
/// with the Activities feature.
///
/// - see: `ActivitiesFeature` and `ActivityMetadata`
public protocol ActivityMetadataRepresentable {

    /// Implementations must return their metadata.
    /// Call `ActivityMetadata.build` to use the builder to create instances of this type.
    var metadata: ActivityMetadata { get }
}
