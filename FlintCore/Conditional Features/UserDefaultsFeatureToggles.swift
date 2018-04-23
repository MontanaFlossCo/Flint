//
//  UserDefaultsFeatureToggles.swift
//  FlintCore
//
//  Created by Marc Palmer on 13/01/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A simple convenience class that can be used for managing user-toggled features using UserDefaults,
/// with the `DefaultAvailabilityChecker`
public class UserDefaultsFeatureToggles: UserFeatureToggles {
    
    /// Generates the unique key for the feature, used to store the availability of it in User Defaults
    private func key(_ id: String) -> String {
        return "features.user.toggle.\(id)"
    }
    
    /// Return `true` if the specified feature is currently enabled for the user.
    public func isEnabled(_ feature: ConditionalFeatureDefinition.Type) -> Bool {
        let id = feature.identifier.description
        // Note that missing values will return `false`, so default is always off.
        return UserDefaults.standard.bool(forKey: key(id))
    }

    /// Set whether or not the specified feature is currently enabled for the user.
    public func setEnabled(_ feature: ConditionalFeatureDefinition.Type, enabled: Bool) {
        let id = feature.identifier.description
        UserDefaults.standard.set(enabled, forKey: key(id))
    }
}
