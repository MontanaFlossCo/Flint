//
//  MockUserToggles.swift
//  FlintCore
//
//  Created by Marc Palmer on 27/04/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

class MockUserToggles: UserFeatureToggles {
    var toggles: [FeaturePath:Bool] = [:]
    
    func isEnabled(_ feature: ConditionalFeatureDefinition.Type) -> Bool {
        return toggles[feature.identifier] ?? false
    }
    
    func setEnabled(_ feature: ConditionalFeatureDefinition.Type, enabled: Bool) {
        toggles[feature.identifier] = enabled
   }
}
