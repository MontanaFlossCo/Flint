//
//  MockFeatureConstraintsEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation
import FlintCore

class MockFeatureConstraintsEvaluator: ConstraintsEvaluator {
    private var constraintsForFeatures: [FeaturePath:DeclaredFeatureConstraints] = [:]
    private var mockEvaluations: [FeaturePath:FeatureConstraintsEvaluationResult] = [:]

    func description(for feature: ConditionalFeatureDefinition.Type) -> String {
        return ""
    }
    
    func set(constraints: DeclaredFeatureConstraints, for feature: ConditionalFeatureDefinition.Type) {
        constraintsForFeatures[feature.identifier] = constraints
    }

    func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool {
        return true
    }
    
    func evaluate(for feature: ConditionalFeatureDefinition.Type) -> FeatureConstraintsEvaluationResult {
        guard let result = mockEvaluations[feature.identifier] else {
            fatalError("Mock evaluator has no evaluation result set for feature: \(feature)")
        }
        return result
    }

    // MARK: Test helpers
    
    func setEvaluationResult(for feature: ConditionalFeatureDefinition.Type, result: FeatureConstraintsEvaluationResult) {
        mockEvaluations[feature.identifier] = result
    }
        
    func constraints(for feature: ConditionalFeatureDefinition.Type) -> DeclaredFeatureConstraints? {
        return constraintsForFeatures[feature.identifier]
    }
}
