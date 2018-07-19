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
        // Sanity checks and footgun avoidance
        Flint.requiresSetup()
        Flint.requiresPrepared(feature: actionBinding.feature)

        flintBugPrecondition(Flint.isDeclared(actionBinding.action, on: actionBinding.feature),
                             "Action \(actionBinding.action) has not been declared on \(actionBinding.feature). Call 'declare' or 'publish' with it in your feature's prepare function.")

        /// The action is possible only if this feature is currently available
        guard let available = isAvailable, available == true else {
            return nil
        }
        return ConditionalActionRequest(actionBinding: actionBinding)
    }


    /// Create a new context-specific logger with this feature as the context (topic path).
    /// - param activity: A string that identifies the kind of activity that will be generating log entries, e.g. "bg upload"
    /// - return: A logger if running in a development build, else nil. You must store the result of this call to avoid
    /// re-creating the loggers every time this function is called.
    public static func developmentLogger(for activity: String) -> ContextSpecificLogger? {
        if let factory = Logging.development {
            return factory.contextualLogger(with: activity, topicPath: self.identifier)
        } else {
            return nil
        }
    }

    /// Create a new context-specific logger with this feature as the context (topic path).
    /// - param activity: A string that identifies the kind of activity that will be generating log entries, e.g. "bg upload"
    /// - return: A logger if running in a production build, else nil. You must store the result of this call to avoid
    /// re-creating the loggers every time this function is called.
    public static func productionLogger(for activity: String) -> ContextSpecificLogger? {
        if let factory = Logging.production {
            return factory.contextualLogger(with: activity, topicPath: self.identifier)
        } else {
            return nil
        }
    }
    
    /// Access information about the permissions required by this feature
    public static var permissions: FeaturePermissionRequirements {
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        
        func _filter(_ permissions: [SystemPermissionConstraint], onStatus matchingStatus: SystemPermissionStatus) -> Set<SystemPermissionConstraint> {
            let results = permissions.filter { permission in
                let status = Flint.permissionChecker.status(of: permission)
                return matchingStatus == status
            }
            return Set(results)
        }
        
        let notDetermined = _filter(constraints.permissions.notDetermined.map { $0.constraint }, onStatus: .notDetermined)
        let denied = _filter(constraints.permissions.notSatisfied.map { $0.constraint }, onStatus: .denied)
        let restricted = _filter(constraints.permissions.notSatisfied.map { $0.constraint }, onStatus: .restricted)

        return FeaturePermissionRequirements(all: Set(constraints.permissions.all.map { $0.constraint }),
                                             notDetermined: notDetermined,
                                             denied: denied,
                                             restricted: restricted)
    }
    
    /// Access information about the purchases required by this feature
    public static var purchases: FeaturePurchaseRequirements {
        // Ugly implementation of this for now until we patch up `FeatureConstraints` internals
        func _extractPurchaseRequirements(_ preconditions: [FeaturePreconditionConstraint]) -> Set<PurchaseRequirement> {
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
        let all = _extractPurchaseRequirements(constraints.preconditions.all.map { $0.constraint })
        let requiredToUnlock = _extractPurchaseRequirements(constraints.preconditions.notSatisfied.map { $0.constraint })
        let purchased = _extractPurchaseRequirements(constraints.preconditions.satisfied.map { $0.constraint })
        
        return FeaturePurchaseRequirements(all: all, requiredToUnlock: requiredToUnlock, purchased: purchased)
    }
    
    /// Request permissions for all unauthorised permission requirements, using the supplied presenter
    public static func permissionAuthorisationController(using coordinator: PermissionAuthorisationCoordinator?) -> AuthorisationController? {
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        guard constraints.permissions.notDetermined.count > 0 else {
            return nil
        }
        
        return DefaultAuthorisationController(coordinator: coordinator,
                                              permissions: Set(constraints.permissions.notDetermined.map { $0.constraint }))
    }
    
    /// Function for binding a conditional feature and action pair, to restrict how this can be done externally by app code.
    public static func action<A>(_ action: A.Type) -> ConditionalActionBinding<Self, A> where A: Action {
        return ConditionalActionBinding(feature: self, action: action)
    }

}

