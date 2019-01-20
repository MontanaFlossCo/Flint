//
//  ConditionalFeature.swift
//  FlintCore
//
//  Created by Marc Palmer on 21/12/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Features that are not guaranteed to be available all the time must conform to this protocol.
///
/// You implement a conditional feature like so:
///
/// ```
/// public class TimelineFeature: ConditionalFeature {
///     /// Set the availability to .purchasRequired, .runtimeEvaluated or .userToggled as appropriate
///     public static var availability: FeatureAvailability = .runtimeEvaluated
///
///     public static var description: String = "Maintains an in-memory timeline of actions for debugging and reporting"
///
///     /// If availability is `runtimeEvaluated`, you must make `isAvailable` return whether or not it is available.
///     /// Otherwise do not define a property for it and the `DefaultAvailabilityChecker` will be used to work out
///     /// the correct value of this by calling into the `UserDefaultsFeatureToggles` or `PurchaseValidator`.
///     public static var isAvailable: Bool? = true
///
///     /// If using `runtimeEvaluated` you can use this function to set `isAvailable` at startup based on
///     /// some other condition. Beware of dependency on other features and non-determinate initialising sequence.
///     public static func prepare(actions: FeatureActionsBuilder) {
///         if isAvailable == true {
///             // Tracks the user's history of actions performed
///             Flint.dispatcher.add(observer: TimelineDispatchObserver.instance)
///         }
///     }
/// }
/// ```
///
/// Apps must call `request` to test if the action is available, and then call `perform` with the resulting request instance.
public protocol ConditionalFeature: ConditionalFeatureDefinition {

    /// Call to request invocation of the conditionally available action.
    ///
    /// - return: nil if the action's feature is not available, or a request instance that can be used to `perform`
    /// the action directly or on a specific `ActionSession` if the feature is available
    ///
    /// - note: This is defined in the protocol so you may override it if you have other ways to validate features.
    static func request<T>(_ actionBinding: ConditionalActionBinding<Self, T>) -> ConditionalActionRequest<Self, T>?
}

/// Convenience functions to do useful things with conditional features
public extension ConditionalFeature {
    
    /// Verifies that the feature is correctly prepared in Flint and tests `isAvailable` to see if it is true.
    /// If so, returns a request that can be used to perform the action, otherwise `nil`.
    ///
    /// The default `isAvailable` implementation will delegate to the `AvailabilityChecker` to see if the feature is available.
    public static func request<ActionType>(_ actionBinding: ConditionalActionBinding<Self, ActionType>) -> ConditionalActionRequest<Self, ActionType>? {
        // Sanity checks and footgun avoidance
        Flint.requiresSetup()
        Flint.requiresPrepared(feature: Self.self)

        flintBugPrecondition(Flint.isDeclared(ActionType.self, on: Self.self),
                             "Action \(ActionType.self) has not been declared on \(Self.self). Call 'declare' or 'publish' with it in your feature's prepare function.")

        /// The action is possible only if this feature is currently available
        guard let available = isAvailable, available == true else {
            let requiredPermissions = permissions.allNotAuthorized
            let requiredPurchases = purchases.requiredToUnlock
            var reason = ""
            if requiredPermissions.count > 0 {
                let permissionNames = requiredPermissions.map({ $0.name }).joined(separator: ", ")
                reason.append(" Requires permissions: \(permissionNames).")
            }
            if requiredPurchases.count > 0 {
                let purchaseNames = requiredPurchases.map({ $0.description }).joined(separator: ", ")
                reason.append(" Requires purchases: \(purchaseNames).")
            }
            /// TODO: Add info about preconditions
            flintAdvisoryNotice("Request to use action '\(ActionType.name)' on feature '\(Self.name)' denied.\(reason)")
            return nil
        }
        return ConditionalActionRequest(actionBinding: actionBinding)
    }

    /// Function for binding a conditional feature and action pair, to restrict how this can be done externally by app code.
    ///
    /// - note: This exists only in an extension as it is not an extension point for features to override.
    public static func action<ActionType>(_ action: ActionType.Type) -> ConditionalActionBinding<Self, ActionType> where ActionType: Action {
        return ConditionalActionBinding<Self, ActionType>()
    }
}

