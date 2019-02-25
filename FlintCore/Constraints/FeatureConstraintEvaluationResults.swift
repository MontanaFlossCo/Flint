//
//  FeatureConstraintEvaluationResults.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The protocol for accessing information about the results of an evaluation
public protocol FeatureConstraintEvaluationResults {
    /// The type of constraint these results relate to. Constraints are based on `enum`s and they are
    /// not polymorphic, so we have to be generic over the type of the enum.
    associatedtype ConstraintType: FeatureConstraint
    
    /// All the constraint results, including those that are `.notActive`
    var all: Set<FeatureConstraintResult<ConstraintType>> { get }
    
    /// All the `.satisfied` constraint results
    var satisfied: Set<ConstraintType> { get }

    /// All the `.notSatisfied` constraint results
    var notSatisfied: Set<ConstraintType> { get }

    /// All the `.notDetermined` constraint results
    var notDetermined: Set<ConstraintType> { get }
}
