//
//  DefaultFeatureConstraintsEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// This is the implementation of the constraints evaluator.
///
/// It is threadsafe.
public class DefaultFeatureConstraintsEvaluator: ConstraintsEvaluator {
    var constraintsByFeature: [FeaturePath:FeatureConstraints] = [:]
    var purchaseEvaluator: FeaturePreconditionEvaluator?
    var runtimeEvaluator: FeaturePreconditionEvaluator = RuntimePreconditionEvaluator()
    var userToggleEvaluator: FeaturePreconditionEvaluator?
    let permissionChecker: SystemPermissionChecker
    lazy var accessQueue = {
        return SmartDispatchQueue(queue: DispatchQueue(label: "tools.flint.DefaultFeatureConstraintsEvaluator"), owner: self)
    }()
    
    public init(permissionChecker: SystemPermissionChecker, purchaseTracker: PurchaseTracker?, userToggles: UserFeatureToggles?) {
        self.permissionChecker = permissionChecker
        if let purchaseTracker = purchaseTracker {
            purchaseEvaluator = PurchasePreconditionEvaluator(purchaseTracker: purchaseTracker)
        }
        if let userToggles = userToggles {
            userToggleEvaluator = UserTogglePreconditionEvaluator(userToggles: userToggles)
        }
    }
    
    public func description(for feature: ConditionalFeatureDefinition.Type) -> String {
        if let constraints = accessQueue.sync(execute: { constraintsByFeature[feature.identifier] }) {
            let platforms = constraints.allDeclaredPlatforms.map { $0.value.description }
            let preconditions = constraints.preconditions.map { $0.description }
            let permissions = constraints.permissions.map { $0.description }
            return "Platforms: \(platforms.joined(separator: ", "))\nPreconditions: \(preconditions.joined(separator: ", "))\nPermissions: \(permissions.joined(separator: ", "))"
        } else {
            return "<none>"
        }
    }

    public func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool {
        if let constraints = accessQueue.sync(execute: { constraintsByFeature[feature.identifier] }) {
            // The runtime `enabled` flag can be toggled by the app, typically at startup and we don't want to have to force
            // the developer to invalidate everything else every time.
            return !constraints.preconditions.contains(.runtimeEnabled)
        } else {
            return true
        }
    }
    
    public func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type) {
        FlintInternal.logger?.debug("Constraints evaluator storing constraints for \(feature.identifier): \(constraints)")
        accessQueue.sync {
            constraintsByFeature[feature.identifier] = constraints
        }
    }

    public func evaluate(for feature: ConditionalFeatureDefinition.Type) -> FeatureEvaluationResult {
        var satisfiedPreconditions: Set<FeaturePrecondition> = []
        var satisfiedPermissions: Set<SystemPermission> = []
        var unsatisfiedPreconditions: Set<FeaturePrecondition> = []
        var unsatisfiedPermissions: Set<SystemPermission> = []
        var unknownPreconditions: Set<FeaturePrecondition> = []

        let featureIdentifier = feature.identifier

        FlintInternal.logger?.debug("Constraints evaluator evaluating constraints for \(featureIdentifier)")

        let knownConstraints = accessQueue.sync {
            constraintsByFeature[featureIdentifier]
        }
        
        var satisfiedPlatforms: [Platform:PlatformConstraint] = [:]
        var unsatisfiedPlatforms: [Platform:PlatformConstraint] = [:]
        
        if let constraints = knownConstraints {
            for platformConstraint in constraints.currentPlatforms.values {
                // Only add evaluator for our current platform
                if platformConstraint.platform.isCurrentPlatform && platformConstraint.version.isCurrentCompatible {
                    satisfiedPlatforms[platformConstraint.platform] = platformConstraint
                } else {
                    unsatisfiedPlatforms[platformConstraint.platform] = platformConstraint
                }
            }
        
            for precondition in constraints.preconditions {
                let evaluator: FeaturePreconditionEvaluator
                
                switch precondition {
                    case .purchase(_):
                        guard let purchaseEvaluator = purchaseEvaluator else {
                            fatalError("Feature '\(feature)' has a purchase precondition but there is no purchase evaluator")
                        }
                        evaluator = purchaseEvaluator
                    case .runtimeEnabled:
                        evaluator = runtimeEvaluator
                    case .userToggled(_):
                        guard let userToggleEvaluator = userToggleEvaluator else {
                            fatalError("Feature '\(feature)' has a user toggling precondition but there is no purchase evaluator")
                        }
                        evaluator = userToggleEvaluator
                }
                
                switch evaluator.isFulfilled(precondition, for: feature) {
                    case .some(true):
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) satisfied precondition: \(precondition)")
                        satisfiedPreconditions.insert(precondition)
                    case .some(false):
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) did not satisfy precondition: \(precondition)")
                        unsatisfiedPreconditions.insert(precondition)
                    case .none:
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) could not determine precondition: \(precondition)")
                        unknownPreconditions.insert(precondition)
                }
            }
            
            for permission in constraints.permissions {
                let status = permissionChecker.status(of: permission)
                switch status {
                    case .notDetermined,
                         .unsupported,
                         .restricted,
                         .denied:
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) did not have permission '\(permission)', status is: \(status)")
                        unsatisfiedPermissions.insert(permission)
                    case .authorized:
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) has permission: \(permission)")
                        satisfiedPermissions.insert(permission)
                }
            }
        }
        
        let satisfied = FeatureConstraints(allDeclaredPlatforms: satisfiedPlatforms,
                                           preconditions: satisfiedPreconditions,
                                           permissions: satisfiedPermissions)
        let unsatisfied = FeatureConstraints(allDeclaredPlatforms: unsatisfiedPlatforms,
                                            preconditions: unsatisfiedPreconditions,
                                            permissions: unsatisfiedPermissions)
        let unknown = FeatureConstraints(allDeclaredPlatforms: [:],
                                        preconditions: unknownPreconditions,
                                        permissions: [])
        
        return FeatureEvaluationResult(satisfied: satisfied,
                                       unsatisfied: unsatisfied,
                                       unknown: unknown)
    }
}
