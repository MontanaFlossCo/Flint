//
//  UserFeatureToggles.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface to user-specified feature toggling, where a user may choose to switch certain features
/// on or off in the "Settings" of your app.
///
/// The `DefaultAvailabilityChecker` uses instances of this type to verify availability of user toggled features
/// at runtime. The default implementation `UserDefaultsFeatureToggles` stores the toggled values in User Defaults.
///
/// If you want to store your feature toggles differently, implement this protocol and assign your own
/// instance of `DefaultAvailabilityChecker` to `Flint.availabilityChecker` at startup.
public protocol UserFeatureToggles {
    /// Call to add an observer for changes to user toggles
    func addObserver(_ observer: UserFeatureTogglesObserver)

    /// Call to remove an observer for changes to user toggles
    func removeObserver(_ observer: UserFeatureTogglesObserver)

    /// Checke if a feature is enabled.
    /// - return: Whether or not the feature should currently be enabled for the user.
    /// If the user has not set a preference, return nil
    func isEnabled(_ feature: ConditionalFeatureDefinition.Type) -> Bool?
}
