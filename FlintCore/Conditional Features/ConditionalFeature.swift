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
    /// - return: nil if the action's feature is not available, or a request instance that can be used to `perform`
    /// the action directly or on a specific `ActionSession` if the feature is available
    static func request<T>(_ actionBinding: ConditionalActionBinding<Self, T>) -> ConditionalActionRequest<Self, T>?
}

/// Convenience functions to do useful things with conditional features
public extension ConditionalFeature {
    
    /// Verifies that the feature is correctly prepared in Flint and tests `isAvailable` to see if it is true.
    /// If so, returns a request that can be used to perform the action, otherwise `nil`.
    ///
    /// The default `isAvailable` implementation will delegate to the `AvailabilityChecker` to see if the feature is available.
    public static func request<T>(_ actionBinding: ConditionalActionBinding<Self, T>) -> ConditionalActionRequest<Self, T>? {
        Flint.requiresSetup()
        Flint.requiresPrepared(feature: actionBinding.feature)

        /// The action is possible only if this feature is currently available
        guard let available = isAvailable, available == true else {
            return nil
        }
        return ConditionalActionRequest(actionBinding: actionBinding)
    }

    /// Access information about the permissions required by this feature
    public static var permissions: FeaturePermissionRequirements {
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        let all = constraints.all.permissions
        
        func _filter(_ permissions: Set<SystemPermission>, onStatus matchingStatus: SystemPermissionStatus) -> Set<SystemPermission> {
            let results = permissions.filter { permission in
                let status = Flint.permissionChecker.status(of: permission)
                return matchingStatus == status
            }
            return Set(results)
        }
        
        let notDetermined = _filter(constraints.unsatisfied.permissions, onStatus: .notDetermined)
        let denied = _filter(constraints.unsatisfied.permissions, onStatus: .denied)
        let restricted = _filter(constraints.unsatisfied.permissions, onStatus: .restricted)

        return FeaturePermissionRequirements(all: all, notDetermined: notDetermined, denied: denied, restricted: restricted)
    }
    
    /// Access information about the purchases required by this feature
    public static var purchases: FeaturePurchaseRequirements {
        // Ugly implementation of this for now until we patch up `FeatureConstraints` internals
        func _extractPurchaseRequirements(_ preconditions: Set<FeaturePrecondition>) -> Set<PurchaseRequirement> {
            let requirements: [PurchaseRequirement] = preconditions.flatMap {
                if case let .purchase(requirement) = $0 {
                    return requirement
                } else {
                    return nil
                }
            }
            return Set(requirements)
        }
    
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        let all = _extractPurchaseRequirements(constraints.all.preconditions)
        let requiredToUnlock = _extractPurchaseRequirements(constraints.unsatisfied.preconditions)
        let purchased = _extractPurchaseRequirements(constraints.satisfied.preconditions)
        
        return FeaturePurchaseRequirements(all: all, requiredToUnlock: requiredToUnlock, purchased: purchased)
    }
    
    /// Request permissions for all unauthorised permission requirements, using the supplied presenter
    public static func permissionAuthorisationController(using coordinator: PermissionAuthorisationCoordinator?) -> AuthorisationController? {
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        guard constraints.unsatisfied.permissions.count > 0 else {
            return nil
        }
        
        return DefaultAuthorisationController(coordinator: coordinator, permissions: constraints.unsatisfied.permissions)
    }
    
    /// Function for binding a conditional feature and action pair, to restrict how this can be done externally by app code.
    public static func action<A>(_ action: A.Type) -> ConditionalActionBinding<Self, A> where A: Action {
        return ConditionalActionBinding(feature: self, action: action)
    }

}

