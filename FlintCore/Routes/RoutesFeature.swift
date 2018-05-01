//
//  RoutesFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 05/02/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The FlintCore "Deep Linking" feature which is used to take incoming URLs and
/// dispatch the appropriate App action using a Presenter provided by a `PresentationRouter`
/// which determines how your app will present the UI required for the action.
final public class RoutesFeature: ConditionalFeature {
    public static func constraints(requirements: FeatureConstraintsBuilder) {
        requirements.precondition(.runtimeEnabled)
    }
    
    /// Turned on by default, this can be turned off at runtime by setting it to `false`
    public static var enabled = true
    
    public static var description: String = "URL routes that support deep linking and custom URL schemes"

    /// The action to use to perform the URL
    public static let performIncomingURL = action(PerformIncomingURLAction.self)
    
    public static func prepare(actions: FeatureActionsBuilder) {
        actions.declare(performIncomingURL)
    }
}
