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
    
    private var observers = ObserverSet<UserFeatureTogglesObserver>()

    public func addObserver(_ observer: UserFeatureTogglesObserver) {
        let queue = SmartDispatchQueue(queue: .main, owner: self)
        observers.add(observer, using: queue)
    }
    
    public func removeObserver(_ observer: UserFeatureTogglesObserver) {
        observers.remove(observer)
    }

    /// Generates the unique key for the feature, used to store the availability of it in User Defaults
    private func key(_ id: String) -> String {
        return "features.user.toggle.\(id)"
    }
    
    /// Return `true` if the specified feature is currently enabled for the user, `false` if it is off, or nil
    /// if the user has not saved a preference
    public func isEnabled(_ feature: ConditionalFeatureDefinition.Type) -> Bool? {
        let id = feature.identifier.description
        let defaultsKey = key(id)
        if UserDefaults.standard.object(forKey: defaultsKey) != nil {
            return UserDefaults.standard.bool(forKey: defaultsKey)
        } else {
            return nil
        }
    }

    /// Set whether or not the specified feature is currently enabled for the user.
    public func setEnabled(_ feature: ConditionalFeatureDefinition.Type, enabled: Bool) {
        let id = feature.identifier.description
        UserDefaults.standard.set(enabled, forKey: key(id))
        
        observers.notifySync { observer in
            observer.userFeatureTogglesDidChange()
        }
    }
}
