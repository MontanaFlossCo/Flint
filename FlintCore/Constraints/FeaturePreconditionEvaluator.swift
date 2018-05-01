//
//  FeaturePreconditionEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

public protocol FeaturePreconditionEvaluator {
    func isFulfilled(_ precondition: FeaturePrecondition, for feature: ConditionalFeatureDefinition.Type) -> Bool?
}
