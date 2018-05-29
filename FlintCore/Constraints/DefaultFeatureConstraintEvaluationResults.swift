//
//  DefaultFeatureConstraintEvaluationResults.swift
//  FlintCore
//
//  Created by Marc Palmer on 29/05/2018.
//  Copyright © 2018 Montana Floss Co. Ltd. All rights reserved.
//

import Foundation

/// The default container for feature constraint evaluation results.
public class DefaultFeatureConstraintEvaluationResults<ConstraintType>: FeatureConstraintEvaluationResults where ConstraintType: FeatureConstraint {
    /// Results for all the constraint results, including those that are `.notActive`
    public let all: Set<FeatureConstraintResult<ConstraintType>>

    /// Only the `.satisfied` constraint results
    public lazy var satisfied: Set<FeatureConstraintResult<ConstraintType>> = {
        return all.filter { $0.status == .satisfied }
    }()

    /// Only the `.notSatisfied` constraint results
    public lazy var notSatisfied: Set<FeatureConstraintResult<ConstraintType>> = {
        return all.filter { $0.status == .notSatisfied }
    }()

    /// Only the `.notDetermined` constraint results
    public lazy var notDetermined: Set<FeatureConstraintResult<ConstraintType>> = {
        return all.filter { $0.status == .notDetermined }
    }()
    
    /// Initialise with the supplied results.
    init(_ results: Set<FeatureConstraintResult<ConstraintType>>) {
        self.all = results
    }

    /// Initialise with the supplied results.
    init(_ array: [FeatureConstraintResult<ConstraintType>]) {
        self.all = Set(array)
    }
}
