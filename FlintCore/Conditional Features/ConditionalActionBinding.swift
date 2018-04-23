//
//  ConditionalActionBinding.swift
//  FlintCore
//
//  Created by Marc Palmer on 30/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A binding of feature and action for a conditional action that may not be available at runtime,
/// depending on other factors e.g. feature flagging or IAPs.
///
/// You can call `request()` on such a binding to see if its available in order to perform it:
///
/// ```
/// public class TimelineFeature: ConditionalFeature {
///     public static var availability: FeatureAvailability = .runtimeEvaluated
///
///     public static var description: String = "Maintains an in-memory timeline of actions for debugging and reporting"
///
///     public static var isAvailable: Bool? = true
///
///     // ** This creates the conditional binding **
///     public static let loadData = action(LoadDataAction.self)
///
///     public static func prepare(actions: FeatureActionsBuilder) {
///         // Declare the action to  Flint
///         actions.declare(loadData)
///     }
/// }
///
/// ... elsewhere when you need to perform the action ...
///
/// if let request = TimelineFeature.loadData.request() {
///     // Perform it in the main session. Use `ActionSession.perform` to use other sessions.
///     request.perform(using: presenter, with: input)
/// } else {
///     fatalError("Should not have been able to chose this action, feature is disabled!")
/// }
///
/// ```
///
/// - note: This is a completely discrete type from `StaticActionBinding` so that you cannot call `perform`
/// with a conditional action, you must first request the conditional action using this binding, and then
/// call perform with the `ConditionalActionRequest` received from that.
public struct ConditionalActionBinding<FeatureType: ConditionalFeature, ActionType: Action>: CustomDebugStringConvertible {
    public let feature: FeatureType.Type
    public let action: ActionType.Type

    public var debugDescription: String {
        return "ConditionalActionBinding action \(action) of \(feature)"
    }

    /// Get a conditional action request if the feature of this binding is currently available.
    /// Otherwise, returns nil and the action cannot be performed.
    ///
    /// - see: `ActionSession.perform`
    public func request() -> ConditionalActionRequest<FeatureType, ActionType>? {
        return FeatureType.request(self)
    }
}
