//
//  ConditionalFeatureDefinition.swift
//  Features
//
//  Created by Marc Palmer on 25/11/2017.
//  Copyright © 2017 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// A feature that is not guaranteed to always be available must conform to `ConditionalFeatureDefinition`,
/// so that we can ensure the caller always verifies their availability before performing them.
///
/// This type exists separately from `ConditionalFeature` so that other types of conditional feature
/// can exist (e.g. a future `ConditionalFeatureGroup`).
///
/// We also have this type to enable us to reference conditional features without generic constraint issues
/// that arise from the Self requirement of `ConditionalFeature`. This allows us to define helper functions
/// that operate on conditional features without having to deal with those problems.
///
/// - note: Accesses to any properties that may change at runtime, e.g. `isAvailable` must only occur on the main thread.
public protocol ConditionalFeatureDefinition: FeatureDefinition {
    /// Called to define the requirements of this feature
    /// - see: `FeatureConstraintsBuilder` for the functions you can call to define constraints
    static func constraints(requirements: FeatureConstraintsBuilder)

    /// By default features with a runtime precondition are neither enabled nor disabled.
    /// Override this in your own types to set it to a default at runtime, or enable changing it at runtime
    static var isEnabled: Bool? { get }
}

public extension ConditionalFeatureDefinition {
    /// By default features with a runtime precondition are neither enabled nor disabled.
    /// Override this in your own types to set it to a default at runtime, or enable changing it at runtime
    static var isEnabled: Bool? {
        return nil
    }
    
    /// Check if a feature is available.
    /// - note: It is safe to invoke this from any thread or queue
    /// - see: `AvailabilityChecker`
    static var isAvailable: Bool? {
        return Flint.availabilityChecker?.isAvailable(self)
    }


    /// Returns a set of new context-specific loggers with this feature as the context (topic path).
    ///
    /// - param activity: A string that identifies the kind of activity that will be generating log entries, e.g. "bg upload"
    /// - return: A `Logs` value which contains development and production loggers as appropriate at runtime.
    public static func logs(for activity: String) -> ContextualLoggers {
        let development: ContextSpecificLogger?
        if let factory = Logging.development {
            development = factory.contextualLogger(with: activity, topicPath: self.identifier)
        } else {
            development = nil
        }

        let production: ContextSpecificLogger?
        if let factory = Logging.development {
            production = factory.contextualLogger(with: activity, topicPath: self.identifier)
        } else {
            production = nil
        }

        return ContextualLoggers(development: development, production: production)
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
            let requirements: [PurchaseRequirement] = preconditions.compactMap {
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
}
