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

    /// Get a human readable description of what constraints are not currently satisfied and hence preventing
    /// the use of this feature.
    static var descriptionOfUnsatisfiedConstraints: String? {
        let requiredPermissions = permissions.allNotAuthorized
        let requiredPurchases = purchases.requiredToUnlock
        var reason = ""
        if requiredPermissions.count > 0 {
            let permissionNames = requiredPermissions.map({ $0.name }).joined(separator: ", ")
            reason.append(" Requires permissions: \(permissionNames).")
        }
        if requiredPurchases.count > 0 {
            let purchaseNames = requiredPurchases.map({ $0.description }).joined(separator: ", ")
            reason.append(" \(purchaseNames).")
        }
        if requiresUserToggle {
            reason.append(" User toggle = OFF.")
        }
        if requiresRuntimeEnabled {
            reason.append(" Runtime enabled = OFF.")
        }
        
        return reason.count == 0 ? nil : reason
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
        let allUnsatisfied = constraints.preconditions.notSatisfied.union(constraints.preconditions.notDetermined)
        let requiredToUnlock = _extractPurchaseRequirements(allUnsatisfied.map { $0.constraint })
        
        let purchased = _extractPurchaseRequirements(constraints.preconditions.satisfied.map { $0.constraint })
        
        return FeaturePurchaseRequirements(all: all, requiredToUnlock: requiredToUnlock, purchased: purchased)
    }
    
    /// - return: `true` if this feature is currently disabled at least in part because the user has not toggled it ON
    /// via the Flint user toggles API
    public static var requiresUserToggle: Bool {
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        let preconditionMatching = constraints.preconditions.notSatisfied.first {
            if case .userToggled = $0.constraint {
                return true
            } else {
                return false
            }
        }
        
        if preconditionMatching != nil {
            return true
        } else {
            return false
        }
    }
    
    /// - return: `true` if this feature is currently disabled at least in part because it requires runtime status
    /// of `isEnabled` to return `true` and it is not currently.
    public static var requiresRuntimeEnabled: Bool {
        let constraints = Flint.constraintsEvaluator.evaluate(for: self)
        let preconditionMatching = constraints.preconditions.notSatisfied.first {
            if case .runtimeEnabled = $0.constraint {
                return true
            } else {
                return false
            }
        }
        
        if preconditionMatching != nil {
            return true
        } else {
            return false
        }
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
