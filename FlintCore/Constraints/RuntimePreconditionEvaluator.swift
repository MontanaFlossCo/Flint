//
//  RuntimePreconditionEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The precondition evaluator that tests if the feature's `isEnabled` property is `true`
public class RuntimePreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case .runtimeEnabled = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to runtime evaluator")
        }

        return feature.isEnabled
    }
}

