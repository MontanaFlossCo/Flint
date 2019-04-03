//
//  FeaturePreconditionConstraintEvaluator.swift
//  FlintCore
//
//  Created by Marc Palmer on 01/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The interface to types that evaluate whether or not a specific precondition has been met.
public protocol FeaturePreconditionConstraintEvaluator: AnyObject {

    /// - return: `true` only if the precondition is currently satisfied. If the state cannot be determined
    /// yet and will change, return `nil`
    func isFulfilled(_ precondition: FeaturePreconditionConstraint, for feature: ConditionalFeatureDefinition.Type) -> Bool?
}
