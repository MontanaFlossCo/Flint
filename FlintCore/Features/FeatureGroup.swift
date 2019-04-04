//
//  ParentFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A grouping (nesting) of features.
///
/// Used to apply some hierarchical struture to feature definitions internally, for logging and debugging user activities.
///
///
/// ```
/// final class AppFeatures: FeatureGroup {
///     static var description = "Demo app features"
///
///     static var subfeatures: [FeatureDefinition.Type] = [
///         DocumentManagementFeature.self,
///         DocumentSharingFeature.self
///     ]
/// }
/// ```
public protocol FeatureGroup: FeatureDefinition {
    static var subfeatures: [FeatureDefinition.Type] { get }
}

public extension FeatureGroup {
    /// Normally a feature group has no initialisation to do, so we remove the requirement to implement this.
    static func prepare(actions: FeatureActionsBuilder) {
    }

    static var description: String {
        return "A feature group"
    }
}
