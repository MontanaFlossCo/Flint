//
//  FeatureConstraintsEvaluationResult.swift
//  FlintCore
//
//  Created by Marc Palmer on 03/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The container for constraint evaluation results.
///
/// Use this to examine all the constraints on the feature and whether they are active and/or fulfilled.
public struct FeatureConstraintsEvaluation {
    public let permissions: DefaultFeatureConstraintEvaluationResults<SystemPermissionConstraint>
    public let preconditions: DefaultFeatureConstraintEvaluationResults<FeaturePreconditionConstraint>
    public let platforms: DefaultFeatureConstraintEvaluationResults<PlatformConstraint>

    public var hasNotSatisfiedConstraints: Bool {
        return permissions.notSatisfied.count > 0 || preconditions.notSatisfied.count > 0 || platforms.notSatisfied.count > 0
    }
    
    public var hasNotDeterminedConstraints: Bool {
        return permissions.notDetermined.count > 0 || preconditions.notDetermined.count > 0 || platforms.notDetermined.count > 0
    }
    
    init(permissions: Set<FeatureConstraintResult<SystemPermissionConstraint>>,
         preconditions: Set<FeatureConstraintResult<FeaturePreconditionConstraint>>,
         platforms: Set<FeatureConstraintResult<PlatformConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults(permissions)
        self.preconditions = DefaultFeatureConstraintEvaluationResults(preconditions)
        self.platforms = DefaultFeatureConstraintEvaluationResults(platforms)
    }

    init(permissions: Set<FeatureConstraintResult<SystemPermissionConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults(permissions)
        self.preconditions = DefaultFeatureConstraintEvaluationResults([])
        self.platforms = DefaultFeatureConstraintEvaluationResults([])
    }

    init(preconditions: Set<FeatureConstraintResult<FeaturePreconditionConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults([])
        self.preconditions = DefaultFeatureConstraintEvaluationResults(preconditions)
        self.platforms = DefaultFeatureConstraintEvaluationResults([])
    }

    init(platforms: Set<FeatureConstraintResult<PlatformConstraint>>) {
        self.permissions = DefaultFeatureConstraintEvaluationResults([])
        self.preconditions = DefaultFeatureConstraintEvaluationResults([])
        self.platforms = DefaultFeatureConstraintEvaluationResults(platforms)
    }
}
