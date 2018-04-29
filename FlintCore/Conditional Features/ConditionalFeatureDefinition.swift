//
//  ConditionalFeatureDefinition.swift
//  Features
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A feature that is not guaranteed to always be available must conform to `ConditionalFeatureDefinition`,
/// so that we can ensure the caller always verifies their availability before performing them.
///
/// This type exists separately from `ConditionalFeature` so that other types of conditional feature
/// can exist (e.g. a future `ConditionalFeatureGroup`).
///
/// - note: Accesses to any properties that may change at runtime, e.g. `isAvailable` must only occur on the main thread.
public protocol ConditionalFeatureDefinition: FeatureDefinition {
    /// Indicates how availability of this feature is determined.
    static var availability: FeatureAvailability { get }
    
}

public extension ConditionalFeatureDefinition {
    /// Check if a feature is available.
    /// - note: It is safe to invoke this from any thread or queue
    /// - see: `AvailabilityChecker`
    static var isAvailable: Bool? {
        return Flint.availabilityChecker?.isAvailable(self)
    }
}
