//
//  ActionStackFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 04/05/2019.
//  Copyright © 2019 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The Action Stack Feature tracks actions the user performs, as a "threaded" set of stacks.
///
/// Set `ActionStacksFeature.isEnabled = true` to turn this feature on
final public class ActionStacksFeature: ConditionalFeature {
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.runtimeEnabled()
    }

    /// Set this to `true` at runtime to enable Action Stacks
    public static var isEnabled: Bool? = false
    
    public static var description: String = "Keep a history of actions the user performs, threaded by the feature they started using"

    public static func prepare(actions: FeatureActionsBuilder) {
    }
}
