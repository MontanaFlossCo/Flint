//
//  RuntimePreconditionEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The precondition evaluator that tests if the feature's `isEnabled` property is `true`
public class RuntimePreconditionEvaluator: FeaturePreconditionConstraintEvaluator {
    public func isFulfilled(_ precondition: FeaturePreconditionConstraint, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        flintBugPrecondition(.runtimeEnabled == precondition, "Incorrect precondition type '\(precondition)' passed to runtime evaluator")

        return feature.isEnabled
    }
}

