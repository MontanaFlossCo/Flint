//
//  ConstraintsEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public struct FeatureEvaluationResult {
    let satisfied: FeatureConstraints
    let unsatisfied: FeatureConstraints
    let unknown: FeatureConstraints

    init(satisfied: FeatureConstraints, unsatisfied: FeatureConstraints, unknown: FeatureConstraints) {
        self.satisfied = satisfied
        self.unsatisfied = unsatisfied
        self.unknown = unknown
    }

    init(satisfied: FeatureConstraints) {
        self.satisfied = satisfied
        self.unsatisfied = FeatureConstraints()
        self.unknown = FeatureConstraints()
    }

    init(unsatisfied: FeatureConstraints) {
        self.satisfied = FeatureConstraints()
        self.unsatisfied = unsatisfied
        self.unknown = FeatureConstraints()
    }

    init(unknown: FeatureConstraints) {
        self.satisfied = FeatureConstraints()
        self.unsatisfied = FeatureConstraints()
        self.unknown = unknown
    }

}

public protocol ConstraintsEvaluator {
    func description(for feature: ConditionalFeatureDefinition.Type) -> String
    
    func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type)

    func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool
    
    func evaluate(for feature: ConditionalFeatureDefinition.Type) -> FeatureEvaluationResult
}

