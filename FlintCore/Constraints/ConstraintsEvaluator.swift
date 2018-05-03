//
//  ConstraintsEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation


public protocol ConstraintsEvaluator {
    func description(for feature: ConditionalFeatureDefinition.Type) -> String
    
    func set(constraints: FeatureConstraints, for feature: ConditionalFeatureDefinition.Type)

    func canCacheResult(for feature: ConditionalFeatureDefinition.Type) -> Bool
    
    func evaluate(for feature: ConditionalFeatureDefinition.Type) -> FeatureEvaluationResult
}

