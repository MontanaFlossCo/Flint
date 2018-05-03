//
//  MockUserToggles.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
@testable import FlintCore

class MockUserToggles: UserFeatureToggles {
    var toggles: [FeaturePath:Bool] = [:]
    
    private var observers = ObserverSet<UserFeatureTogglesObserver>()

    func addObserver(_ observer: UserFeatureTogglesObserver) {
        let queue = SmartDispatchQueue(queue: .main, owner: self)
        observers.add(observer, using: queue)
    }
    
    func removeObserver(_ observer: UserFeatureTogglesObserver) {
        observers.remove(observer)
    }

    func isEnabled(_ feature: ConditionalFeatureDefinition.Type) -> Bool? {
        return toggles[feature.identifier]
    }
    
    func setEnabled(_ feature: ConditionalFeatureDefinition.Type, enabled: Bool) {
        toggles[feature.identifier] = enabled
        observers.notifySync { observer in
            observer.userFeatureTogglesDidChange()
        }
   }
}
