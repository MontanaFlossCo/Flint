//
//  FeaturePrecondition.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Defines the list of possible feature preconditions
public enum FeaturePrecondition: Hashable, CustomStringConvertible {
    /// Indicates that the feature supports User Toggling and its default value for when
    /// there is no setting in the user's preferences yet. If the user toggle is `false`
    /// the feature will not be available.
    /// - see `UserFeatureToggles`
    case userToggled(defaultValue: Bool)
    
    /// Indicates that the feature is subject to runtime evaluation, and the property `isEnabled`
    /// will be checked on the Feature to test availability. If it is not `true`, the feature is not available.
    case runtimeEnabled
    
    /// Indicates that the feature has a purchase requirement. Unless that requirement is fulfilled,
    /// the feature will not be available.
    case purchase(requirement: PurchaseRequirement)
    
    public var description: String {
        switch self {
            case .userToggled(let defaultValue): return "User toggled (default: \(defaultValue))"
            case .runtimeEnabled: return "Runtime enabled"
            case .purchase(let requirement): return "Purchase \(requirement.description)"
        }
    }
}
