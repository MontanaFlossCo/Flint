//
//  ActivitiesFeature.swift
//  FlintCore-iOS
//
//  Created by Marc Palmer on 17/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The is the internal Flint feature for automatic `NSUserActivity` publishing and handling.
///
/// This provides actions used internally to publish and handle `NSUserActivity` for actions that opt-in to this by
/// setting their `activityEligibility` property.
public final class ActivitiesFeature: ConditionalFeature {
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.runtimeEnabled)
    }

    /// Set this to `false` to disable automatic user activity publishing
    public static var enabled = true

    public static var description: String = "Automatic NSUserActivity publishing and handling for Handoff, Siri suggestions and Spotlight"

    static var publishCurrentActionActivity = action(PublishCurrentActionActivityAction.self)
    static var handleActivity = action(HandleActivityAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(handleActivity)
        actions.declare(publishCurrentActionActivity)
        
        if isAvailable == true {
            // Implements Auto-Activities
            ActionSession.main.dispatcher.add(observer: ActivityActionDispatchObserver())
        }
    }
    
    // MARK: Properties shared by actions
    
    static let autoURLUserInfoKey = "tools.flint.auto.action.url"
}


