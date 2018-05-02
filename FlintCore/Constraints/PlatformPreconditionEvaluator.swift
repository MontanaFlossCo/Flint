//
//  PlatformPreconditionEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public class PlatformPreconditionEvaluator: FeaturePreconditionEvaluator {
    public func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool? {
        guard case let .platform(id, version) = precondition else {
            fatalError("Incorrect precondition type '\(precondition)' passed to platform evaluator")
        }
        return id.isCurrentPlatform && version.isCurrentCompatible
    }
}
