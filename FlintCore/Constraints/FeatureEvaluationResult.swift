//
//  FeatureEvaluationResult.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The container for constraint evaluation results.
public struct FeatureEvaluationResult {
    /// The information about the constraints that are currently satisfied
    public let satisfied: FeatureConstraints

    /// The information about the constraints that are currently unsatisfied
    public let unsatisfied: FeatureConstraints

    /// The information about the constraints that are currently undetermined
    public let unknown: FeatureConstraints

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
