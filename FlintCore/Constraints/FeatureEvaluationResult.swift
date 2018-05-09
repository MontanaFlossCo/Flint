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
    /// The information about all the constraints declared
    public let all: FeatureConstraints

    /// The information about the constraints that are currently satisfied
    public let satisfied: FeatureConstraints

    /// The information about the constraints that are currently unsatisfied
    public let unsatisfied: FeatureConstraints

    /// The information about the constraints that are currently undetermined
    public let unknown: FeatureConstraints

    init(satisfied: FeatureConstraints, unsatisfied: FeatureConstraints, unknown: FeatureConstraints) {
        var allDeclaredPlatforms = satisfied.allDeclaredPlatforms.merging(unsatisfied.allDeclaredPlatforms) { (_, new) in return new }
        allDeclaredPlatforms = allDeclaredPlatforms.merging(unknown.allDeclaredPlatforms) {(_, new) in return new }

        self.all = FeatureConstraints(allDeclaredPlatforms: allDeclaredPlatforms,
                                      preconditions: satisfied.preconditions.union(unsatisfied.preconditions).union(unknown.preconditions),
                                      permissions: satisfied.permissions.union(unsatisfied.permissions).union(unknown.permissions))
        self.satisfied = satisfied
        self.unsatisfied = unsatisfied
        self.unknown = unknown
    }

    init(satisfied: FeatureConstraints) {
        self.all = satisfied
        self.satisfied = satisfied
        self.unsatisfied = FeatureConstraints()
        self.unknown = FeatureConstraints()
    }

    init(unsatisfied: FeatureConstraints) {
        self.all = unsatisfied
        self.satisfied = FeatureConstraints()
        self.unsatisfied = unsatisfied
        self.unknown = FeatureConstraints()
    }

    init(unknown: FeatureConstraints) {
        self.all = unknown
        self.satisfied = FeatureConstraints()
        self.unsatisfied = FeatureConstraints()
        self.unknown = unknown
    }

}
