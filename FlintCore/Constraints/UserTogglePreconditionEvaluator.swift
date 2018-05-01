//
//  UserTogglePreconditionEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public class UserTogglePreconditionEvaluator: FeaturePreconditionEvaluator {
    let userToggles: UserFeatureToggles
    
    public init(userToggles: UserFeatureToggles) {
        self.userToggles = userToggles
    }

    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case let .userToggled(defaultValue) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to user toggle evaluator")
        }
        
        return userToggles.isEnabled(feature) ?? defaultValue
    }
}
