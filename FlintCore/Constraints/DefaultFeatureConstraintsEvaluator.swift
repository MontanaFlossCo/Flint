//
//  DefaultFeatureConstraintsEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public class DefaultFeatureConstraintsEvaluator: ConstraintsEvaluator {
    var constraintsByFeature: [FeaturePath:FeatureConstraints] = [:]
    var platformEvaluator: FeaturePreconditionEvaluator = PlatformPreconditionEvaluator()
    var purchaseEvaluator: FeaturePreconditionEvaluator?
    var runtimeEvaluator: FeaturePreconditionEvaluator = RuntimePreconditionEvaluator()
    var userToggleEvaluator: FeaturePreconditionEvaluator?
    let permissionChecker: PermissionChecker
    lazy var accessQueue = {
        return SmartDispatchQueue(queue: DispatchQueue(label: "tools.flint.DefaultFeatureConstraintsEvaluator"), owner: self)
    }()
    
    public init(permissionChecker: PermissionChecker, purchaseTracker: PurchaseTracker?, userToggles: UserFeatureToggles?) {
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
            return String(describing: constraints)
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

    public func evaluate(for feature: ConditionalFeatureDefinition.Type) -> (satisfied: FeatureConstraints, unsatisfied: FeatureConstraints, unknown: FeatureConstraints) {
        var satisfiedPreconditions: Set<FeaturePrecondition> = []
        var satisfiedPermissions: Set<SystemPermission> = []
        var unsatisfiedPreconditions: Set<FeaturePrecondition> = []
        var unsatisfiedPermissions: Set<SystemPermission> = []
        var unknownPreconditions: Set<FeaturePrecondition> = []
        var unknownPermissions: Set<SystemPermission> = []

        let featureIdentifier = feature.identifier

        FlintInternal.logger?.debug("Constraints evaluator evaluating constraints for \(featureIdentifier)")

        let knownConstraints = accessQueue.sync {
            constraintsByFeature[featureIdentifier]
        }
        
        if let constraints = knownConstraints {
            for precondition in constraints.preconditions {
                let evaluator: FeaturePreconditionEvaluator
                
                switch precondition {
                    case .platform(_, _):
                        evaluator = platformEvaluator
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
                switch permissionChecker.status(of: permission) {
                    case .unknown:
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) could not determine permission: \(permission)")
                        unknownPermissions.insert(permission)
                    case .unsupported,
                         .restricted,
                         .denied:
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) did not have permission: \(permission)")
                        unsatisfiedPermissions.insert(permission)
                    case .authorized:
                        FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) has permission: \(permission)")
                        satisfiedPermissions.insert(permission)
                }
            }
        }
        
        return (satisfied: FeatureConstraints(preconditions: satisfiedPreconditions, permissions: satisfiedPermissions),
                unsatisfied: FeatureConstraints(preconditions: unsatisfiedPreconditions, permissions: unsatisfiedPermissions),
                unknown: FeatureConstraints(preconditions: unknownPreconditions, permissions: unknownPermissions))
    }
}
