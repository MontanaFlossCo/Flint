//
//  ConstraintsEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface to the constraints evaluator component.
///
/// Implementations are responsible for evaluating all the constraints and returning information about
/// those that are satisfied or not.
public protocol ConstraintsEvaluator {
    /// Return a human-readable descriptiong for the constraints of a single feature
    func description(for feature: ConditionalFeatureDefinition.Type) -> String
    
    /// Set the constraints for a given feature, for later evaluation.
    ///
    /// This is called when building the constraints from the DSL definitions
    func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type)

    /// - return: `true` if the feature's evaluation can be cached long term. `false` if it needs to be checked every time.
    func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool
    
    /// Evaluate the constraints for the feature and return the results.
    /// - note: Implementations should not cache anything. The `AvailabilityChecker` caches its results and manages
    /// this via calls to `canCacheResult(for:)`.
    func evaluate(for feature: ConditionalFeatureDefinition.Type) -> FeatureEvaluationResult
}

