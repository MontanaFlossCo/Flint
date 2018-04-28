//
//  AvailabilityChecker.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// You can customise the checking of purchased and user toggled conditional features by
/// implementing this protocol.
///
/// Implementations must be safe to call from any thread or queue, so that callers
/// testing `isAvailable` on a feature do not need to be concerned about this even if running
/// on a background queue or an ActionSession that is not on the main queue.
///
/// Implementations must also take care to examine the ancestors of features to ensure
/// the correct result is returned from isAvailable.
///
/// - see: `DefaultAvailabilityChecker`
public protocol AvailabilityChecker {

    /// Return whether or not the specified feature is currently available.
    /// Implementations must only return `true` if all ancesters of the feature are
    /// also available.
    /// - return: `nil` if the state of this feature or its ancestors is not yet known, or
    /// a boolean value indicating whether or not this feature and all its ancestors are available.
    func isAvailable(_ feature: ConditionalFeatureDefinition.Type) -> Bool?
}

