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
/// It is threadsafe, you may call this from any thread
public class DefaultFeatureConstraintsEvaluator: ConstraintsEvaluator {
    var constraintsByFeature: [FeaturePath:DeclaredFeatureConstraints] = [:]
    var purchaseEvaluator: FeaturePreconditionConstraintEvaluator?
    var runtimeEvaluator: FeaturePreconditionConstraintEvaluator = RuntimePreconditionEvaluator()
    var userToggleEvaluator: FeaturePreconditionConstraintEvaluator?
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
    
    public func set(constraints: DeclaredFeatureConstraints, for feature: ConditionalFeatureDefinition.Type) {
        FlintInternal.logger?.debug("Constraints evaluator storing constraints for \(feature.identifier): \(constraints)")
        accessQueue.sync {
            constraintsByFeature[feature.identifier] = constraints
        }
    }

    public func evaluate(for feature: ConditionalFeatureDefinition.Type) -> FeatureConstraintsEvaluation {
        let featureIdentifier = feature.identifier

        FlintInternal.logger?.debug("Constraints evaluator evaluating constraints for \(featureIdentifier)")

        let constraints = accessQueue.sync {
            constraintsByFeature[featureIdentifier]
        }
        
        let platforms = evaluatePlatforms(for: feature, constraints: constraints)
        let permissions = evaluatePermissions(for: feature, constraints: constraints)
        let preconditions = evaluatePreconditions(for: feature, constraints: constraints)

        return FeatureConstraintsEvaluation(permissions: permissions, preconditions: preconditions, platforms: platforms)
    }
    
    private func evaluatePlatforms(for feature: ConditionalFeatureDefinition.Type, constraints: DeclaredFeatureConstraints?) -> Set<FeatureConstraintResult<PlatformConstraint>> {
        guard let constraints = constraints else {
            return []
        }
        var results: Set<FeatureConstraintResult<PlatformConstraint>> = []
        for platformConstraint in constraints.allDeclaredPlatforms.values {
            // Only add evaluator for our current platform
            let status: FeatureConstraintStatus
            if platformConstraint.platform.isCurrentPlatform {
                status = platformConstraint.version.isCurrentCompatible ? .satisfied : .notSatisfied
            } else {
                status = .notActive
            }
            results.insert(FeatureConstraintResult(constraint: platformConstraint, status: status))
        }
        return results
    }

    private func evaluatePermissions(for feature: ConditionalFeatureDefinition.Type, constraints: DeclaredFeatureConstraints?) -> Set<FeatureConstraintResult<SystemPermissionConstraint>> {
        guard let constraints = constraints else {
            return []
        }
        let featureIdentifier = feature.identifier
        var results: Set<FeatureConstraintResult<SystemPermissionConstraint>> = []
        for permission in constraints.permissions {
            let permissionStatus = permissionChecker.status(of: permission)
            let status: FeatureConstraintStatus
            switch permissionStatus {
                case .notDetermined:
                    status = .notDetermined
                    FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) does not yet have permission '\(permission)', status is: \(permissionStatus)")
                case .unsupported,
                     .restricted,
                     .denied:
                    FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) cannot not have permission '\(permission)', status is: \(permissionStatus)")
                    status = .notSatisfied
                case .authorized:
                    FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) has permission: \(permission)")
                    status = .satisfied
            }
            results.insert(FeatureConstraintResult(constraint: permission, status: status))
        }
        return results
    }
    
    private func evaluatePreconditions(for feature: ConditionalFeatureDefinition.Type, constraints: DeclaredFeatureConstraints?) -> Set<FeatureConstraintResult<FeaturePreconditionConstraint>> {
        guard let constraints = constraints else {
            return []
        }
        let featureIdentifier = feature.identifier
        var results: Set<FeatureConstraintResult<FeaturePreconditionConstraint>> = []
        for precondition in constraints.preconditions {
            let evaluator: FeaturePreconditionConstraintEvaluator

            switch precondition {
                case .purchase(_):
                    guard let purchaseEvaluator = purchaseEvaluator else {
                        flintBug("Feature '\(feature)' has a purchase precondition but there is no purchase evaluator")
                    }
                    evaluator = purchaseEvaluator
                case .runtimeEnabled:
                    evaluator = runtimeEvaluator
                case .userToggled(_):
                    guard let userToggleEvaluator = userToggleEvaluator else {
                        flintBug("Feature '\(feature)' has a user toggling precondition but there is no purchase evaluator")
                    }
                    evaluator = userToggleEvaluator
            }

            let status: FeatureConstraintStatus
            switch evaluator.isFulfilled(precondition, for: feature) {
                case .some(true):
                    FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) satisfied precondition: \(precondition)")
                    status = .satisfied
                case .some(false):
                    FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) did not satisfy precondition: \(precondition)")
                    status = .notSatisfied
                case .none:
                    FlintInternal.logger?.debug("Constraints evaluator on \(featureIdentifier) could not determine precondition: \(precondition)")
                    status = .notDetermined
            }
            results.insert(FeatureConstraintResult(constraint: precondition, status: status))
        }
        return results
    }
}
