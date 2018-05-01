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

    public init(purchaseTracker: PurchaseTracker?, userToggles: UserFeatureToggles?) {
        if let purchaseTracker = purchaseTracker {
            purchaseEvaluator = PurchasePreconditionEvaluator(purchaseTracker: purchaseTracker)
        }
        if let userToggles = userToggles {
            userToggleEvaluator = UserTogglePreconditionEvaluator(userToggles: userToggles)
        }
    }
    
    public func description(for feature: ConditionalFeatureDefinition.Type) -> String {
        if let constraints = constraintsByFeature[feature.identifier] {
            return String(describing: constraints)
        } else {
            return "<none>"
        }
    }

    public func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool {
        if let constraints = constraintsByFeature[feature.identifier] {
            // The runtime `enabled` flag can be toggled by the app, typically at startup and we don't want to have to force
            // the developer to invalidate everything else every time.
            return !constraints.preconditions.contains(.runtimeEnabled)
        } else {
            return true
        }
    }
    
    public func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type) {
        constraintsByFeature[feature.identifier] = constraints
    }

    public func evaluate(for feature: ConditionalFeatureDefinition.Type) -> (satisfied: FeatureConstraints, unsatisfied: FeatureConstraints, unknown: FeatureConstraints) {
        var satisfiedPreconditions: Set<FeaturePrecondition> = []
        var unsatisfiedPreconditions: Set<FeaturePrecondition> = []
        var unknownPreconditions: Set<FeaturePrecondition> = []

        if let constraints = constraintsByFeature[feature.identifier] {
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
                    case .some(true): satisfiedPreconditions.insert(precondition)
                    case .some(false): unsatisfiedPreconditions.insert(precondition)
                    case .none: unknownPreconditions.insert(precondition)
                }
            }
        }
        
        return (satisfied: FeatureConstraints(preconditions: satisfiedPreconditions),
                unsatisfied: FeatureConstraints(preconditions: unsatisfiedPreconditions),
                unknown: FeatureConstraints(preconditions: unsatisfiedPreconditions))
    }
}
