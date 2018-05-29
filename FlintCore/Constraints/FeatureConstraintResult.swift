//
//  FeatureConstraintResult.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// Values of this type represent a single constraint evaluation result, used to determine
/// whether a constraint has been met or not.
///
/// You receive these values when the feature's constraints have been evaluated by the `FeatureConstraintsEvaluator`,
/// which returns a `FeatureConstraintEvaluation` so that you can access the individual results.
///
/// - see: `FeatureConstraintEvaluation`
public struct FeatureConstraintResult<T>: Hashable where T: FeatureConstraint {
    public let status: FeatureConstraintStatus
    public let constraint: T
    
    public init(constraint: T, status: FeatureConstraintStatus) {
        self.constraint = constraint
        self.status = status
    }
    
    public var hashValue: Int {
        return status.hashValue ^ constraint.hashValue
    }

    public static func ==(lhs: FeatureConstraintResult<T>, rhs: FeatureConstraintResult<T>) -> Bool {
        return lhs.status == rhs.status  &&
            lhs.constraint == rhs.constraint
    }
}
