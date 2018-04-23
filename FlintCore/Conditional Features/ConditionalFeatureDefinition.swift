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
    
    /// This property determines whether or not this feature is currently available.
    /// A nil value indicates that availability is not yet known, and actions of this feature cannot yet be used.
    /// During startup this may be the case for A/B tested or IAP dependent features where the networking or receipt
    /// validation has not yet completed.
    static var isAvailable: Bool? { get }
}

public extension ConditionalFeatureDefinition {
    /// Override this in your own features (with a more specific extension and YourFeature base class?)
    /// to use a custom checker instance that does not use the default validators
    /// - note: Accesses to any properties that may change at runtime, e.g. `isAvailable` must only occur on the main thread.
    static var isAvailable: Bool? {
        return Flint.availabilityChecker?.isAvailable(self)
    }
}

